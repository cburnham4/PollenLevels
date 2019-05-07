//
//  ViewController.swift
//  Pollen Index
//
//  Created by Carl Burnham on 5/5/19.
//  Copyright © 2019 Carl Burnham. All rights reserved.
//

import UIKit
import LhHelpers

class PollenViewModel {
    
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
                break
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
}

class ViewController: UIViewController {

    @IBOutlet weak var pollenLevel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var airQualityLabel: UILabel!
    
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
            }
        })
    }()
    
    
    var viewModel: PollenViewModel!
    
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
}

