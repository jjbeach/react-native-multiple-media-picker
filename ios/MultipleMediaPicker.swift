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
                reject("E_PERMISSION_MISSING", "Cannot access photo library. Please allow access if you want to select media assets.", nil)
                return;
            }
            DispatchQueue.main.async {
                
                //Options
                var maxFiles : Int = 4;
                var selectedPhLocalIds : [String] = [];
                var mediaType : Set<Settings.Fetch.Assets.MediaTypes> = [.image]
                if (options != nil) {
                    if (options?["maxFiles"] != nil) {
                        maxFiles = options?["maxFiles"] as! Int
                    }
                    if (options?["selectedAssetsIds"] != nil) {
                        selectedPhLocalIds = options?["selectedAssetsIds"] as! [String]
                    }
                    if (options?["mediaType"] != nil) {
                        if (options?["mediaType"] as! String == "any") {
                            mediaType = [.image, .video]
                        }
                        if (options?["mediaType"] as! String == "image") {
                            mediaType = [.image]
                        }
                        if (options?["mediaType"] as! String == "video") {
                            mediaType = [.video]
                        }
                    }
                }
                
                let imagePicker = ImagePickerController()
                imagePicker.settings.selection.max = maxFiles
                imagePicker.settings.theme.selectionStyle = .numbered
                imagePicker.settings.fetch.assets.supportedMediaTypes = mediaType
                
                //ToDo: include dropDownHeight as a param in showMediaPicker
                Settings.shared.theme.dropDownHeight = 700
                
                var imgDataObjs = [ImgDataObj]()
                
                if(!selectedPhLocalIds.isEmpty) {
                    var foundAssets = [PHAsset]()
                    PHAsset.fetchAssets(withLocalIdentifiers: selectedPhLocalIds, options: nil).enumerateObjects({ (asset, idx, stop) -> Void in
                        foundAssets.append(asset)
                        
                        asset.getContentEditingInput(){ cei in
                            asset.appendImgDataObjs(
                                imgDataObj: asset.buildImgDataObjFromContentEditingInput(contentEditingInput: cei),
                                imgDataObjs: &imgDataObjs
                            )
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
                
                UIApplication.presentedViewController?.presentImagePicker(
                    imagePicker,
                    select: { (asset) in
                        print("Selected: \(asset)")
                        
                        asset.getContentEditingInput(){ cei in
                            asset.appendImgDataObjs(
                                imgDataObj: asset.buildImgDataObjFromContentEditingInput(contentEditingInput: cei),
                                imgDataObjs: &imgDataObjs
                            )
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
                    resolve(imgDataObjs.map {$0.generateJpegImgDataObj().dictionary})
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
    var fullSizeImageURL: String
    var jpegURL: String
    var type: String
    var name: String
    var phAssetLocalId: String
    
    func generateJpegImgDataObj() -> ImgDataObj {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [self.phAssetLocalId], options: nil).firstObject else { return self}
        let manager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        var url : String = ""
        let path : String = "photo/temp/mmp/\(self.phAssetLocalId).jpg"
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
            if (image != nil) {
                url = image?.save(at: .documentDirectory,
                                  pathAndImageName: path)?.absoluteString ?? ""
            }
        }
        return ImgDataObj(
            fullSizeImageURL: self.fullSizeImageURL,
            jpegURL: url,
            type: "image/jpeg",
            name: "\(self.phAssetLocalId).jpg",
            phAssetLocalId: self.phAssetLocalId
        )
    }
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
    
    func buildImgDataObjFromContentEditingInput(contentEditingInput: PHContentEditingInput?) -> ImgDataObj {
        var imgDataObj = ImgDataObj(
            fullSizeImageURL: "",
            jpegURL: "",
            type: "",
            name:"",
            phAssetLocalId: ""
        )
        
        imgDataObj.fullSizeImageURL = contentEditingInput?.fullSizeImageURL?.absoluteString ?? ""
        imgDataObj.phAssetLocalId = self.localIdentifier
        
        return imgDataObj
    }
    
    func appendImgDataObjs(imgDataObj: ImgDataObj, imgDataObjs: inout [ImgDataObj]) {
        imgDataObjs.append(imgDataObj)
    }
}

extension UIImage {
    
    func save(at directory: FileManager.SearchPathDirectory,
              pathAndImageName: String,
              createSubdirectoriesIfNeed: Bool = true,
              compressionQuality: CGFloat = 0.8)  -> URL? {
        do {
            let documentsDirectory = try FileManager.default.url(for: directory, in: .userDomainMask,
                                                                 appropriateFor: nil,
                                                                 create: false)
            return save(at: documentsDirectory.appendingPathComponent(pathAndImageName),
                        createSubdirectoriesIfNeed: createSubdirectoriesIfNeed,
                        compressionQuality: compressionQuality)
        } catch {
            print("-- Error: \(error)")
            return nil
        }
    }
    
    func save(at url: URL,
              createSubdirectoriesIfNeed: Bool = true,
              compressionQuality: CGFloat = 1.0)  -> URL? {
        do {
            if createSubdirectoriesIfNeed {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }
            guard let data = jpegData(compressionQuality: compressionQuality) else { return nil }
            try data.write(to: url)
            return url
        } catch {
            print("-- Error: \(error)")
            return nil
        }
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
