//
//  PollenRequest.swift
//  Pollen Index
//
//  Created by Carl Burnham on 5/5/19.
//  Copyright © 2019 Carl Burnham. All rights reserved.
//

import Foundation

enum Response<T> {
    case success(T)
    case failure(error: String)
}

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
        return forecast[0]
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
}

struct PollenRequest {

    let lat: Double
    let long: Double
    
    func makeRequest(result: @escaping (Response<PollenResponse>) -> ()) {
        let latLong = String.init(format: "[%f,%f]", lat, long)
        let pollenEndpoint: String = "https://socialpollencount.co.uk/api/forecast?location=\(latLong)"
        print(pollenEndpoint)
        guard let url = URL(string: pollenEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            guard error == nil else {
                result(.failure(error: error!.localizedDescription))
                return
            }
            guard let responseData = data else {
                result(.failure(error: "Error: did not receive data"))
                return
            }
            
            let decoder = JSONDecoder()
            let pollenResponse = try! decoder.decode(PollenResponse.self, from: responseData)
            DispatchQueue.main.async {
                result(.success(pollenResponse))
            }
            
        })
        task.resume()
    }
}
