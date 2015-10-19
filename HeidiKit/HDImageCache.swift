//
//  HDImageCache.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 10. 19..
//  Copyright © 2015년 inode.kr. All rights reserved.
//

import UIKit

public class HDImageCache: NSObject {
    let targetURL: NSURL
    lazy var fileURL: NSURL = {
        let absoulteURLString = self.targetURL.absoluteString
        let filename = absoulteURLString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        
        return HDImageCacheManager.defaultManager().cacheDirectoryURL.URLByAppendingPathComponent(filename)
        }()
    
    var image: UIImage?
    
    init(targetURL: NSURL) {
        self.targetURL = targetURL
        super.init()
    }
    
    public func isCached() -> Bool {
        if image != nil {
            return true
        }
        return NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!)
    }
    
    public func getImage() -> UIImage? {
        if let image = self.image {
            return image
        }
        
        if !isCached() {
            return nil
        }
        
        guard let data = NSFileManager.defaultManager().contentsAtPath(fileURL.path!) else {
            return nil
        }
        
        var image: UIImage!
        if memcmp(data.bytes, "GIF89a", 6) == 0 {
            image = UIImage.animatedImageWithAnimatedGIFData(data)
        } else {
            image = UIImage(data: data)
        }
        
        self.image = image
        return image
    }
    
    public func download(handler: (cache: HDImageCache, error: NSError?) -> Void) {
        let request = NSURLRequest(URL: targetURL)
        HDImageCacheManager.defaultManager().session().downloadTaskWithRequest(request) { (location, response, error) -> Void in
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(cache: self, error: error)
                })
                return
            }
            
            if let response = response as? NSHTTPURLResponse {
                if response.statusCode != 200 {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler(cache: self, error: NSError(domain: "HeidiKit", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)]))
                    })
                    return
                }
            }
            
            guard let location = location else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(cache: self, error: NSError(domain: "HeidiKit", code: 500, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Download location not exists", comment: "HDImageCache download location not found")]))
                })
                return
            }
            
            let fileManager = NSFileManager.defaultManager()
            do {
                if fileManager.fileExistsAtPath(self.fileURL.path!) {
                    try fileManager.removeItemAtURL(self.fileURL)
                }
                try fileManager.moveItemAtURL(location, toURL: self.fileURL)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(cache: self, error: nil)
                })
            } catch let error as NSError {
                print(error)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(cache: self, error: error)
                })
            }
            
            }.resume()
    }
}
