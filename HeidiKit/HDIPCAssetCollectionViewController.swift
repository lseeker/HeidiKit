//
//  HDImagePickerAssetCollectionViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 1. 27..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCAssetCollectionViewController: UITableViewController, PHPhotoLibraryChangeObserver {
    @IBOutlet weak var countTextItem: UIBarButtonItem!
    @IBOutlet weak var selectedButtonItem: UIBarButtonItem!
    
    var assetCollections = [HDAssetCollection]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if PHPhotoLibrary.authorizationStatus() == .Authorized {
            loadCollections()
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.addObserver(self, forKeyPath: "selectedAssets", options: .New, context: nil)
        updateToolbar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.removeObserver(self, forKeyPath: "selectedAssets")
        
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        switch (PHPhotoLibrary.authorizationStatus()) {
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization { (status) -> Void in
                if status == .Authorized {
                    self.loadCollections()
                    self.tableView.reloadData()
                } else {
                    self.showUnauthrizedAlert()
                }
            }
        case .Authorized:
            // already loaded from viewDidLoad
            break
        default:
            showUnauthrizedAlert()
        }
    }
    
    private func loadCollections() {
        var assetCollections = [HDAssetCollection]()
        
        // camera roll
        var result = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumUserLibrary, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // photo stream
        result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumMyPhotoStream, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // favorites
        result = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumFavorites, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // regular album
        result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumRegular, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // synced event
        result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumSyncedEvent, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // synced faces
        result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumSyncedFaces, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // synced album
        result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumSyncedAlbum, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // imported
        result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumImported, options: nil);
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // cloud shared
        result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumCloudShared, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        
        self.assetCollections = assetCollections
    }
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        dispatch_async(dispatch_get_main_queue()) {
            for var i = 0; i < self.assetCollections.count; ++i {
                if let assetCollectionChangeDetails = changeInstance.changeDetailsForObject(self.assetCollections[i].assetCollection) {
                    if assetCollectionChangeDetails.objectWasDeleted {
                        self.assetCollections.removeAtIndex(i)
                        self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Fade)
                        --i
                    } else if let afterChanges = assetCollectionChangeDetails.objectAfterChanges as? PHAssetCollection {
                        self.assetCollections[i] = HDAssetCollection(afterChanges)
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Automatic)
                    }
                }
                
                if let fetchResult = self.assetCollections[i]._assetsFetchResult {
                    if let fetchResultChangeDetails = changeInstance.changeDetailsForFetchResult(fetchResult) {
                        self.assetCollections[i]._assetsFetchResult = fetchResultChangeDetails.fetchResultAfterChanges
                        
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Automatic)
                    }
                }
            }
        }
    }
    
    func showUnauthrizedAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Unauthorized", comment: "Unauthorized alert title"), message: NSLocalizedString("Cannot access to photo library. Check Settings -> Privacy -> Photos", comment: "Unauthorized alert message"), preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .Cancel, handler: { (action) -> Void in
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        var visibleIndexPaths = tableView.indexPathsForVisibleRows
        if visibleIndexPaths == nil {
            visibleIndexPaths = [NSIndexPath]()
        }
        
        for (index, assetCollection) in assetCollections.enumerate() {
            var visible = false
            for visibleIndexPath in visibleIndexPaths! {
                if index == visibleIndexPath.row {
                    visible = true
                    break
                }
            }
            if !visible {
                assetCollection.cleanUp()
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollections.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AssetCollectionCell", forIndexPath: indexPath) as! HDIPCAssetCollectionCell
        
        // Configure the cell...
        let assetCollection = assetCollections[indexPath.row]
        
        cell.titleLabel.text = assetCollection.title
        cell.detailLabel.text = String(assetCollection.assetsFetchResult.count)
        
        if let keyImage = assetCollection.keyImage {
            cell.keyImageView.image = keyImage
        } else {
            cell.keyImageView.image = UIImage(named: "EmptyAssetCollection", inBundle: NSBundle(forClass: HDIPCAssetCollectionViewController.self), compatibleWithTraitCollection: nil)
            assetCollection.fetchKeyImage({ (keyImage) -> Void in
                if let index = self.assetCollections.indexOf(assetCollection) {
                    if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? HDIPCAssetCollectionCell {
                        cell.keyImageView.image = keyImage
                    }
                }
            })
        }
        
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let assetsViewController = segue.destinationViewController as? HDIPCAssetsViewController {
            assetsViewController.assetCollection = assetCollections[tableView.indexPathForSelectedRow!.row]
        } else if let selectedListViewController = segue.destinationViewController as? HDIPCSelectedListViewController {
            selectedListViewController.setValue(navigationController?.valueForKey("selectedAssets"), forKey: "assets")
        }
    }
    
}
