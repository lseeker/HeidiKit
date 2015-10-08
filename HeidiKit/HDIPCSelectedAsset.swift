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
            return NSDateFormatter.localizedStringFromDate(asset.creationDate!, dateStyle: NSDateFormatterStyle.MediumStyle, timeStyle: NSDateFormatterStyle.NoStyle)
        }
    }
    var resolution : String
    
    init(_ asset : PHAsset) {
        self.asset = asset
        
        resolution = "\(asset.pixelWidth) x \(asset.pixelHeight)"
        
        loadData()
    }
    
    private func loadData() {
        let options = PHImageRequestOptions()
        options.version = PHImageRequestOptionsVersion.Current
        options.networkAccessAllowed = false
        options.synchronous = true
        
        // request data for file name
        PHImageManager.defaultManager().requestImageDataForAsset(asset, options: options) { (imageData, dataUTI, orientation, info) -> Void in
            if let url = info!["PHImageFileURLKey"] as? NSURL {
                self.fileName = "\(url.lastPathComponent!)"
            } else {
                self.fileName = "NO NAME"
            }
            if let imageData = imageData {
                self.fileSize = imageData.length
            } else {
                self.fileSize = -1
            }
        }
    }
    
    func loadThumbnail(completionHandler : ((HDIPCSelectedAsset) -> Void)?) {
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: 68, height: 68), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info) -> Void in
            self.thumbnail = image
            
            if completionHandler != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler!(self)
                }
            }
        })
    }
    
    func downloadFullsizeImage(completionHandler : ((HDIPCSelectedAsset) -> Void)?) {
        // attempt to load full size image data
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
        options.version = PHImageRequestOptionsVersion.Current
        options.resizeMode = PHImageRequestOptionsResizeMode.None
        
        options.networkAccessAllowed = true
        options.synchronous = false
        
        options.progressHandler = { (p1, p2, p3, p4) -> Void in
            print(p1)
            print(p2)
            print(p3)
            print(p4)
        }
        
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: CGFloat.max, height: CGFloat.max), contentMode: PHImageContentMode.AspectFit, options: options) { (image, info) -> Void in
            if (!Bool(info![PHImageResultIsDegradedKey] as! NSNumber)) {
                self.needLoading = false
                
                if completionHandler != nil {
                    dispatch_async(dispatch_get_main_queue()) {
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

