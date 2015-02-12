//
//  HDImagePickerControllerViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 1. 29..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

public class HDImagePickerController: UINavigationController {
    @IBOutlet weak var toolbarText: UIBarButtonItem!
    @IBOutlet weak var toolbarSelectedListButton: UIBarButtonItem!
    
    @IBOutlet public var imagePickerDelegate : HDImagePickerControllerDelegate?
    @IBInspectable public var maxImageCount = 5
    
    class HDIPCSelectedAssets : NSObject, PHPhotoLibraryChangeObserver {
        private let selectedAssets = NSMutableOrderedSet()
        
        var count : Int {
            get { return selectedAssets.count }
        }
        
        var photoAssets : NSMutableOrderedSet {
            get { return selectedAssets }
        }
        
        override init() {
            super.init()
            
            PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        }
        
        deinit {
            PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        }
        
        func addObject(asset: PHAsset) {
            selectedAssets.addObject(asset)
        }
        
        func removeObject(asset: PHAsset) {
            selectedAssets.removeObject(asset)
        }
        
        func containsObject(asset: PHAsset) -> Bool {
            return selectedAssets.containsObject(asset)
        }
        
        func array() -> [PHAsset] {
            var array = [PHAsset]()
            array.reserveCapacity(selectedAssets.count)
            selectedAssets.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
                array.append(obj as PHAsset)
            }
            return array
        }
        
        func photoLibraryDidChange(changeInstance: PHChange!) {
            dispatch_async(dispatch_get_main_queue()) {
                self.selectedAssets.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
                    if let details = changeInstance.changeDetailsForObject(obj as PHAsset) {
                        if details.assetContentChanged {
                            let asset = details.objectAfterChanges as PHAsset
                            self.selectedAssets.setObject(asset, atIndex: index)
                        }
                    }
                }
            }
        }
    }
    let selectedAssets = HDIPCSelectedAssets()
    
    
    class public func newImagePickerController() -> HDImagePickerController {
        return UIStoryboard(name: "HDImagePickerController", bundle: NSBundle(forClass: HDImagePickerController.self)).instantiateInitialViewController() as HDImagePickerController
    }
    
    override public init() {
        super.init(rootViewController: UIStoryboard(name: "HDImagePickerController", bundle: NSBundle(forClass: HDImagePickerController.self)).instantiateViewControllerWithIdentifier("HDIPCAssetCollectionViewController") as UIViewController)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    @IBAction func doDone() {
        if let delegate = imagePickerDelegate {
            delegate.imagePickerController(self, didFinishWithPhotoAssets: selectedAssets.array())
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func doCancel() {
        if let delegate = imagePickerDelegate {
            if delegate.respondsToSelector(Selector("imagePickerControllerDidCancel:")) {
                delegate.imagePickerControllerDidCancel!(self)
                return
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateToolbar()
    }
    
    func setupToolbar(viewController : UIViewController) {
        viewController.toolbarItems = self.toolbarItems
    }
    
    func updateToolbar() {
        toolbarText.title = "\(selectedAssets.count) / \(maxImageCount)"
        toolbarSelectedListButton.enabled = selectedAssets.count > 0
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let navigationController = segue.destinationViewController as? UINavigationController {
            if let selectedListViewController = navigationController.topViewController as? HDIPCSelectedListViewController {
                selectedListViewController.assets = selectedAssets.photoAssets
            }
        }
    }
}
