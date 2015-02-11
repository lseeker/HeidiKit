//
//  HDIPCSelectedListViewController.swift
//  HeidiKit
//
//  Created by Yun-young LEE on 2015. 2. 9..
//  Copyright (c) 2015년 inode.kr. All rights reserved.
//

import UIKit
import Photos

class HDIPCSelectedListViewController: UITableViewController {
    var assets : NSMutableOrderedSet!
    var imageAssets = [HDIPCSelectedAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assets.enumerateObjectsUsingBlock { (obj, index, stop) -> Void in
            self.imageAssets.append(HDIPCSelectedAsset(asset: obj as PHAsset))
        }
        
        editing = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SelectedAssetCell", forIndexPath: indexPath) as HDIPCSelectedAssetCell
        
        // Configure the cell...
        let asset = imageAssets[indexPath.row]

        if let image = asset.image {
            cell.thumnailImageView.image = image
        } else {
            cell.thumnailImageView.image = nil
            asset.loadImage({ (asset) -> Void in
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            })
        }
        
        if let fileName = asset.fileName {
            cell.nameLabel.text = fileName
        } else {
            cell.nameLabel.text = "Loading..."
        }
        
        cell.dateLabel.text = asset.formattedDate
        cell.resolutionLabel.text = asset.resolution
        
        if let fileSize = asset.fileSize {
            cell.fileSizeLabel.text = String(format: "%0.2fMB", Double(fileSize) / 1024.0 / 1024.0)
        } else {
            cell.fileSizeLabel.text = nil
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
    
}
