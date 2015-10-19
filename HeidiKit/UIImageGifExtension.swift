//
//  UIImageGifExtension.swift
//  DCLifeHD
//
//  Created by Yun-young LEE on 2015. 10. 9..
//  Copyright © 2015년 Yun-young LEE. All rights reserved.
//

import UIKit
import ImageIO

extension UIImage {
    class func animatedImageWithAnimatedGIFData(data: NSData) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data, nil) else {
            return nil
        }
        
        let imageCount = CGImageSourceGetCount(source)
        if imageCount == 1 {
            // not animated gif
            return UIImage(CGImage: CGImageSourceCreateImageAtIndex(source, 0, nil)!)
        }
        
        var images = [CGImageRef]()
        var delays = [Int]()
        
        for var i = 0; i < imageCount; ++i {
            images.append(CGImageSourceCreateImageAtIndex(source, i, nil)!)
            delays.append(delayForImageAtIndex(source, index: i))
        }
        
        var totalDuration = 0
        for delay in delays {
            totalDuration += delay
        }
        
        let frames = frameArray(imageCount, images: images, delays: delays)
        return UIImage.animatedImageWithImages(frames, duration: Double(totalDuration) / 100.0)
    }
    
    class func delayForImageAtIndex(source: CGImageSourceRef, index: Int) -> Int {
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
    
    class func frameArray(count: Int, images: [CGImageRef], delays: [Int]) -> [UIImage] {
        let gcd = vectorGCD(delays)
        var frames = [UIImage]()
        
        for var i = 0; i < count; ++i {
            let frame = UIImage(CGImage: images[i])
            for var j = delays[i] / gcd; j > 0; --j {
                frames.append(frame)
            }
        }
        
        return frames
    }

    class func vectorGCD(values: [Int]) -> Int {
        var gcd = values[0]
        for value in values.suffixFrom(1) {
            gcd = pairGCD(value, gcd)
        }
        return gcd
    }
    
    class func pairGCD(var a: Int, var _ b: Int) -> Int {
        if a < b {
            return pairGCD(b, a)
        }
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