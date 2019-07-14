//
//  AirQualityRequest.swift
//  Pollen Index
//
//  Created by Carl Burnham on 5/6/19.
//  Copyright © 2019 Carl Burnham. All rights reserved.
//

import Foundation

struct AirQualityResponse: Codable {
    let data: AirQualityData
}

struct AirQualityData: Codable {
    let aqi: Int
    
    var level: String {
        // TODO: Angel, complete this switch statement. This is a computer property: https://docs.swift.org/swift-book/LanguageGuide/Properties.html
        switch aqi {
        case 0...50:
            return "Good (\(aqi))"
        case 51...100:
            return "Moderate (\(aqi))"
        case 101...150:
            return "Unhealthy for Sensitive Groups (\(aqi))"
        case 151...200:
            return "Unhealthy (\(aqi))"
        case 201...300:
            return "Very Unhealthy (\(aqi))"
        default:
            return ""
        }
//        0 to 50    Good    Green
//        51 to 100    Moderate    Yellow
//        101 to 150    Unhealthy for Sensitive Groups    Orange
//        151 to 200    Unhealthy    Red
//        201 to 300    Very Unhealthy    Purple
//        301 to 500
    }
}

struct AirQualityRequest: Request {

    typealias ResultObject = AirQualityResponse
    
    let apiKey = "4f344d127c41eb841e83d533d2c4a336ce5c3cec"
    
    let lat: Double
    let long: Double
    
    var endpoint: String {
        let latLong = String.init(format: "%f;%f", lat, long)
        return "https://api.waqi.info/feed/geo:\(latLong)/?token=\(apiKey)"
    }
}
