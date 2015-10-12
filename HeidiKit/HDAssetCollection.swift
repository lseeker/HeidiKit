//
//  HDAssetCollection.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 4..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos
import Darwin

class HDAssetCollection: NSObject {
    var assetCollection : PHAssetCollection {
        didSet {
            _assetsFetchResult = nil
        }
    }
    var keyImage : UIImage?
    var _assetsFetchResult : PHFetchResult? {
        didSet {
            keyImage = nil
        }
    }
    var assetsFetchResult : PHFetchResult {
        get {
            if _assetsFetchResult != nil {
                return _assetsFetchResult!
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.Image.rawValue)
            fetchOptions.wantsIncrementalChangeDetails = true
            
            //fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: true) ]
            _assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: fetchOptions)
            
            return _assetsFetchResult!
        }
    }
    var title : String {
        get {
            return assetCollection.localizedTitle!
        }
    }
    var count : Int {
        get {
            return assetsFetchResult.count
        }
    }
    
    init (_ assetCollection : PHAssetCollection) {
        self.assetCollection = assetCollection
        super.init()
    }
    
    func cleanUp() {
        keyImage = nil;
        _assetsFetchResult = nil;
    }
    
    func fetchKeyImage(resultHandler : ((keyImage : UIImage!) -> Void)) {
        if keyImage != nil {
            resultHandler(keyImage: keyImage)
            return
        }
        if assetsFetchResult.count == 0 {
            return
        }
        
        NSOperationQueue().addOperationWithBlock { () -> Void in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.Image.rawValue)
            
            var resultOptional = PHAsset.fetchKeyAssetsInAssetCollection(self.assetCollection, options: fetchOptions)
            if resultOptional?.count == 0 {
                resultOptional = self.assetsFetchResult
            }
            
            guard let result = resultOptional
                else { return }
            
            let options = self.assetCollection.assetCollectionSubtype == .SmartAlbumUserLibrary ? .Reverse : NSEnumerationOptions()
            
            var assets = [PHAsset]()
            result.enumerateObjectsWithOptions(options) { (obj, index, stop) -> Void in
                assets.append(obj as! PHAsset)
                if assets.count == 3 {
                    stop.memory = true
                }
            }
            
            if assets.isEmpty {
                return
            }
            
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.synchronous = true // synchronous for asset order
            imageRequestOptions.version = PHImageRequestOptionsVersion.Current
            imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.Fast
            
            let scale = UIScreen.mainScreen().scale
            
            let width = 68 * scale
            let height = 72 * scale
            
            var color = UITableViewCell.appearance().backgroundColor
            if color == nil {
                color = UIColor.whiteColor()
            }
            // scale is 1.0 for line stroke
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 1.0)
            let context = UIGraphicsGetCurrentContext()
            
            CGContextSetFillColorWithColor(context, color?.CGColor)
            CGContextFillRect(context, CGRect(x: 0, y: 0, width: width, height: height))
            
            let count = assets.count
            for (index, asset) in Array(assets.reverse()).enumerate() {
                let factor = CGFloat((count - 1 - index) * 2) * scale
                let sideLength = 68 * scale - factor * 2
                let size = CGSize(width: sideLength, height: sideLength)
                PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: size, contentMode: PHImageContentMode.AspectFill, options: imageRequestOptions, resultHandler: { (image, info) -> Void in
                    guard let image = image else {
                        return
                    }
                    
                    let rect = CGRect(origin: CGPoint(x: factor, y: factor * 3), size: size)
                    let cropSize = min(image.size.width, image.size.height)
                    let cropOrigin = CGPoint(x: (image.size.width - cropSize) / 2, y: (image.size.height - cropSize) / 2)
                    
                    CGContextDrawImage(context, rect, CGImageCreateWithImageInRect(image.CGImage, CGRect(origin: cropOrigin, size: CGSize(width: cropSize, height: cropSize))))
                })
            }
            CGContextSetStrokeColorWithColor(context, color?.CGColor)
            CGContextAddRect(context, CGRect(x: 0, y: height - 4 * scale + 0.5, width: width, height: 2 * scale))
            CGContextStrokePath(context)
            
            if let cgImage = CGBitmapContextCreateImage(context) {
                UIGraphicsEndImageContext()
                
                self.keyImage = UIImage(CGImage: cgImage, scale: scale, orientation: UIImageOrientation.DownMirrored)
            }
            dispatch_async(dispatch_get_main_queue()) {
                resultHandler(keyImage: self.keyImage)
            }
        }
        
    }
    
}
