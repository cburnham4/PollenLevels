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
import GoogleMobileAds

class PollenViewModel: NSObject, CLLocationManagerDelegate {

    var locationManager = CLLocationManager();
    var latitude = 70.0;
    var longitude = 70.0;
    var locationText = Observable("Location: Unknown")
    var placemark: CLPlacemark? {
        didSet {
            if let containsPlacemark = placemark {
                //stop updating location to save battery life
                locationManager.stopUpdatingLocation()
                let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
                let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
                let administrativeArea = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
                
                let cordinates = containsPlacemark.location?.coordinate
                self.latitude = (cordinates?.latitude)!
                self.longitude = (cordinates?.longitude)!
                
                let address = locality! + ", " + administrativeArea! + " " + postalCode!;
                locationText.value = "Location: \(address)"
            }
        }
    }
    
    var pollenLevel: Observable<PollenDayResponse?>
    var airQuality: Observable<AirQualityData?>
    
    override init() {
        pollenLevel = Observable(nil)
        airQuality = Observable(nil)
    }
    
    func startLocationTracking() {
        /* Get the location of the user */
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    var location: CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
    
    func makeRequests() {
        getPollenLevel()
        getAirQuality()
    }
    
    func getPollenLevel() {
        let pollenRequest = PollenRequest(lat: latitude, long: longitude)
        pollenRequest.makeRequest(result: { [weak self] reponse in
            switch reponse {
            case .success(let pollenResponse):
                self?.pollenLevel.value = pollenResponse.currentPollen
            case .failure(let _):
                self?.pollenLevel.value = nil
            }
        })
    }
    
    func getAirQuality() {
        let request = AirQualityRequest(lat: latitude, long: longitude)
        request.makeRequest(result: { [weak self] response in
            switch response {
            case .success(let data):
                self?.airQuality.value = data
                break
            case .failure(let _):
                break
            }
        })
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        /* Stop getting user location once the first location is recieved */
        self.locationManager.stopUpdatingLocation()
        
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
                // self.displayLocationInfo(pm)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
        
        makeRequests()
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var pollenLevel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var airQualityLabel: UILabel!
    @IBOutlet weak var changeLocationButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var bannerView: GADBannerView!
    
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
    
    lazy var locationTextBind = {
        return Bond<String>(valueChanged: { [weak self] value in
            guard let strongSelf = self else { return }
            strongSelf.locationLabel.text = value
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if viewModel == nil {
            viewModel = PollenViewModel()
        }
        viewModel.startLocationTracking()
        
        locationLabel.text = viewModel.locationText.value
        
        locationTextBind.bind(observable: viewModel.locationText)
        pollenLevelBind.bind(observable: viewModel.pollenLevel)
        airQualityBind.bind(observable: viewModel.airQuality)
        
        bannerView.adUnitID = "ca-app-pub-8223005482588566/5223451763"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
    func loadPollenLevel(pollenResponse: PollenDayResponse) {
        switch pollenResponse.pollen_count {
        case .Low:
            pollenLevel.text = PollenLevel.Low.rawValue
            view.backgroundColor = .red
        case .Moderate:
            pollenLevel.text = PollenLevel.Moderate.rawValue
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
//        if(placemark == nil) {
//            //location.placemark
//        }
        
        let initialLocation = Location(name: "Current Location", location: viewModel.location, placemark: viewModel.placemark)
        
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
        
        locationPicker.completion = { [weak self] location in
            // do some awesome stuff with location
            print(location?.placemark)
            self?.viewModel.placemark = location?.placemark
            self?.viewModel.makeRequests()
        }
        
        navigationController?.pushViewController(locationPicker, animated: true)
    }
}
