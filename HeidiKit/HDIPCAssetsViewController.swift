//
//  HDIPCAssetsViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 7..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCAssetsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var toolbarText: UIBarButtonItem!
    
    var assetCollection : HDAssetCollection!
    let imageManager = PHCachingImageManager()
    let requestOptions = PHImageRequestOptions()
    var size = CGSize()
    var scrollToBottomOnLayout = false
    let operationQueue = NSOperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = assetCollection.title
        
        clearsSelectionOnViewWillAppear = false
        collectionView?.allowsSelection = true
        collectionView?.allowsMultipleSelection = true
        
        let imagePicker = navigationController as HDImagePickerController
        imagePicker.setupToolbar(self)
        
        let screenSize = UIScreen.mainScreen().bounds.size
        let base = min(screenSize.width, screenSize.height)
        let side = (base - 6) / 4
        size.width = side
        size.height = side
        
        var assets = [PHAsset]()
        assetCollection.assetsFetchResult.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assets.append(obj as PHAsset)
        }
        
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.FastFormat
        
        imageManager.allowsCachingHighQualityImages = false
        imageManager.startCachingImagesForAssets(assets, targetSize: size, contentMode: PHImageContentMode.AspectFill, options: requestOptions)
        
        scrollToBottomOnLayout = assetCollection.assetCollection.assetCollectionSubtype != PHAssetCollectionSubtype.AlbumRegular && assetCollection.count > 0
        
        collectionView?.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let imagePicker = navigationController as HDImagePickerController
        imagePicker.updateToolbar()
        
        collectionView?.reloadItemsAtIndexPaths(collectionView?.indexPathsForSelectedItems() as [NSIndexPath])
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if scrollToBottomOnLayout {
            self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: assetCollection.count - 1, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: false)
            scrollToBottomOnLayout = false
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if let collectionView = self.collectionView {
            // get relative content position
            let realContentHeight = collectionView.contentSize.height - collectionView.contentInset.top - collectionView.contentInset.bottom
            let realContentOffset = collectionView.contentOffset.y + collectionView.contentInset.top
            let beforeContentPosition = realContentOffset / realContentHeight
            
            // caculate contentSize after transition
            let frameSize = collectionView.frame.size
            collectionView.frame.size = size
            let invalidationContext = UICollectionViewFlowLayoutInvalidationContext()
            invalidationContext.invalidateFlowLayoutDelegateMetrics = true
            collectionViewLayout.invalidateLayoutWithContext(invalidationContext)
            let afterContentSize = collectionViewLayout.collectionViewContentSize()
            collectionView.frame.size = frameSize
            
            coordinator.animateAlongsideTransition({ (context) -> Void in
                // offset adjustment
                let invalidationContext = UICollectionViewFlowLayoutInvalidationContext()
                invalidationContext.contentOffsetAdjustment = CGPoint(x: 0, y: beforeContentPosition * (collectionView.contentSize.height - collectionView.contentInset.top - collectionView.contentInset.bottom) - collectionView.contentOffset.y - collectionView.contentInset.top)
                self.collectionViewLayout.invalidateLayoutWithContext(invalidationContext)
                }, completion: nil)
        }
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetCollection.assetsFetchResult.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AssetCell", forIndexPath: indexPath) as HDIPCAssetCell
        
        let asset = assetCollection.assetsFetchResult.objectAtIndex(indexPath.row) as PHAsset
        
        // select status update (for album/camera roll intersection)
        if let imagePicker = navigationController as? HDImagePickerController {
            if imagePicker.selectedAssets.containsObject(asset) {
                if !cell.selected {
                    collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
                    cell.selected = true
                }
            } else if cell.selected {
                // not contains but selected
                collectionView.deselectItemAtIndexPath(indexPath, animated: false)
                cell.selected = false
            }
        }
        
        // Configure the cell
        cell.imageRequestID = imageManager.requestImageForAsset(asset, targetSize: size, contentMode: PHImageContentMode.AspectFill, options: self.requestOptions) { (image, info) -> Void in
            if let requestID = info[PHImageResultRequestIDKey] as? NSNumber {
                dispatch_async(dispatch_get_main_queue()) {
                    if requestID.intValue == cell.imageRequestID {
                        cell.imageView.image = image
                    }
                }
            }
        }
        
        cell.selectedImageView.hidden = !cell.selected
        if cell.highlighted {
            cell.imageView.alpha = 0.5
        } else if cell.selected {
            cell.imageView.alpha = 0.7
        } else {
            cell.imageView.alpha = 1
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
    }
    */
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as HDIPCAssetCell
        cell.selectedImageView.hidden = false
        cell.imageView.alpha = 0.7
        
        let imagePicker = navigationController as HDImagePickerController
        imagePicker.selectedAssets.addObject(assetCollection.assetsFetchResult.objectAtIndex(indexPath.row) as PHAsset)
        imagePicker.updateToolbar()
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as HDIPCAssetCell
        cell.selectedImageView.hidden = true
        cell.imageView.alpha = 1
        
        let imagePicker = navigationController as HDImagePickerController
        imagePicker.selectedAssets.removeObject(assetCollection.assetsFetchResult.objectAtIndex(indexPath.row) as PHAsset)
        imagePicker.updateToolbar()
    }
    
    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as HDIPCAssetCell
        cell.backgroundColor = UIColor.blackColor()
        cell.imageView.alpha = 0.5
    }
    
    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as HDIPCAssetCell
        cell.backgroundColor = UIColor.whiteColor()
        cell.imageView.alpha = 1
    }
    
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let imagePicker = navigationController as HDImagePickerController
        return imagePicker.selectedAssets.count < imagePicker.maxImageCount
    }
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return size
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        let count = floor(collectionView.frame.size.width / size.width)
        return (collectionView.frame.size.width - count * size.width) / (count - 1)
    }
    
}
