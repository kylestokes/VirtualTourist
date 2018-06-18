//
//  LocationsController.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/7/18.
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import UIKit
import MapKit

class LocationsController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editInfo: UIView!
    
    // This is injected when app loads
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add long press gesture recognizer to add pin to map view
        configLongPressRecognizer()
        
        // Initialize Edit-Done button
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func configLongPressRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPinOnLongPress))
        longPress.minimumPressDuration = 1 // seconds
        mapView.addGestureRecognizer(longPress)
    }
    
    @objc func addPinOnLongPress(_ recognizer: UIGestureRecognizer) {
        let location = recognizer.location(in: self.mapView)
        let locationCoordinate : CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: self.mapView)
        
        let newPin = MKPointAnnotation()
        newPin.coordinate = locationCoordinate
        
        // Don't drop pins if user is dragging or lifting finger
        if recognizer.state == .began { mapView.addAnnotation(newPin) }
    }
    
    // Edit-Done actions
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            editInfo.isHidden = false
            mapView.frame.origin.y = -70
        } else {
            editInfo.isHidden = true
            mapView.frame.origin.y = 0
        }
    }

    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        // Delete pin if editing
        if isEditing {
            mapView.removeAnnotation(view.annotation!)
            return
        }
        
        let photoAlbumViewController = self.storyboard?.instantiateViewController(withIdentifier: "photoAlbum") as! PhotoAlbumController
        // Send pin to photoAlbumViewController
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = (view.annotation?.coordinate.latitude)!
        pin.longitude = (view.annotation?.coordinate.longitude)!
        photoAlbumViewController.pin = pin
        // Dependency injection
        photoAlbumViewController.dataController = dataController
        // Segue to photo album
        self.navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }
}
