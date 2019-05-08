//
//  ViewController.swift
//  Pollen Index
//
//  Created by Carl Burnham on 5/5/19.
//  Copyright © 2019 Carl Burnham. All rights reserved.
//

import UIKit
import LhHelpers
import CoreLocation
import LocationPicker

class PollenViewModel: CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager();
    var latitude = 70.0;
    var longitude = 70.0;
    var placemark: CLPlacemark?
    
    var pollenLevel: Observable<PollenDayResponse?>
    var airQuality: Observable<AirQualityData?>
    
    init() {
        pollenLevel = Observable(nil)
        airQuality = Observable(nil)
    }
    
    func getPollenLevel() {
        let pollenRequest = PollenRequest(lat: 30.0, long: 30.0)
        pollenRequest.makeRequest(result: { [weak self] reponse in
            switch reponse {
            case .success(let pollenResponse):
                self?.pollenLevel.value = pollenResponse.currentPollen
            case .failure(let _):
                self?.pollenLevel.value = nil
            }
        })}
    
    func getAirQuality() {
        let request = AirQualityRequest(lat: 38.8, long: -77.0)
        request.makeRequest(result: { [weak self] response in
            switch response {
            case .success(let data):
                self?.airQuality.value = data
                break
            case .failure(let _):
                break
            }
        })}
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        /* Stop getting user location once the first location is recieved */
        self.locationManager.stopUpdatingLocation();
        
        /* get the longitude and latitude of the user */
        let locationlast = locations.last
        self.latitude = (locationlast?.coordinate.latitude)!
        self.longitude = (locationlast?.coordinate.longitude)!
        
        /* Get the address from the long and lat */
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error)->Void in
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                self.placemark = pm
                self.displayLocationInfo(pm)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
        
        createRequest();
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var pollenLevel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var airQualityLabel: UILabel!
    @IBOutlet weak var changeLocationButton: UIButton!
    
    var viewModel: PollenViewModel! 
    
    lazy var pollenLevelBind = {
        return Bond<PollenDayResponse?>(valueChanged: { [weak self] value in
            if let value = value {
                self?.loadPollenLevel(pollenResponse: value)
            } else if let strongSelf = self {
                AlertUtils.createAlert(view: strongSelf, title: "Error Retrieving Pollen Values", message: "")
            }
        })
    }()
    
    lazy var airQualityBind = {
        return Bond<AirQualityData?>(valueChanged: { [weak self] value in
            if let value = value {
                self?.airQualityLabel.text = value.level
            } else if let strongSelf = self {
                AlertUtils.createAlert(view: strongSelf, title: "Error Retrieving Air Quality Values", message: "")
            }
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if viewModel == nil {
            viewModel = PollenViewModel()
        }
        viewModel.getPollenLevel()
        viewModel.getAirQuality()
        
        pollenLevelBind.bind(observable: viewModel.pollenLevel)
        airQualityBind.bind(observable: viewModel.airQuality)
    }
    
    func loadPollenLevel(pollenResponse: PollenDayResponse) {
        switch pollenResponse.pollen_count {
        case .Low:
            pollenLevel.text = PollenLevel.Low.rawValue
            view.backgroundColor = .red
        case .Medium:
            pollenLevel.text = PollenLevel.Medium.rawValue
            view.backgroundColor = .orange
        case .High:
            pollenLevel.text = PollenLevel.High.rawValue
            view.backgroundColor = .green
        }
        weatherLabel.text = pollenResponse.weather
    }
    
    @IBAction func changeLocation(_ sender: Any) {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                
                AlertUtils.createAlert(view: self, title: "Location Permission Disabled", message: "Please Enable Location Services for this App")
            case .authorizedAlways, .authorizedWhenInUse:
                openLocationPicker()
            }
        } else {
            AlertUtils.createAlert(view: self, title: "Location Disabled", message: "Please Enable Location Services")
        }
    }
    
    func openLocationPicker(){
        let locationPicker = LocationPickerViewController()
        
        // you can optionally set initial location
        let location = CLLocation(latitude: self.latitude, longitude: self.longitude)
        if(placemark == nil) {
            //location.placemark
        }
        
        let initialLocation = Location(name: "Current Location", location: location, placemark: self.placemark!)
        
        
        locationPicker.location = initialLocation
        
        
        // button placed on right bottom corner
        locationPicker.showCurrentLocationButton = true // default: true
        
        // default: navigation bar's `barTintColor` or `.whiteColor()`
        locationPicker.currentLocationButtonBackground = .blue
        
        // ignored if initial location is given, shows that location instead
        locationPicker.showCurrentLocationInitially = true // default: true
        
        locationPicker.mapType = .standard // default: .Hybrid
        
        // for searching, see `MKLocalSearchRequest`'s `region` property
        locationPicker.useCurrentLocationAsHint = true // default: false
        
        locationPicker.searchBarPlaceholder = "Search places" // default: "Search or enter an address"
        
        locationPicker.searchHistoryLabel = "Previously searched" // default: "Search History"
        
        // optional region distance to be used for creation region when user selects place from search results
        locationPicker.resultRegionDistance = 500 // default: 600
        
        locationPicker.completion = { location in
            // do some awesome stuff with location
            print(location?.placemark)
            self.placemark = location?.placemark
            self.displayLocationInfo(self.placemark)
            self.createRequest()
        }
        
        navigationController?.pushViewController(locationPicker, animated: true)
    }
}
