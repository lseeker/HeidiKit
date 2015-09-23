//
//  HDTab.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 6. 9..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit

class HDTab: UIView {
    
    var label = "";
    
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        super.drawRect(rect)
        
        let context = UIGraphicsGetCurrentContext()
        UIGraphicsPushContext(context);
        
        CGContextSetStrokeColorWithColor(context, UIColor(white: 0.39, alpha: 1.0).CGColor)
        CGContextSetLineWidth(context, 0.5)
        CGContextMoveToPoint(context, rect.size.width, 0.0);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
        CGContextStrokePath(context);

        UIGraphicsPopContext();
    }
    
}
