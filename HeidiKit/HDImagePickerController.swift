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
    
    var selectedAssets = NSMutableOrderedSet()
    
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
            delegate.imagePickerController(self, didFinishWithPhotoAssets: [PHAsset](selectedAssets.array as [PHAsset]))
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
                selectedListViewController.assets = selectedAssets
            }
        }
    }

}
