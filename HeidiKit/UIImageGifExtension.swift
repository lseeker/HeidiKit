//
//  UIImageGifExtension.swift
//  DCLifeHD
//
//  Created by Yun-young LEE on 2015. 10. 9..
//  Copyright © 2015년 Yun-young LEE. All rights reserved.
//

import UIKit
import ImageIO
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension UIImage {
    class func animatedImageWithAnimatedGIFData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let imageCount = CGImageSourceGetCount(source)
        if imageCount == 1 {
            // not animated gif
            return UIImage(cgImage: CGImageSourceCreateImageAtIndex(source, 0, nil)!)
        }
        
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in  0 ..< imageCount {
            images.append(CGImageSourceCreateImageAtIndex(source, i, nil)!)
            delays.append(delayForImageAtIndex(source, index: i))
        }
        
        var totalDuration = 0
        for delay in delays {
            totalDuration += delay
        }
        
        let frames = frameArray(imageCount, images: images, delays: delays)
        return UIImage.animatedImage(with: frames, duration: Double(totalDuration) / 100.0)
    }
    
    class func delayForImageAtIndex(_ source: CGImageSource, index: Int) -> Int {
        var delay = 1;
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as NSDictionary? else {
            return delay
        }
        
        guard let gifProps = properties[String(kCGImagePropertyGIFDictionary)] as? NSDictionary else {
            return delay
        }
        
        var number = gifProps[String(kCGImagePropertyGIFUnclampedDelayTime)] as? NSNumber
        if number == nil || number?.doubleValue == 0.0 {
            number = gifProps[String(kCGImagePropertyGIFDelayTime)] as? NSNumber
        }
        if number?.doubleValue > 0.0 {
            delay = lrint(number!.doubleValue * 100.0)
        }
        
        return delay
    }
    
    class func frameArray(_ count: Int, images: [CGImage], delays: [Int]) -> [UIImage] {
        let gcd = vectorGCD(delays)
        var frames = [UIImage]()
        
        for i in 0 ..< count {
            let frame = UIImage(cgImage: images[i])
            for j in ((0 + 1)...delays[i] / gcd).reversed() {
                frames.append(frame)
            }
        }
        
        return frames
    }

    class func vectorGCD(_ values: [Int]) -> Int {
        var gcd = values[0]
        for value in values.suffix(from: 1) {
            gcd = pairGCD(value, gcd)
        }
        return gcd
    }
    
    class func pairGCD(_ ap: Int, _ bp: Int) -> Int {
        if ap < bp {
            return pairGCD(bp, ap)
        }
        var a = ap;
        var b = bp;
        for ;; {
            let r = a % b
            if r == 0 {
                return b
            }
            a = b
            b = r
        }
    }
}
