//
//  HDIPCAssetCell.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 8..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCAssetCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    
    var imageRequestID : PHImageRequestID?
}
