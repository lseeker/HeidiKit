//
//  HDImageCacheManager.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 10. 19..
//  Copyright © 2015년 inode.kr. All rights reserved.
//

import UIKit

open class HDImageCacheManager: NSObject {
    static let instance = HDImageCacheManager()

    open class func defaultManager() -> HDImageCacheManager {
        return instance
    }

    open var sessionConfiguration: URLSessionConfiguration? {
        didSet {
            _session = nil
        }
    }
    var _session: URLSession?
    lazy var cacheDirectoryURL: URL = {
        let cacheURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("_HDImageCache")
        
        // make cache directory available
        try! FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        
        return cacheURL
    }()
    
    var imageCaches = [URL: HDImageCache]()
    
    open func imageCacheFor(_ URL: Foundation.URL) -> HDImageCache {
        if let imageCache = imageCaches[URL] {
            return imageCache
        }
        
        let imageCache = HDImageCache(targetURL: URL)
        imageCaches[URL] = imageCache
        return imageCache
    }
    
    open func purge() {
        imageCaches.removeAll()
    }

    open func session() -> URLSession {
        if let session = _session {
            return session
        }
        
        if let sessionConfiguration = sessionConfiguration {
            _session = URLSession(configuration: sessionConfiguration)
        } else {
            _session = URLSession()
        }
        return _session!
    }
    
}
