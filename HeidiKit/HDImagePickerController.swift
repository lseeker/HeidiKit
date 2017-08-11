//
//  HDImagePickerControllerViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 1. 29..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

open class HDImagePickerController: UINavigationController, PHPhotoLibraryChangeObserver {
    @IBOutlet open var imagePickerDelegate : HDImagePickerControllerDelegate?
    @IBInspectable open var maxImageCount = 5
    
    var selectedAssets = [PHAsset]() {
        willSet {
            willChangeValue(forKey: "selectedAssets")
        }
        didSet {
            didChangeValue(forKey: "selectedAsstes")
        }
    }
    
    class open func newImagePickerController() -> HDImagePickerController {
        return UIStoryboard(name: "HDImagePickerController", bundle: Bundle(for: HDImagePickerController.self)).instantiateInitialViewController() as! HDImagePickerController
    }
    
    public init() {
        super.init(rootViewController: UIStoryboard(name: "HDImagePickerController", bundle: Bundle(for: HDImagePickerController.self)).instantiateViewController(withIdentifier: "HDIPCAssetCollectionViewController") )
        
        PHPhotoLibrary.shared().register(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    open func photoLibraryDidChange(_ changeInstance: PHChange) {
        var selectedAssets = self.selectedAssets
        var removedAssetIndexes = [Int]()
        
        for (idx, asset) in selectedAssets.enumerated() {
            guard let details = changeInstance.changeDetails(for: asset) else {
                continue
            }
            
            if details.objectWasDeleted {
                removedAssetIndexes.append(idx)
            } else if let changed = details.objectAfterChanges as? PHAsset {
                selectedAssets[idx] = changed
            }
        }
        
        // reverse for index based remove
        for removedAssetIndex in removedAssetIndexes.reversed() {
            selectedAssets.remove(at: removedAssetIndex)
        }
        
        // trigger observation
        self.selectedAssets = selectedAssets
    }
    
    // behave first responser for doDone and doCancel
    open override var canBecomeFirstResponder : Bool {
        return true
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        becomeFirstResponder()
    }
    
    // MARK: - Actions
    
    @IBAction func doDone() {
        if let delegate = imagePickerDelegate {
            delegate.imagePickerController(self, didFinishWithPhotoAssets: selectedAssets)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func doCancel() {
        if let delegate = imagePickerDelegate {
            if let didCancel = delegate.imagePickerControllerDidCancel {
                didCancel(self)
                return
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}
