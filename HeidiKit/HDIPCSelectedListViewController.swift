//
//  HDIPCSelectedListViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 9..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCSelectedListViewController: UITableViewController, PHPhotoLibraryChangeObserver {
    var assets : NSMutableOrderedSet!
    var imageAssets = [HDIPCSelectedAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        assets.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            let imageAsset = HDIPCSelectedAsset(obj as PHAsset)
            self.imageAssets.append(imageAsset)
            self.downloadImageAsset(imageAsset)
        }
        
        editing = true
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    @IBAction func dismiss() {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SelectedAssetCell", forIndexPath: indexPath) as HDIPCSelectedAssetCell
        
        // Configure the cell...
        let asset = imageAssets[indexPath.row]
        
        if let fileName = asset.fileName {
            cell.nameLabel.text = fileName
        } else {
            cell.nameLabel.text = "Loading..."
        }
        cell.dateLabel.text = asset.formattedDate
        
        if asset.needLoading {
            cell.resolutionLabel.text = "Downloading..."
            cell.fileSizeLabel.text = nil
            cell.downloadIndicatorView.startAnimating()
        } else {
            cell.resolutionLabel.text = asset.resolution
            if let fileSize = asset.fileSize {
                cell.fileSizeLabel.text = String(format: "%0.2fMB", Double(fileSize) / 1024.0 / 1024.0)
            } else {
                cell.fileSizeLabel.text = nil
            }
            cell.downloadIndicatorView.stopAnimating()
        }
        
        if let thumbnail = asset.thumbnail {
            cell.thumnailImageView.image = thumbnail
        } else {
            cell.thumnailImageView.image = nil
            asset.loadThumbnail({ (asset) -> Void in
                if let index = find(self.imageAssets, asset) {
                    if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? HDIPCSelectedAssetCell {
                        cell.thumnailImageView.image = asset.thumbnail
                    }
                }
            })
        }
        
        
        return cell
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    
    */
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Deselect"
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            imageAssets.removeAtIndex(indexPath.row)
            assets.removeObjectAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        assets.moveObjectsAtIndexes(NSIndexSet(index: fromIndexPath.row), toIndex: toIndexPath.row)
        let asset = imageAssets.removeAtIndex(fromIndexPath.row)
        imageAssets.insert(asset, atIndex: toIndexPath.row)
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
    func photoLibraryDidChange(changeInstance: PHChange!) {
        dispatch_async(dispatch_get_main_queue()) {
            for (index, imageAsset) in enumerate(self.imageAssets) {
                if let details = changeInstance.changeDetailsForObject(imageAsset.asset) {
                    if details.assetContentChanged {
                        let afterAsset = HDIPCSelectedAsset(details.objectAfterChanges as PHAsset)
                        self.imageAssets[index] = afterAsset
                        self.downloadImageAsset(afterAsset)
                        
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
            }
        }
    }
    
    private func downloadImageAsset(imageAsset : HDIPCSelectedAsset) {
        imageAsset.downloadFullsizeImage({ (asset) -> Void in
            if let index = find(self.imageAssets, asset) {
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? HDIPCSelectedAssetCell {
                    cell.resolutionLabel.text = asset.resolution
                    if let fileSize = asset.fileSize {
                        cell.fileSizeLabel.text = String(format: "%0.2fMB", Double(fileSize) / 1024.0 / 1024.0)
                    } else {
                        cell.fileSizeLabel.text = nil
                    }
                    cell.downloadIndicatorView.stopAnimating()
                }
            }
        })
    }
}
