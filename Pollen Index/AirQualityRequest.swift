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
        var text: String
        switch aqi {
        case 0...50:
            return "Good (\(aqi))"
        default:
            return "Moderate (\(aqi))"
        }
//        0 to 50    Good    Green
//        51 to 100    Moderate    Yellow
//        101 to 150    Unhealthy for Sensitive Groups    Orange
//        151 to 200    Unhealthy    Red
//        201 to 300    Very Unhealthy    Purple
//        301 to 500
    }
}

struct AirQualityRequest {
    
    let apiKey = "4f344d127c41eb841e83d533d2c4a336ce5c3cec"
    
    let lat: Double
    let long: Double
    
    func makeRequest(result: @escaping (Response<AirQualityData>) -> ()) {
        let latLong = String.init(format: "%f;%f", lat, long)
        let urlString = "https://api.waqi.info/feed/geo:\(latLong)/?token=\(apiKey)"

        guard let url = URL(string: urlString) else {
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
            let airQualityResponse = try! decoder.decode(AirQualityResponse.self, from: responseData)
            DispatchQueue.main.async {
                result(.success(airQualityResponse.data))
            }
        })
        task.resume()
    }
}
