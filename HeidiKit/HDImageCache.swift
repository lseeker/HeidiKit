//
//  HDImageCache.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 10. 19..
//  Copyright © 2015년 inode.kr. All rights reserved.
//

import UIKit

open class HDImageCache: NSObject {
    let targetURL: URL
    lazy var fileURL: URL = {
        let absoulteURLString = self.targetURL.absoluteString
        let filename = absoulteURLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!
        
        return HDImageCacheManager.defaultManager().cacheDirectoryURL.appendingPathComponent(filename)!
        }()
    
    var image: UIImage?
    
    init(targetURL: URL) {
        self.targetURL = targetURL
        super.init()
    }
    
    open func isCached() -> Bool {
        if image != nil {
            return true
        }
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    open func getImage() -> UIImage? {
        if let image = self.image {
            return image
        }
        
        if !isCached() {
            return nil
        }
        
        guard let data = FileManager.default.contents(atPath: fileURL.path) else {
            return nil
        }
        
        var image: UIImage!
        if memcmp((data as NSData).bytes, "GIF89a", 6) == 0 {
            image = UIImage.animatedImageWithAnimatedGIFData(data)
        } else {
            image = UIImage(data: data)
        }
        
        self.image = image
        return image
    }
    
    open func download(_ handler: @escaping (_ cache: HDImageCache, _ error: NSError?) -> Void) {
        let request = URLRequest(url: targetURL)
        HDImageCacheManager.defaultManager().session().downloadTask(with: request, completionHandler: { (location, response, error) -> Void in
            if let error = error {
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(cache: self, error: error)
                })
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    DispatchQueue.main.async(execute: { () -> Void in
                        handler(cache: self, error: NSError(domain: "HeidiKit", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: response.statusCode)]))
                    })
                    return
                }
            }
            
            guard let location = location else {
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(cache: self, error: NSError(domain: "HeidiKit", code: 500, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Download location not exists", comment: "HDImageCache download location not found")]))
                })
                return
            }
            
            let fileManager = FileManager.default
            do {
                if fileManager.fileExists(atPath: self.fileURL.path!) {
                    try fileManager.removeItem(at: self.fileURL)
                }
                try fileManager.moveItem(at: location, to: self.fileURL)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(cache: self, error: nil)
                })
            } catch let error as NSError {
                print(error)
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(cache: self, error: error)
                })
            }
            
            }) .resume()
    }
}
