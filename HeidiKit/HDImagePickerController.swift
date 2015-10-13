//
//  HDImagePickerControllerViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 1. 29..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

public class HDImagePickerController: UINavigationController, PHPhotoLibraryChangeObserver {
    @IBOutlet public var imagePickerDelegate : HDImagePickerControllerDelegate?
    @IBInspectable public var maxImageCount = 5
    
    var selectedAssets = [PHAsset]() {
        willSet {
            willChangeValueForKey("selectedAssets")
        }
        didSet {
            didChangeValueForKey("selectedAsstes")
        }
    }
    
    class public func newImagePickerController() -> HDImagePickerController {
        return UIStoryboard(name: "HDImagePickerController", bundle: NSBundle(forClass: HDImagePickerController.self)).instantiateInitialViewController() as! HDImagePickerController
    }
    
    public init() {
        super.init(rootViewController: UIStoryboard(name: "HDImagePickerController", bundle: NSBundle(forClass: HDImagePickerController.self)).instantiateViewControllerWithIdentifier("HDIPCAssetCollectionViewController") )
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    public func photoLibraryDidChange(changeInstance: PHChange) {
        var selectedAssets = self.selectedAssets
        var removedAssetIndexes = [Int]()
        
        for (idx, asset) in selectedAssets.enumerate() {
            guard let details = changeInstance.changeDetailsForObject(asset) else {
                continue
            }
            
            if details.objectWasDeleted {
                removedAssetIndexes.append(idx)
            } else if let changed = details.objectAfterChanges as? PHAsset {
                selectedAssets[idx] = changed
            }
        }
        
        // reverse for index based remove
        for removedAssetIndex in removedAssetIndexes.reverse() {
            selectedAssets.removeAtIndex(removedAssetIndex)
        }
        
        // trigger observation
        self.selectedAssets = selectedAssets
    }
    
    // behave first responser for doDone and doCancel
    public override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        becomeFirstResponder()
    }
    
    // MARK: - Actions
    
    @IBAction func doDone() {
        if let delegate = imagePickerDelegate {
            delegate.imagePickerController(self, didFinishWithPhotoAssets: selectedAssets)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func doCancel() {
        if let delegate = imagePickerDelegate {
            if let didCancel = delegate.imagePickerControllerDidCancel {
                didCancel(self)
                return
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
