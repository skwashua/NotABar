//
//  FindAResultViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 3/1/19.
//  Copyright © 2019 SoggyMop LLC. All rights reserved.
//

import UIKit
import MapKit

extension MKMapItem: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return placemark.coordinate
    }
    
    public var title: String? {
        return name
    }
}

extension FindAResultViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let mapItem = view.annotation as? MKMapItem else { return }
        
        let action = UIAlertAction(title: "Open in Maps", style: .default) { _ in
            self.openInMaps(mapItem: mapItem)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        
        let alertController = UIAlertController(title: nil, message: mapItem.name, preferredStyle: .actionSheet)
        alertController.addAction(action)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 1.0)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard onceToken == false else { return }
        onceToken = true
        let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: CLLocationDistance(3500), longitudinalMeters: CLLocationDistance(3500))
        mapView.setRegion(mapView.regionThatFits(region), animated: false)
        locationManager.stopUpdatingLocation()
        performSearch()
    }
}

class FindAResultViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var statusLabel: UILabel!
    
    var searchTerm: String = ""
    var locationManager = CLLocationManager()
    var localSearch: MKLocalSearch?
    var mapItems: Set<MKMapItem> = Set<MKMapItem>()
    var onceToken: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        title = "Finding \(searchTerm)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startLocationTracking()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @objc func performSearch() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(runSearch), object: nil)
        perform(#selector(runSearch), with: nil, afterDelay: 0.25)
    }
    
    @objc func runSearch() {
        localSearch?.cancel()
        
        statusLabel.text = "searching ..."
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm
        request.region = mapView.region
        
        localSearch = MKLocalSearch(request: request)
        localSearch?.start() { [weak self] (response, error) in
            guard let self = self, error == nil else { return }
            guard let mapItems = response?.mapItems, mapItems.count > 0 else {
                self.statusLabel.text = "no results found"
                return
            }
            self.mapItems = self.mapItems.union(mapItems)
            
            self.mapView.addAnnotations(self.mapItems.map({ $0 }))
            let visibleCount = self.mapView.annotations(in: self.mapView.visibleMapRect).count
            
            if visibleCount == 0 {
                self.mapView.showAnnotations(mapItems, animated: true)
                self.statusLabel.text = "showing results"
            } else {
                self.statusLabel.text = "showing results"
            }
        }
    }
    
    func openInMaps(mapItem: MKMapItem) {
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func startLocationTracking() {
        guard locationManager.authorizationStatus == .denied else {
            statusLabel.text = "Location not available, please allow in Settings."
            return
        }
        
        guard locationManager.authorizationStatus == .authorizedWhenInUse else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
}

extension FindAResultViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startLocationTracking()
    }
}
