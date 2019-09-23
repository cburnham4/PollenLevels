//
//  PollenRequest.swift
//  Pollen Index
//
//  Created by Carl Burnham on 5/5/19.
//  Copyright © 2019 Carl Burnham. All rights reserved.
//

import Foundation
import LhHelpers

struct PollenResponse: Codable {
    var forecast: [PollenDayResponse]
    
    init(forecast: [PollenDayResponse]) {
        self.forecast = forecast
    }
    
    var currentPollen: PollenDayResponse {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        
        for pollenDay in forecast {
            if let date = dateFormatter.date(from: pollenDay.date), Calendar.current.isDateInToday(date) {
                return pollenDay
            }
        }
        return PollenDayResponse(weather: "Unkown", pollen_count: .Moderate, date: "Today")
    }
}

struct PollenDayResponse: Codable {
    let weather: String?
    let pollen_count: PollenLevel
    let date: String
}

enum PollenLevel : String, Codable {
    case Low = "Low"
    case Moderate = "Moderate"
    case High = "High"
    case VeryHigh = "Very High"
}

struct PollenRequest: Request {
    
    let lat: Double
    let long: Double
    
    typealias ResultObject = PollenResponse
    
    // TODO Angel fix this as well. doh
    var endpoint: String {
        let latLong = String.init(format: "[%f,%f]", lat, long)
        return "https://socialpollencount.co.uk/api/forecast?location=\(latLong)"
    }
}
