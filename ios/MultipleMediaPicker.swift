//
//  MultipleMediaPicker.swift
//  MultipleMediaPicker
//
//  Created by Joshua Beach on 4/7/20.
//  Contributors: Johan Lundström
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import UIKit
import BSImagePicker
import Photos

@objc(MultipleMediaPicker)
class MultipleMediaPicker: UIViewController {
    
    @objc
    func showMediaPicker(_ options: NSDictionary?,
                         resolver resolve: @escaping RCTPromiseResolveBlock,
                         rejecter reject: @escaping RCTPromiseRejectBlock) {
        
        PHPhotoLibrary.requestAuthorization({status in
            if status != .authorized {
                reject("E_PERMISSION_MISSING", "Cannot access photo library. Please allow access if you want to upload media assets.", nil)
                return;
            }
            DispatchQueue.main.async {
                
                //Options
                var maxSelection : Int = 4;
                var selectedPhLocalIds : [String] = [];
                if (options != nil) {
                    if (options?["maxSelection"] != nil) {
                        maxSelection = options?["maxSelection"] as! Int
                    }
                    if (options?["selectedAssetsIds"] != nil) {
                        selectedPhLocalIds = options?["selectedAssetsIds"] as! [String]
                    }
                }
                
                
                let imagePicker = ImagePickerController()
                imagePicker.settings.selection.max = maxSelection
                imagePicker.settings.theme.selectionStyle = .numbered
                imagePicker.settings.fetch.assets.supportedMediaTypes = [.image, .video]

                //ToDo: include dropDownHeight as a param in showMediaPicker
                Settings.shared.theme.dropDownHeight = 700
                
                var imgDataObjs = [ImgDataObj]()

                if(!selectedPhLocalIds.isEmpty) {
                    let allAssets = PHAsset.fetchAssets(with: .image, options: nil)
                    var foundAssets = [PHAsset]()
                    allAssets.enumerateObjects({ (asset, idx, stop) -> Void in
                        if selectedPhLocalIds.firstIndex(where: {(phLocalId: String) -> Bool in asset.localIdentifier == phLocalId }) != nil {
                            foundAssets.append(asset)
                            
                            asset.getContentEditingInput(){ cei in
                                asset.buildImgDataObjAndAppend(contentEditingInput: cei, imgDataObjs: &imgDataObjs)
                            }
                        }
                    })
                    imagePicker.assetStore = AssetStore(assets: foundAssets)
                }
                
                imagePicker.settings.fetch.album.fetchResults = [
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil),
                    PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: imagePicker.settings.fetch.album.options)
                ]
                imagePicker.settings.selection.unselectOnReachingMax = true
                let start = Date()
                
                UIApplication.presentedViewController?.presentImagePicker(imagePicker, select: { (asset) in
                    print("Selected: \(asset)")
                    
                    asset.getContentEditingInput(){ cei in
                        asset.buildImgDataObjAndAppend(contentEditingInput: cei, imgDataObjs: &imgDataObjs)
                    }
                    
                }, deselect: { (asset) in
                    print("Deselected: \(asset)")
                    
                    if let foundIndex = imgDataObjs.firstIndex(where: {(imgDataObj: ImgDataObj) -> Bool in asset.localIdentifier == imgDataObj.phAssetLocalId }) {
                        imgDataObjs.remove(at: foundIndex)
                    }
                    
                }, cancel: { (assets) in
                    print("Canceled with selections: \(assets)")
                }, finish: { (assets) in
                    print("Finished with selections: \(assets)")
                    resolve(imgDataObjs.map {$0.dictionary})
                }, completion: {
                    let finish = Date()
                    print(finish.timeIntervalSince(start))
                })
            }
        })
    }
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
}

struct ImgDataObj: Codable {
    var uri: String
    var type: String
    var name: String
    var phAssetLocalId: String
    
}

struct JSON {
    static let encoder = JSONEncoder()
}

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}

extension PHAsset {
    func getContentEditingInput(completionHandler: @escaping (PHContentEditingInput?) -> Void) {
        let option = PHContentEditingInputRequestOptions()
        self.requestContentEditingInput(with: option) { contentEditingInput, _ in
            completionHandler(contentEditingInput)
        }
    }
    
    func buildImgDataObjAndAppend(contentEditingInput: PHContentEditingInput?, imgDataObjs: inout [ImgDataObj]) {
        var imgDataObj = ImgDataObj(uri: "", type: "", name: "photo_\(NSDate().timeIntervalSince1970).jpg", phAssetLocalId: "")
        
        imgDataObj.uri = contentEditingInput?.fullSizeImageURL?.absoluteString ?? ""
        imgDataObj.phAssetLocalId = self.localIdentifier
        imgDataObj.type = contentEditingInput?.uniformTypeIdentifier ?? ""
        imgDataObjs.append(imgDataObj)
    }
}

extension UIApplication {
    static var presentedViewController: UIViewController? {
        get {
            var rootVC = UIApplication.shared.windows.first!.rootViewController
            while (rootVC?.presentedViewController != nil) {
                rootVC = rootVC?.presentedViewController;
            }
            return rootVC
        }
    }
}
