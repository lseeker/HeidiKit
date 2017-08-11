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
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            loadCollections()
        }
        
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.addObserver(self, forKeyPath: "selectedAssets", options: .new, context: nil)
        updateToolbar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.removeObserver(self, forKeyPath: "selectedAssets")
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch (PHPhotoLibrary.authorizationStatus()) {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) -> Void in
                if status == .authorized {
                    self.loadCollections()
                    self.tableView.reloadData()
                } else {
                    self.showUnauthrizedAlert()
                }
            }
        case .authorized:
            // already loaded from viewDidLoad
            break
        default:
            showUnauthrizedAlert()
        }
    }
    
    fileprivate func loadCollections() {
        var assetCollections = [HDAssetCollection]()
        
        // camera roll
        var result = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // photo stream
        result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // favorites
        result = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // regular album
        result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // synced event
        result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedEvent, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // synced faces
        result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedFaces, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // synced album
        result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // imported
        result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumImported, options: nil);
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        // cloud shared
        result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil)
        result.enumerateObjects { (obj, index, stop) -> Void in
            assetCollections.append(HDAssetCollection(obj as! PHAssetCollection))
        }
        
        self.assetCollections = assetCollections
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            for var i = 0; i < self.assetCollections.count; i += 1 {
                if let assetCollectionChangeDetails = changeInstance.changeDetails(for: self.assetCollections[i].assetCollection) {
                    if assetCollectionChangeDetails.objectWasDeleted {
                        self.assetCollections.remove(at: i)
                        self.tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .fade)
                        i -= 1
                    } else if let afterChanges = assetCollectionChangeDetails.objectAfterChanges as? PHAssetCollection {
                        self.assetCollections[i] = HDAssetCollection(afterChanges)
                        self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
                    }
                }
                
                if let fetchResult = self.assetCollections[i]._assetsFetchResult {
                    if let fetchResultChangeDetails = changeInstance.changeDetails(for: fetchResult) {
                        self.assetCollections[i]._assetsFetchResult = fetchResultChangeDetails.fetchResultAfterChanges
                        
                        self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
                    }
                }
            }
        }
    }
    
    func showUnauthrizedAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Unauthorized", comment: "Unauthorized alert title"), message: NSLocalizedString("Cannot access to photo library. Check Settings -> Privacy -> Photos", comment: "Unauthorized alert message"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .cancel, handler: { (action) -> Void in
            self.navigationController?.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        var visibleIndexPaths = tableView.indexPathsForVisibleRows
        if visibleIndexPaths == nil {
            visibleIndexPaths = [IndexPath]()
        }
        
        for (index, assetCollection) in assetCollections.enumerated() {
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCollectionCell", for: indexPath) as! HDIPCAssetCollectionCell
        
        // Configure the cell...
        let assetCollection = assetCollections[indexPath.row]
        
        cell.titleLabel.text = assetCollection.title
        cell.detailLabel.text = String(assetCollection.assetsFetchResult.count)
        
        if let keyImage = assetCollection.keyImage {
            cell.keyImageView.image = keyImage
        } else {
            cell.keyImageView.image = UIImage(named: "EmptyAssetCollection", in: Bundle(for: HDIPCAssetCollectionViewController.self), compatibleWith: nil)
            assetCollection.fetchKeyImage({ (keyImage) -> Void in
                if let index = self.assetCollections.index(of: assetCollection) {
                    if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? HDIPCAssetCollectionCell {
                        cell.keyImageView.image = keyImage
                    }
                }
            })
        }
        
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let assetsViewController = segue.destination as? HDIPCAssetsViewController {
            assetsViewController.assetCollection = assetCollections[tableView.indexPathForSelectedRow!.row]
        } else if let selectedListViewController = segue.destination as? HDIPCSelectedListViewController {
            selectedListViewController.setValue(navigationController?.value(forKey: "selectedAssets"), forKey: "assets")
        }
    }
    
}
