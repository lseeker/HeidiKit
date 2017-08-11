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
    var _assetsFetchResult : PHFetchResult<AnyObject>? {
        didSet {
            keyImage = nil
        }
    }
    var assetsFetchResult : PHFetchResult<AnyObject> {
        get {
            if _assetsFetchResult != nil {
                return _assetsFetchResult!
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            fetchOptions.wantsIncrementalChangeDetails = true
            
            //fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: true) ]
            _assetsFetchResult = PHAsset.fetchAssets(in: self.assetCollection, options: fetchOptions)
            
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
    
    func fetchKeyImage(_ resultHandler : @escaping ((_ keyImage : UIImage?) -> Void)) {
        if let keyImage = keyImage {
            resultHandler(keyImage)
            return
        }
        
        OperationQueue().addOperation { () -> Void in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            
            var resultOptional = PHAsset.fetchKeyAssets(in: self.assetCollection, options: fetchOptions)
            if resultOptional?.count == 0 {
                resultOptional = self.assetsFetchResult
            }
            
            guard let result = resultOptional
                else { return }
            
            //let options = self.assetCollection.assetCollectionSubtype == .SmartAlbumUserLibrary ? .Reverse : NSEnumerationOptions()
            
            var assets = [PHAsset]()
            result.enumerateObjects({ (obj, index, stop) -> Void in
                assets.append(obj )
                if assets.count == 3 {
                    stop.pointee = true
                }
            })
            
            if assets.isEmpty {
                return
            }
            
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.isSynchronous = true // synchronous for asset order
            imageRequestOptions.version = .current
            imageRequestOptions.deliveryMode = .highQualityFormat
            imageRequestOptions.resizeMode = .exact
            
            let scale = UIScreen.main.scale
            
            let width = 68 * scale
            let height = 72 * scale
            
            var color = UITableViewCell.appearance().backgroundColor
            if color == nil {
                color = UIColor.white
            }
            // scale is 1.0 for line stroke
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 1.0)
            let context = UIGraphicsGetCurrentContext()
            
            context?.setFillColor((color?.cgColor)!)
            context?.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
            let count = assets.count
            for (index, asset) in Array(assets.reversed()).enumerated() {
                let factor = CGFloat((count - 1 - index) * 2) * scale
                let sideLength = 68 * scale - factor * 2
                let size = CGSize(width: sideLength, height: sideLength)
                PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: imageRequestOptions, resultHandler: { (image, info) -> Void in
                    guard let image = image else {
                        return
                    }
                    
                    let rect = CGRect(origin: CGPoint(x: factor, y: factor * 3), size: size)
                    let cropSize = min(image.size.width, image.size.height)
                    let cropOrigin = CGPoint(x: (image.size.width - cropSize) / 2, y: (image.size.height - cropSize) / 2)
                    
                    context?.draw((image.cgImage?.cropping(to: CGRect(origin: cropOrigin, size: CGSize(width: cropSize, height: cropSize)))!)!, in: rect)
                })
            }
            context?.setStrokeColor((color?.cgColor)!)
            context?.addRect(CGRect(x: 0, y: height - 4 * scale + 0.5, width: width, height: 2 * scale))
            context?.strokePath()
            
            if let cgImage = context?.makeImage() {
                UIGraphicsEndImageContext()
                
                self.keyImage = UIImage(cgImage: cgImage, scale: scale, orientation: UIImageOrientation.downMirrored)
            }
            DispatchQueue.main.async {
                resultHandler(self.keyImage)
            }
        }
        
    }
    
}
