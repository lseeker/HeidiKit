//
//  HDIPCAssetsViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 7..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCAssetsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    @IBOutlet weak var countTextItem: UIBarButtonItem!
    @IBOutlet weak var selectedButtonItem: UIBarButtonItem!
    
    var assetCollection : HDAssetCollection!
    let imageManager = PHCachingImageManager()
    let requestOptions = PHImageRequestOptions()
    var size = CGSize()
    var scaledSize = CGSize()
    var scrollToBottomOnLayout = false
    let operationQueue = NSOperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = assetCollection.title
        
        clearsSelectionOnViewWillAppear = false
        collectionView?.allowsSelection = true
        collectionView?.allowsMultipleSelection = true
        
        let screenSize = UIScreen.mainScreen().bounds.size
        let base = min(screenSize.width, screenSize.height)
        let scale = UIScreen.mainScreen().scale
        let side = (base - 6) / 4
        size.width = side
        size.height = side
        scaledSize.width = side * scale
        scaledSize.height = side * scale
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        requestOptions.deliveryMode = .HighQualityFormat
        requestOptions.synchronous = false
        
        scrollToBottomOnLayout = assetCollection.assetCollection.assetCollectionSubtype != .AlbumRegular && assetCollection.count > 0
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.addObserver(self, forKeyPath: "selectedAssets", options: .New, context: nil)
        updateToolbar()
        
        guard let collectionView = collectionView else {
            return
        }
        
        var assets = [PHAsset]()
        if assetCollection.count < 40 {
            assetCollection.assetsFetchResult.enumerateObjectsUsingBlock({ (obj, index, stop) -> Void in
                assets.append(obj as! PHAsset)
            })
        } else if scrollToBottomOnLayout {
            // cache last 40
            for var i = assetCollection.count - 1; i >= assetCollection.count - 40; --i {
                assets.append(assetCollection.assetsFetchResult.objectAtIndex(i) as! PHAsset)
            }
        } else {
            // cache first 40
            for var i = 0; i < 40; ++i {
                assets.append(assetCollection.assetsFetchResult.objectAtIndex(i) as! PHAsset)
            }
        }
        
        imageManager.startCachingImagesForAssets(assets, targetSize: scaledSize, contentMode: .AspectFill, options: requestOptions)
        
        if let selectedItemsIndexes = collectionView.indexPathsForSelectedItems() {
            collectionView.reloadItemsAtIndexPaths(selectedItemsIndexes)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.removeObserver(self, forKeyPath: "selectedAssets")
        imageManager.stopCachingImagesForAllAssets()

        super.viewWillDisappear(animated)
    }
        
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        updateToolbar()
    }
    
    func updateToolbar() {
        guard let picker = navigationController as? HDImagePickerController else {
            countTextItem.title = ""
            selectedButtonItem.enabled = false
            return
        }
        
        countTextItem.title = "\(picker.selectedAssets.count) / \(picker.maxImageCount)"
        selectedButtonItem.enabled = !picker.selectedAssets.isEmpty
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
            //let frameSize = collectionView.frame.size
            /*
            collectionView.frame.size = size
            let invalidationContext = UICollectionViewFlowLayoutInvalidationContext()
            invalidationContext.invalidateFlowLayoutDelegateMetrics = true
            collectionViewLayout.invalidateLayoutWithContext(invalidationContext)
            let afterContentSize = collectionViewLayout.collectionViewContentSize()
            collectionView.frame.size = afterContentSize
            */
            
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AssetCell", forIndexPath: indexPath) as! HDIPCAssetCell
        
        let asset = assetCollection.assetsFetchResult.objectAtIndex(indexPath.row) as! PHAsset
        
        // select status update (for album/camera roll intersection)
        if let imagePicker = navigationController as? HDImagePickerController {
            if imagePicker.selectedAssets.contains(asset) {
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
        cell.imageRequestID = imageManager.requestImageForAsset(asset, targetSize: scaledSize, contentMode: .AspectFill, options: self.requestOptions) { (image, info) -> Void in
            if let requestID = info![PHImageResultRequestIDKey] as? NSNumber {
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
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! HDIPCAssetCell
        cell.selectedImageView.hidden = false
        cell.imageView.alpha = 0.7
        
        let imagePicker = navigationController as! HDImagePickerController
        imagePicker.selectedAssets.append(assetCollection.assetsFetchResult.objectAtIndex(indexPath.row) as! PHAsset)
        updateToolbar()
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! HDIPCAssetCell
        cell.selectedImageView.hidden = true
        cell.imageView.alpha = 1
        
        let imagePicker = navigationController as! HDImagePickerController
        imagePicker.selectedAssets.removeAtIndex(imagePicker.selectedAssets.indexOf(assetCollection.assetsFetchResult.objectAtIndex(indexPath.row) as! PHAsset)!)
        updateToolbar()
    }
    
    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! HDIPCAssetCell
        cell.backgroundColor = UIColor.blackColor()
        cell.imageView.alpha = 0.5
    }
    
    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! HDIPCAssetCell
        cell.backgroundColor = UIColor.whiteColor()
        cell.imageView.alpha = 1
    }
    
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let imagePicker = navigationController as! HDImagePickerController
        return imagePicker.selectedAssets.count < imagePicker.maxImageCount
    }
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        if let details = changeInstance.changeDetailsForFetchResult(assetCollection.assetsFetchResult) {
            dispatch_async(dispatch_get_main_queue()) {
                if details.hasIncrementalChanges {
                    self.collectionView?.performBatchUpdates({ () -> Void in
                        if self.assetCollection._assetsFetchResult != details.fetchResultAfterChanges {
                            self.assetCollection._assetsFetchResult = details.fetchResultAfterChanges
                        }
                        
                        if let removedIndexes = details.removedIndexes {
                            var removedIndexPaths = [NSIndexPath]()
                            removedIndexPaths.reserveCapacity(removedIndexes.count)
                            removedIndexes.enumerateIndexesUsingBlock({ (idx, stop) -> Void in
                                removedIndexPaths.append(NSIndexPath(forRow: idx, inSection: 0))
                            })
                            self.collectionView?.deleteItemsAtIndexPaths(removedIndexPaths)
                        }
                        
                        if let insertedIndexes = details.insertedIndexes {
                            var insertedIndexPaths = [NSIndexPath]()
                            insertedIndexPaths.reserveCapacity(insertedIndexes.count)
                            insertedIndexes.enumerateIndexesUsingBlock({ (idx, stop) -> Void in
                                insertedIndexPaths.append(NSIndexPath(forRow: idx, inSection: 0))
                            })
                            self.collectionView?.insertItemsAtIndexPaths(insertedIndexPaths)
                        }
                        
                        if let changedIndexes = details.changedIndexes {
                            var changedIndexPaths = [NSIndexPath]()
                            changedIndexPaths.reserveCapacity(changedIndexes.count)
                            changedIndexes.enumerateIndexesUsingBlock({ (idx, stop) -> Void in
                                changedIndexPaths.append(NSIndexPath(forRow: idx, inSection: 0))
                            })
                            self.collectionView?.reloadItemsAtIndexPaths(changedIndexPaths)
                        }
                        
                        details.enumerateMovesWithBlock({ (fromIndex, toIndex) -> Void in
                            self.collectionView?.moveItemAtIndexPath(NSIndexPath(forRow: fromIndex, inSection:0), toIndexPath: NSIndexPath(forRow: toIndex, inSection: 0))
                            return
                        })
                        
                        }, completion: nil)
                } else {
                    if self.assetCollection._assetsFetchResult != details.fetchResultAfterChanges {
                        self.assetCollection._assetsFetchResult = details.fetchResultAfterChanges
                    }
                    self.collectionView?.reloadData()
                }
            }
        }
        
    }
    
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
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let selectedListViewController = segue.destinationViewController as? HDIPCSelectedListViewController {
            selectedListViewController.setValue(navigationController?.valueForKey("selectedAssets"), forKey: "assets")
        }
    }
}
