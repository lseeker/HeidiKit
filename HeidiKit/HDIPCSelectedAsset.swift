//
//  HDImageAsset.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 10..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCSelectedAsset : Equatable {
    let asset : PHAsset
    var thumbnail : UIImage?
    var fileName : String?
    var fileSize : Int?
    var needLoading = true
    var formattedDate : String {
        get {
            return DateFormatter.localizedString(from: asset.creationDate!, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.none)
        }
    }
    var resolution : String {
        get {
            return "\(asset.pixelWidth) x \(asset.pixelHeight)"
        }
    }
    
    init(_ asset : PHAsset) {
        self.asset = asset
        
        loadData()
    }
    
    fileprivate func loadData() {
        let options = PHImageRequestOptions()
        options.version = PHImageRequestOptionsVersion.current
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true
        
        // request data for file name
        PHImageManager.default().requestImageData(for: asset, options: options) { (imageData, dataUTI, orientation, info) -> Void in
            if let url = info!["PHImageFileURLKey"] as? URL {
                self.fileName = "\(url.lastPathComponent)"
            } else {
                self.fileName = "NO NAME"
            }
            if let imageData = imageData {
                self.fileSize = imageData.count
            } else {
                self.fileSize = -1
            }
        }
    }
    
    func loadThumbnail(_ completionHandler : ((HDIPCSelectedAsset) -> Void)?) {
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 68, height: 68), contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: { (image, info) -> Void in
            self.thumbnail = image
            
            if completionHandler != nil {
                DispatchQueue.main.async {
                    completionHandler!(self)
                }
            }
        })
    }
    
    func downloadFullsizeImage(_ completionHandler : ((HDIPCSelectedAsset) -> Void)?) {
        // attempt to load full size image data
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic
        options.version = PHImageRequestOptionsVersion.current
        options.resizeMode = PHImageRequestOptionsResizeMode.none
        
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        options.progressHandler = { (p1, p2, p3, p4) -> Void in
            print(p1)
            print(p2)
            print(p3)
            print(p4)
        }
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), contentMode: PHImageContentMode.aspectFit, options: options) { (image, info) -> Void in
            if (!Bool(info![PHImageResultIsDegradedKey] as! NSNumber)) {
                self.needLoading = false
                
                if completionHandler != nil {
                    DispatchQueue.main.async {
                        completionHandler!(self)
                    }
                }
            }
        }
    }
}

func ==(lhs: HDIPCSelectedAsset, rhs:HDIPCSelectedAsset) -> Bool {
    return lhs.asset == rhs.asset
}

