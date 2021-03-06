//
//  ViewController.swift
//  locationPOC
//
//  Created by Jonathon Day on 2/7/17.
//  Copyright © 2017 dayj. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKLocalSearchCompleterDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var resultsView: UITextView!
    @IBOutlet var textField: UITextField!
    
    @IBAction func locationTapped(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinates = locations.first!.coordinate
        makeRequestWithCoordinate(coordinates) { (name) in
            DispatchQueue.main.async {
                self.resultsView.text = name
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let region = MKCoordinateRegion(center: coordinates, span: span)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinates
                self.mapView.addAnnotation(annotation)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    

    @IBAction func suggestTapped(_ sender: UIButton) {
        let request = MKLocalSearchCompleter()
        request.delegate = self
        request.queryFragment = textField.text!
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        resultsView.text = completer.results.reduce("", { (accum, completer) -> String in
            return accum + "\(completer.title) \n"
        })
    }
    
    @IBAction func searchTapped(_ sender: UIButton) {
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = textField.text
        
        let search = MKLocalSearch(request: request)
        search.start { (_response, _error) in
            if let response  = _response {
                let firstResult = response.mapItems.first!
                let coordinates = firstResult.placemark.location!.coordinate
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinates
                self.mapView.addAnnotation(annotation)
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let region = MKCoordinateRegion(center: coordinates, span: span)
                self.mapView.setRegion(region, animated: true)
                
                self.makeRequestWithCoordinate(coordinates, completion: { (name) in
                    DispatchQueue.main.async {
                        self.resultsView.text = name
                    }
                })
                
            }
            
            if let error = _error {
                self.resultsView.text = "local search error: \(error.localizedDescription)"
            }
        }
    }
    
    func makeRequestWithCoordinate(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let lat = coordinate.latitude
        let long = coordinate.longitude
        let url = URL(string: "https://openstates.org/api/v1/legislators/geo/?lat=\(lat)&long=\(long)")
        
        let session = URLSession.shared
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session.dataTask(with: request) { (_data, _response, _error) in
            if let data = _data {
                let array = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
                let names = array.reduce("", { (accum, dict) -> String in
                    return accum + (dict["full_name"] as! String) + "\n"
                })
                completion(names)
            }
            if let response = _response {
                print(response.debugDescription)
            }
            if let error = _error {
                print(error.localizedDescription)
            }
        }.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
    }
}

