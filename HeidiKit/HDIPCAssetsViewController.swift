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
    let operationQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = assetCollection.title
        
        clearsSelectionOnViewWillAppear = false
        collectionView?.allowsSelection = true
        collectionView?.allowsMultipleSelection = true
        
        PHPhotoLibrary.shared().register(self)
        
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = false
        
        scrollToBottomOnLayout = assetCollection.assetCollection.assetCollectionSubtype != .albumRegular && assetCollection.count > 0
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let viewSize = parent!.view.frame
        let base = min(viewSize.width, viewSize.height)
        let scale = UIScreen.main.scale
        let side = (base - 6) / 4
        size.width = side
        size.height = side
        scaledSize.width = side * scale
        scaledSize.height = side * scale
        
        navigationController?.addObserver(self, forKeyPath: "selectedAssets", options: .new, context: nil)
        updateToolbar()
        
        guard let collectionView = collectionView else {
            return
        }
        
        var assets = [PHAsset]()
        if assetCollection.count < 40 {
            assetCollection.assetsFetchResult.enumerateObjects({ (obj, index, stop) -> Void in
                assets.append(obj as! PHAsset)
            })
        } else if scrollToBottomOnLayout {
            // cache last 40
            for var i = assetCollection.count - 1; i >= assetCollection.count - 40; i -= 1 {
                assets.append(assetCollection.assetsFetchResult.object(at: i) as! PHAsset)
            }
        } else {
            // cache first 40
            for i in 0 ..< 40 {
                assets.append(assetCollection.assetsFetchResult.object(at: i) as! PHAsset)
            }
        }
        
        imageManager.startCachingImages(for: assets, targetSize: scaledSize, contentMode: .aspectFill, options: requestOptions)
        
        if let selectedItemsIndexes = collectionView.indexPathsForSelectedItems {
            collectionView.reloadItems(at: selectedItemsIndexes)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.removeObserver(self, forKeyPath: "selectedAssets")
        imageManager.stopCachingImagesForAllAssets()

        super.viewWillDisappear(animated)
    }
        
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        updateToolbar()
    }
    
    func updateToolbar() {
        guard let picker = navigationController as? HDImagePickerController else {
            countTextItem.title = ""
            selectedButtonItem.isEnabled = false
            return
        }
        
        countTextItem.title = "\(picker.selectedAssets.count) / \(picker.maxImageCount)"
        selectedButtonItem.isEnabled = !picker.selectedAssets.isEmpty
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if scrollToBottomOnLayout {
            self.collectionView?.scrollToItem(at: IndexPath(row: assetCollection.count - 1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: false)
            scrollToBottomOnLayout = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
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
            
            coordinator.animate(alongsideTransition: { (context) -> Void in
                // offset adjustment
                let invalidationContext = UICollectionViewFlowLayoutInvalidationContext()
                invalidationContext.contentOffsetAdjustment = CGPoint(x: 0, y: beforeContentPosition * (collectionView.contentSize.height - collectionView.contentInset.top - collectionView.contentInset.bottom) - collectionView.contentOffset.y - collectionView.contentInset.top)
                self.collectionViewLayout.invalidateLayout(with: invalidationContext)
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
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetCollection.assetsFetchResult.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as! HDIPCAssetCell
        
        let asset = assetCollection.assetsFetchResult.object(at: indexPath.row) as! PHAsset
        
        // select status update (for album/camera roll intersection)
        if let imagePicker = navigationController as? HDImagePickerController {
            if imagePicker.selectedAssets.contains(asset) {
                if !cell.isSelected {
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
                    cell.isSelected = true
                }
            } else if cell.isSelected {
                // not contains but selected
                collectionView.deselectItem(at: indexPath, animated: false)
                cell.isSelected = false
            }
        }
        
        // Configure the cell
        cell.imageRequestID = imageManager.requestImage(for: asset, targetSize: scaledSize, contentMode: .aspectFill, options: self.requestOptions) { (image, info) -> Void in
            if let requestID = info![PHImageResultRequestIDKey] as? NSNumber {
                DispatchQueue.main.async {
                    if requestID.int32Value == cell.imageRequestID {
                        cell.imageView.image = image
                    }
                }
            }
        }
        
        cell.selectedImageView.isHidden = !cell.isSelected
        if cell.isHighlighted {
            cell.imageView.alpha = 0.5
        } else if cell.isSelected {
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! HDIPCAssetCell
        cell.selectedImageView.isHidden = false
        cell.imageView.alpha = 0.7
        
        let imagePicker = navigationController as! HDImagePickerController
        imagePicker.selectedAssets.append(assetCollection.assetsFetchResult.object(at: indexPath.row) as! PHAsset)
        updateToolbar()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! HDIPCAssetCell
        cell.selectedImageView.isHidden = true
        cell.imageView.alpha = 1
        
        let imagePicker = navigationController as! HDImagePickerController
        imagePicker.selectedAssets.remove(at: imagePicker.selectedAssets.index(of: assetCollection.assetsFetchResult.object(at: indexPath.row) as! PHAsset)!)
        updateToolbar()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! HDIPCAssetCell
        cell.backgroundColor = UIColor.black
        cell.imageView.alpha = 0.5
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! HDIPCAssetCell
        cell.backgroundColor = UIColor.white
        cell.imageView.alpha = 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let imagePicker = navigationController as! HDImagePickerController
        return imagePicker.selectedAssets.count < imagePicker.maxImageCount
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let details = changeInstance.changeDetails(for: assetCollection.assetsFetchResult) {
            DispatchQueue.main.async {
                if details.hasIncrementalChanges {
                    self.collectionView?.performBatchUpdates({ () -> Void in
                        if self.assetCollection._assetsFetchResult != details.fetchResultAfterChanges {
                            self.assetCollection._assetsFetchResult = details.fetchResultAfterChanges
                        }
                        
                        if let removedIndexes = details.removedIndexes {
                            var removedIndexPaths = [IndexPath]()
                            removedIndexPaths.reserveCapacity(removedIndexes.count)
                            (removedIndexes as NSIndexSet).enumerate({ (idx, stop) -> Void in
                                removedIndexPaths.append(IndexPath(row: idx, section: 0))
                            })
                            self.collectionView?.deleteItems(at: removedIndexPaths)
                        }
                        
                        if let insertedIndexes = details.insertedIndexes {
                            var insertedIndexPaths = [IndexPath]()
                            insertedIndexPaths.reserveCapacity(insertedIndexes.count)
                            (insertedIndexes as NSIndexSet).enumerate({ (idx, stop) -> Void in
                                insertedIndexPaths.append(IndexPath(row: idx, section: 0))
                            })
                            self.collectionView?.insertItems(at: insertedIndexPaths)
                        }
                        
                        if let changedIndexes = details.changedIndexes {
                            var changedIndexPaths = [IndexPath]()
                            changedIndexPaths.reserveCapacity(changedIndexes.count)
                            (changedIndexes as NSIndexSet).enumerate({ (idx, stop) -> Void in
                                changedIndexPaths.append(IndexPath(row: idx, section: 0))
                            })
                            self.collectionView?.reloadItems(at: changedIndexPaths)
                        }
                        
                        details.enumerateMoves({ (fromIndex, toIndex) -> Void in
                            self.collectionView?.moveItem(at: IndexPath(row: fromIndex, section:0), to: IndexPath(row: toIndex, section: 0))
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let count = floor(collectionView.frame.size.width / size.width)
        return (collectionView.frame.size.width - count * size.width) / (count - 1)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectedListViewController = segue.destination as? HDIPCSelectedListViewController {
            selectedListViewController.setValue(navigationController?.value(forKey: "selectedAssets"), forKey: "assets")
        }
    }
}
