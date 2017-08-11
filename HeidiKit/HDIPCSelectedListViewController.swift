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
    var assets: [PHAsset]!
    var imageAssets = [HDIPCSelectedAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.shared().register(self)
        
        for asset in assets {
            let imageAsset = HDIPCSelectedAsset(asset)
            self.imageAssets.append(imageAsset)
            self.downloadImageAsset(imageAsset)
        }
        
        isEditing = true
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    @IBAction func dismiss() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedAssetCell", for: indexPath) as! HDIPCSelectedAssetCell
        
        // Configure the cell...
        let asset = imageAssets[indexPath.row]
        
        if let fileName = asset.fileName {
            cell.nameLabel.text = fileName
        } else {
            cell.nameLabel.text = "Loading..."
        }
        cell.dateLabel.text = asset.formattedDate
        
        if asset.needLoading {
            cell.resolutionLabel.text = "Downloading... \(asset.resolution)"
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
                if let index = self.imageAssets.index(of: asset) {
                    if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? HDIPCSelectedAssetCell {
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
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Deselect"
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            imageAssets.remove(at: indexPath.row)
            assets.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let asset = assets.remove(at: fromIndexPath.row)
        assets.insert(asset, at: toIndexPath.row)
        
        let iAsset = imageAssets.remove(at: fromIndexPath.row)
        imageAssets.insert(iAsset, at: toIndexPath.row)
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
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
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            for (index, imageAsset) in self.imageAssets.enumerated() {
                if let details = changeInstance.changeDetails(for: imageAsset.asset) {
                    if details.assetContentChanged {
                        let afterAsset = HDIPCSelectedAsset(details.objectAfterChanges as! PHAsset)
                        self.imageAssets[index] = afterAsset
                        self.downloadImageAsset(afterAsset)
                        
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
                    }
                }
            }
        }
    }
    
    fileprivate func downloadImageAsset(_ imageAsset : HDIPCSelectedAsset) {
        imageAsset.downloadFullsizeImage({ (asset) -> Void in
            if let index = self.imageAssets.index(of: asset) {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? HDIPCSelectedAssetCell {
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
