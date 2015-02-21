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
    var assetCollections : [HDAssetCollection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imagePicker = navigationController as HDImagePickerController
        imagePicker.setupToolbar(self)
        
        loadCollections()
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch (PHPhotoLibrary.authorizationStatus()) {
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization { (status) -> Void in
                if status == PHAuthorizationStatus.Authorized {
                    self.loadCollections()
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.showUnauthrizedAlert()
                    }
                }
            }
        case .Authorized:
            break
        default:
            showUnauthrizedAlert()
        }
    }
    
    private func loadCollections() {
        var assetCollections = [HDAssetCollection]()
        
        // camera roll
        var result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.SmartAlbumUserLibrary, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // photo stream
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumMyPhotoStream, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // favorites
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.SmartAlbumFavorites, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // regular album
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumRegular, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // synced event
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumSyncedEvent, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // synced faces
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumSyncedFaces, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // synced album
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumSyncedAlbum, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // imported
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumImported, options: nil);
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        // cloud shared
        result = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumCloudShared, options: nil)
        result.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as PHAssetCollection))
        }
        
        self.assetCollections = assetCollections
    }
    
    func photoLibraryDidChange(changeInstance: PHChange!) {
        dispatch_async(dispatch_get_main_queue()) {
            for var i = 0; i < self.assetCollections.count; ++i {
                if let assetCollectionChangeDetails = changeInstance.changeDetailsForObject(self.assetCollections[i].assetCollection) {
                    if assetCollectionChangeDetails.objectWasDeleted {
                        self.assetCollections.removeAtIndex(i)
                        self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                        --i
                    } else if let afterChanges = assetCollectionChangeDetails.objectAfterChanges as? PHAssetCollection {
                        if self.assetCollections[i].assetCollection != afterChanges {
                            self.assetCollections[i].assetCollection = afterChanges
                            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    }
                }
                
                if let fetchResult = self.assetCollections[i]._assetsFetchResult {
                    if let fetchResultChangeDetails = changeInstance.changeDetailsForFetchResult(fetchResult) {
                        if self.assetCollections[i]._assetsFetchResult != fetchResultChangeDetails.fetchResultAfterChanges {
                            self.assetCollections[i]._assetsFetchResult = fetchResultChangeDetails.fetchResultAfterChanges
                        }
                        
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
            }
        }
    }
    
    func showUnauthrizedAlert() {
        let alertController = UIAlertController(title: "Unauthorized", message: "Cannot access to photo library. Check Settings -> Privacy -> Photos", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        var visibleIndexPaths = tableView.indexPathsForVisibleRows() as [NSIndexPath]?
        if visibleIndexPaths == nil {
            visibleIndexPaths = [NSIndexPath]()
        }
        
        for (index, assetCollection) in enumerate(assetCollections) {
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
        let cell = tableView.dequeueReusableCellWithIdentifier("AssetCollectionCell", forIndexPath: indexPath) as HDIPCAssetCollectionCell
        
        // Configure the cell...
        let assetCollection = assetCollections[indexPath.row]
        
        cell.titleLabel.text = assetCollection.title
        cell.detailLabel.text = String(assetCollection.assetsFetchResult.count)
        
        if let keyImage = assetCollection.keyImage {
            cell.keyImageView.image = keyImage
        } else {
            cell.keyImageView.image = UIImage(named: "EmptyAssetCollection", inBundle: NSBundle(forClass: HDIPCAssetCollectionViewController.self), compatibleWithTraitCollection: nil)
            assetCollection.fetchKeyImage({ (keyImage) -> Void in
                if let index = find(self.assetCollections, assetCollection) {
                    if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? HDIPCAssetCollectionCell {
                        cell.keyImageView.image = keyImage
                    }
                }
            })
        }
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    //override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    //        return 80.0
    //  }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let assetsViewController = segue.destinationViewController as? HDIPCAssetsViewController {
            assetsViewController.assetCollection = assetCollections[tableView.indexPathForSelectedRow()!.row]
        }
    }
}
