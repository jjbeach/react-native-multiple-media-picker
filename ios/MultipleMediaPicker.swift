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
    func showMediaPicker(_ selectedPhLocalIds: [String]?, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        
        PHPhotoLibrary.requestAuthorization({status in
            if status != .authorized {
                reject("E_PERMISSION_MISSING", "Cannot access images. Please allow access if you want to be able to select images.", nil)
                return;
            }
            DispatchQueue.main.async {
                let imagePicker = ImagePickerController()
                imagePicker.settings.selection.max = 2
                imagePicker.settings.theme.selectionStyle = .numbered
                imagePicker.settings.fetch.assets.supportedMediaTypes = [.image, .video]

                //ToDo: include dropDownHeight as a param in showMediaPicker
                Settings.shared.theme.dropDownHeight = 700

                var imgDataObjs = [ImgDataObj]()
                if(selectedPhLocalIds != nil) {
                    let allAssets = PHAsset.fetchAssets(with: .image, options: nil)
                    var foundAssets = [PHAsset]()
                    allAssets.enumerateObjects({ (asset, idx, stop) -> Void in
                        if selectedPhLocalIds?.firstIndex(where: {(phLocalId: String) -> Bool in asset.localIdentifier == phLocalId }) != nil {
                            foundAssets.append(asset)
                            var imgDataObj = ImgDataObj(uri: "", type: "", name: "", phAssetLocalId: "")
                            asset.getAssetUrl(){ url in
                                guard let url = url else { return }

                                imgDataObj.uri = url.absoluteString
                                imgDataObj.phAssetLocalId = asset.localIdentifier
                                imgDataObj.type = "image/jpeg"
                                imgDataObj.name = "photo_\(NSDate().timeIntervalSince1970).jpg"
                                imgDataObjs.append(imgDataObj)
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
                    var imgDataObj = ImgDataObj(uri: "", type: "", name: "photo_\(NSDate().timeIntervalSince1970).jpg", phAssetLocalId: "")
                    asset.getAssetUrl(){ url in
                        guard let url = url else { return }

                        imgDataObj.uri = url.absoluteString
                        imgDataObj.phAssetLocalId = asset.localIdentifier
                        imgDataObj.type = "image/jpeg"
                        imgDataObjs.append(imgDataObj)
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
                    resolve(imgDataObjs.map {$0.dictionary} )
//                    resolve(assets.map {$0.imageDataObj})
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
    var imageDataObj : [String: String] {
        var imgDataObj : [String: String] = [:]
//        let manager = PHCachingImageManager()
//        let options = PHImageRequestOptions()
//        options.version = .original
//        options.isSynchronous = true
//        options.isNetworkAccessAllowed = true
//        manager.requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
//            if (image != nil) {
//                let path = "photo/temp/mmp/\(NSDate().timeIntervalSince1970).jpg"
//                let url = image?.save(at: .documentDirectory,
//                                      pathAndImageName: path)
//                imgDataObj["uri"] = url?.absoluteString
//                imgDataObj["type"] = "image/jpeg"
//                imgDataObj["name"] = path
//                imgDataObj["phAssetLocalId"] = self.localIdentifier
//            }
//        }
        imgDataObj["phAssetLocalId"] = self.localIdentifier
        imgDataObj["type"] = "image/jpeg"
        imgDataObj["name"] = "foo"
        return imgDataObj
    }
    
    func getAssetUrl(completionHandler: @escaping (URL?) -> Void) {
        let option = PHContentEditingInputRequestOptions()
        self.requestContentEditingInput(with: option) { contentEditingInput, _ in
            completionHandler(contentEditingInput?.fullSizeImageURL)
        }
    }
    
}


// save
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

// load from path

extension UIImage {
    convenience init?(fileURLWithPath url: URL, scale: CGFloat = 1.0) {
        do {
            let data = try Data(contentsOf: url)
            self.init(data: data, scale: scale)
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
