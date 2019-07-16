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

    var locationManager = CLLocationManager()
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
        locationManager.distanceFilter = 10.0
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
            case .failure( _):
                self?.pollenLevel.value = nil
            }
        })
    }
    
    func getAirQuality() {
        let request = AirQualityRequest(lat: latitude, long: longitude)
        request.makeRequest(result: { [weak self] response in
            switch response {
            case .success(let result):
                self?.airQuality.value = result.data
            case .failure( _):
                self?.airQuality.value = nil
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
                self?.loadAirQuality(airQuality: value)
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
    
    func loadAirQuality(airQuality: AirQualityData) {
        switch airQuality.aqi {
        case 0...50:
            airQualityLabel.text = airQuality.level
            airQualityLabel.textColor = .green
        case 51...100:
            airQualityLabel.text = airQuality.level
            airQualityLabel.textColor = UIColor(red: 204, green: 204, blue: 0)
        case 101...150:
            airQualityLabel.text = airQuality.level
            airQualityLabel.textColor = .orange
        case 151...200:
            airQualityLabel.text = airQuality.level
            airQualityLabel.textColor = .red
        case 201...300:
            airQualityLabel.text = airQuality.level
            airQualityLabel.textColor = .purple
        default:
            airQualityLabel.text = airQuality.level
            airQualityLabel.textColor = UIColor(red: 128, green: 0, blue: 0)
        }
    }
    
    func loadPollenLevel(pollenResponse: PollenDayResponse) {
        switch pollenResponse.pollen_count {
        case .Low:
            pollenLevel.text = PollenLevel.Low.rawValue
            pollenLevel.textColor = .green
        case .Moderate:
            pollenLevel.text = PollenLevel.Moderate.rawValue
            pollenLevel.textColor = .orange
        case .High:
            pollenLevel.text = PollenLevel.High.rawValue
            pollenLevel.textColor  = .red
        case .VeryHigh:
            pollenLevel.text = PollenLevel.VeryHigh.rawValue
            pollenLevel.textColor = .red
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
            @unknown default:
                // TODO: Angel add an alert here saying there was an error
                break; // TODO: remove this break
            }
        } else {
            AlertUtils.createAlert(view: self, title: "Location Disabled", message: "Please Enable Location Services")
        }
    }
    
    func openLocationPicker(){
        let locationPicker = LocationPickerViewController()

        let initialLocation = Location(name: "Current Location", location: viewModel.location, placemark: viewModel.placemark)
        
        locationPicker.location = initialLocation
        
        locationPicker.showCurrentLocationButton = true
        locationPicker.currentLocationButtonBackground = .blue
        locationPicker.showCurrentLocationInitially = true
        
        locationPicker.mapType = .standard // default: .Hybrid
        
        // for searching, see `MKLocalSearchRequest`'s `region` property
        locationPicker.useCurrentLocationAsHint = true // default: false
        
        locationPicker.searchBarPlaceholder = "Search places" // default: "Search or enter an address"
        
        locationPicker.searchHistoryLabel = "Previously searched" // default: "Search History"
        
        // optional region distance to be used for creation region when user selects place from search results
        locationPicker.resultRegionDistance = 500 // default: 600
        
        locationPicker.completion = { [weak self] location in
            self?.viewModel.placemark = location?.placemark
            self?.viewModel.makeRequests()
        }
        
        navigationController?.pushViewController(locationPicker, animated: true)
    }
}
