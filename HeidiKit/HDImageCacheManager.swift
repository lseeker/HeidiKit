//
//  HDImageCacheManager.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 10. 19..
//  Copyright © 2015년 inode.kr. All rights reserved.
//

import UIKit

public class HDImageCacheManager: NSObject {
    static let instance = HDImageCacheManager()

    public class func defaultManager() -> HDImageCacheManager {
        return instance
    }

    public var sessionConfiguration: NSURLSessionConfiguration? {
        didSet {
            _session = nil
        }
    }
    var _session: NSURLSession?
    lazy var cacheDirectoryURL: NSURL = {
        let cacheURL = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false).URLByAppendingPathComponent("_HDImageCache")
        
        // make cache directory available
        try! NSFileManager.defaultManager().createDirectoryAtURL(cacheURL, withIntermediateDirectories: true, attributes: nil)
        
        return cacheURL
    }()
    
    var imageCaches = [NSURL: HDImageCache]()
    
    public func imageCacheFor(URL: NSURL) -> HDImageCache {
        if let imageCache = imageCaches[URL] {
            return imageCache
        }
        
        let imageCache = HDImageCache(targetURL: URL)
        imageCaches[URL] = imageCache
        return imageCache
    }
    
    public func purge() {
        imageCaches.removeAll()
    }

    public func session() -> NSURLSession {
        if let session = _session {
            return session
        }
        
        if let sessionConfiguration = sessionConfiguration {
            _session = NSURLSession(configuration: sessionConfiguration)
        } else {
            _session = NSURLSession()
        }
        return _session!
    }
    
}
