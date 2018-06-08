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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add long press gesture recognizer to add pin to map view
        configLongPressRecognizer()
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
        if recognizer.state == .changed || recognizer.state == .ended { return }
        
        addPinToMap(newPin)
    }
    
    func addPinToMap(_ pin: MKPointAnnotation) {
        // Check if same pin already exists on map
        let isPinOnMap = checkIfPinExists(pin)
        if isPinOnMap { return }
        mapView.addAnnotation(pin)
    }
    
    func checkIfPinExists(_ pin: MKPointAnnotation) -> Bool {
        let isPinOnMap = self.mapView.annotations.contains { existingPin in
            if existingPin.coordinate.latitude == pin.coordinate.latitude && existingPin.coordinate.longitude == pin.coordinate.longitude {
                return true
            } else {
                return false
            }
        }
        return isPinOnMap
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
        print("Hi!")
    }
}
