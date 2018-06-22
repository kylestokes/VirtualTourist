//
//  PhotoAlbumController.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/7/18.
//  with attribution to nsutanto
//  https://github.com/nsutanto/ios-VirtualTourist/blob/master/VirtualTourist/ViewController/PictureViewController.swift
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    
    @IBAction func collectionButtonPressed(_ sender: UIBarButtonItem) {
        // Remove all photos
        if sender.title == Constants.BarButtonTitles.NewCollection {
            collectionButton.isEnabled = false
            for photo in fetchedResultsController.fetchedObjects! {
                dataController.viewContext.delete(photo)
            }
            dataController.save()
            // Update current page number of photo results from Flickr
            if currentPageNumber < numberOfPagesForPin {
                currentPageNumber += 1
            } else {
                currentPageNumber = numberOfPagesForPin
            }
            
            collectionView.isHidden = false
            
            // Get all new photos
            retrievePhotosFromFlickr(forPage: currentPageNumber)
            
        } else {
        // Remove only selected photos
            for photoIndex in selectedPhotoIndexes {
                let photo = fetchedResultsController.object(at: photoIndex)
                dataController.viewContext.delete(photo)
            }
            dataController.save()
            // Reset selected indexes
            selectedPhotoIndexes.removeAll()
            collectionButton.title = Constants.BarButtonTitles.NewCollection
        }
    }
    
    
    var pin: Pin!
    var photos: [Photo] = [Photo]()
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    // Indexes for photos for fetchedResultsController
    var photoIndexesToInsert = [IndexPath]()
    var photoIndexesToDelete = [IndexPath]()
    var photoIndexesToUpdate = [IndexPath]()
    var selectedPhotoIndexes = [IndexPath]()
    // Determines if collectionButton is enabled
    var numberOfDownloadedImages: Int = 0
    // Total number of pages returned by Flickr call for pin
    var numberOfPagesForPin: Int = 0
    var currentPageNumber: Int = 1
    
    fileprivate func configFetchResultsController() {
        let fetchRquest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRquest.predicate = predicate
        fetchRquest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRquest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Unable to fetch photos: \(error.localizedDescription)")
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update UI
        collectionButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configFetchResultsController()
        configMapForSelectedPin()
        configPhotos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    // Determine if any photos are saved in Core Data
    func configPhotos() {
        if (fetchedResultsController.fetchedObjects?.count == 0) {
            retrievePhotosFromFlickr(forPage: currentPageNumber)
        }
    }
    
    // Get all photo URLs for pin
    func retrievePhotosFromFlickr(forPage: Int) {
        FlickrClient.sharedInstance().getPhotoURLsForLocation(pin.latitude, pin.longitude, forPage, completionHandlerPhotos: { (result, numberOfPages, error) in
            
            if (error == nil) {
                // No URLs returned from location; hide collection to show 'No photos' label
                if (result?.count == 0) {
                    DispatchQueue.main.async {
                        self.collectionView.isHidden = true
                    }
                }
                
                self.dataController?.viewContext.perform {
                    for photoURL in result! {
                        let photo = Photo(photoURL: photoURL, photoData: nil, context: self.dataController.viewContext)
                        self.pin.addToPhotos(photo)
                    }
                }
                self.numberOfPagesForPin = numberOfPages!
            }
            else {
                self.displayAlert("There seems to be an issue getting photos from Flickr — try again in a couple seconds!")
            }
        })
    }
    
    func configMapForSelectedPin() {
        // Center map
        let center = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
        // Add pin
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        self.mapView.addAnnotation(annotation)
    }
    
    func displayAlert(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "🤨", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - MKMapViewDelegate

extension PhotoAlbumController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        return pinView
    }
}

// MARK: UICollectionViewDataSource

extension PhotoAlbumController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        DispatchQueue.main.async {
            cell.imageView.image = nil
            cell.backgroundColor = UIColor.lightGray
            cell.activityIndicator.hidesWhenStopped = true
            cell.activityIndicator.startAnimating()
        }
        
        // Retrieve photo from fetchedResultsController
        let photo = fetchedResultsController.object(at: indexPath)
        
        // Update UI if photo has image data, else download image data
        if let photoImageData = photo.image {
            
            DispatchQueue.main.async {
                cell.imageView.image = UIImage(data: photoImageData as Data)
                cell.activityIndicator.stopAnimating()
                
                if (self.numberOfDownloadedImages > 0) {
                    self.numberOfDownloadedImages = self.numberOfDownloadedImages - 1
                }
                if self.numberOfDownloadedImages == 0 {
                    self.collectionButton.isEnabled = true
                }
                
            }
        }
        else {
            // Download image data
            // This will be called if no image data exists for photo
            // Then, a new cell will be added to the collectionView and 'cellForItemAt' will be called again to set photo for cell
            self.numberOfDownloadedImages = self.numberOfDownloadedImages + 1
            let task = FlickrClient.sharedInstance().convertURLToPhotoData(photoURL: photo.imageURL!, completionHandler: { (photoData, error) in
                
                if (error == nil) {
                    DispatchQueue.main.async {
                        cell.activityIndicator.stopAnimating()
                        if (self.numberOfDownloadedImages > 0) {
                            self.collectionButton.isEnabled = false
                        }
                    }
                    
                    self.dataController?.viewContext.perform {
                        photo.image = photoData as NSData?
                    }
                } else {
                    print("Could not download photoData for cell!")
                }
            })
            
            // Cancel converting url to photo data if cell is already used in collection view
            cell.taskToCancelIfCellIsReused = task
        }
        
        return cell
    }
}

// MARK: UICollectionViewDelegate

extension PhotoAlbumController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath as IndexPath)
        if (!selectedPhotoIndexes.contains(indexPath)) {
            selectedPhotoIndexes.append(indexPath)
            cell?.alpha = 0.5
        } else {
            let index = selectedPhotoIndexes.index(of: indexPath)
            selectedPhotoIndexes.remove(at: index!)
            cell?.alpha = 1
        }
        
        let collectionButtonTitle = selectedPhotoIndexes.count == 0 ? Constants.BarButtonTitles.NewCollection : Constants.BarButtonTitles.RemoveSelectedPhotos
        collectionButton.title = collectionButtonTitle
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
//         https://stackoverflow.com/a/45995121

extension PhotoAlbumController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - (5 * 3)) / 3.0
        let height = width
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
        
    }
}

// MARK: NSFetchedResultsControllerDelegate

extension PhotoAlbumController: NSFetchedResultsControllerDelegate {
    
    // Called when fetchedResultsController objects are about to change
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // We want to reset the index path arrays
        photoIndexesToInsert.removeAll()
        photoIndexesToDelete.removeAll()
        photoIndexesToUpdate.removeAll()
    }
    
    // Called when change has occurred in fetchedResultsController object(s)
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            photoIndexesToInsert.append(newIndexPath!)
        case .delete:
            photoIndexesToDelete.append(indexPath!)
        case .update:
            photoIndexesToUpdate.append(indexPath!)
        default:
            break
        }
    }
    
    // Called when the fetchedResultsController has completed changes
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates( {
            self.collectionView.insertItems(at: photoIndexesToInsert)
            self.collectionView.deleteItems(at: photoIndexesToDelete)
            self.collectionView.reloadItems(at: photoIndexesToUpdate)
        }, completion: nil)
    }
}
