//
//  HDImageAsset.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 10..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCSelectedAsset {
    let asset : PHAsset
    var image : UIImage?
    var fileName : String?
    var fileSize : Int?
    var formattedDate : String {
        get {
            return NSDateFormatter.localizedStringFromDate(asset.creationDate, dateStyle: NSDateFormatterStyle.MediumStyle, timeStyle: NSDateFormatterStyle.NoStyle)
        }
    }
    var resolution : String {
        get {
            return "\(asset.pixelWidth) x \(asset.pixelHeight)"
        }
    }
    
    init(asset : PHAsset) {
        self.asset = asset
        
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
        
        // request max size for title
        PHImageManager.defaultManager().requestImageDataForAsset(asset, options: nil) { (imageData, dataUTI, orientation, info) -> Void in
            if let url = info["PHImageFileURLKey"] as? NSURL {
                self.fileName = "\(url.lastPathComponent!)"
            }
            self.fileSize = imageData.length
        }
    }
    
    func loadImage(completionHandler : ((HDIPCSelectedAsset) -> Void)?) {
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: 68, height: 68), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info) -> Void in
            self.image = image
            
            if completionHandler != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler!(self)
                }
            }
        })
    }
    
}
