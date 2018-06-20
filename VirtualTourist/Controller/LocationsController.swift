//
//  LocationsController.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/7/18.
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editInfo: UIView!
    
    var pins: [Pin] = [Pin]()
    
    // This is injected when app loads
    var dataController: DataController!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add long press gesture recognizer to add pin to map view
        configLongPressRecognizer()
        
        // Initialize Edit-Done button
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Retrieve pins from Core Data
        loadPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show previous map center coordinate
        getMapCoordinates()
        
        print(mapView.centerCoordinate)
    }
    
    func configLongPressRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPinOnLongPress))
        longPress.minimumPressDuration = 1 // seconds
        mapView.addGestureRecognizer(longPress)
    }
    
    @objc func addPinOnLongPress(_ recognizer: UIGestureRecognizer) {
        let location = recognizer.location(in: self.mapView)
        let locationCoordinate : CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: self.mapView)
        
        // Don't drop pins if user is dragging or lifting finger
        if recognizer.state == .began {
            // Persist pin to Core Data
            createPin(coordinate: locationCoordinate)
            // Add pin as point annotation on map
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = locationCoordinate
            mapView.addAnnotation(pointAnnotation)
        }
    }
    
    func createPin(coordinate: CLLocationCoordinate2D){
        let pin = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, context: dataController.viewContext)
        pins.append(pin)
    }
    
    func loadPins() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        request.returnsObjectsAsFaults = false
        do {
            let pins = try dataController.viewContext.fetch(request)
            for pin in pins as! [NSManagedObject] {
                print(pin.value(forKey: "longitude") as! Double)
            }
        } catch {
            print("Unable to retrieve pins from Core Data")
        }
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
    
    // Save map coordinates to UserDefaults on segue
    func saveMapCoordinates(coordinates: [CLLocationDegrees]) {
        UserDefaults.standard.set(coordinates, forKey: "centerCoordinate")
    }
    
    // Get map coordinates from UserDefaults
    func getMapCoordinates() {
        if let coordinates = UserDefaults.standard.value(forKey: "centerCoordinate") as? [CLLocationDegrees] {
            mapView.centerCoordinate.latitude = coordinates[0]
            mapView.centerCoordinate.longitude = coordinates[1]
        }
    }
}

// MARK: - MKMapViewDelegate

extension LocationsController: MKMapViewDelegate {
    
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
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Save map coordinates
        var coordinates = [CLLocationDegrees]()
        coordinates.append(mapView.centerCoordinate.latitude)
        coordinates.append(mapView.centerCoordinate.longitude)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.coordinates = coordinates
        saveMapCoordinates(coordinates: coordinates)
    }
}
