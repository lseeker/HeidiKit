//
//  HDImagePickerControllerDelegate.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 12..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import Foundation
import Photos

@objc public protocol HDImagePickerControllerDelegate : UINavigationControllerDelegate {
    func imagePickerController(picker: HDImagePickerController, didFinishWithPhotoAssets: [PHAsset])
    
    optional func imagePickerControllerDidCancel(picker: HDImagePickerController)
}
