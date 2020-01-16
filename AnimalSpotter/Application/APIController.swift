//
//  APIController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 4/16/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum NetworkError: Error {
    case badData
    case noDecode
    case noBearer
    case serverError(Error)
    case unexpectedStatusCode
    case otherError
}

enum HeaderNames: String {
    case authorization = "Authorization"
    case contentType = "Content-Type"
}

class APIController {
    
    private let baseUrl = URL(string: "https://lambdaanimalspotter.vapor.cloud/api")!
    var bearer: Bearer?
    
    // The Result enum is going to have an [String] for its success and a NetworkingError for its failure.
    typealias AnimalNamesCompletionHandler = (Result<[String], NetworkError>) -> Void
    typealias AnimalDetailCompletionHandler = (Result<Animal, NetworkError>) -> Void
    typealias AnimailImageCompletionHandler = (Result<UIImage, NetworkError>) -> Void
    
    func signUp(with user: User, completion: @escaping (Error?) -> Void) {
        
        // Build the URL
        let requestURL = baseUrl
            .appendingPathComponent("users")
            .appendingPathComponent("signup")
        
        // Build the request
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.post.rawValue
        // Tell the API that the body is in JSON format
        request.setValue("application/json", forHTTPHeaderField: HeaderNames.contentType.rawValue)
        
        let encoder = JSONEncoder()
        do {
            let userJSON = try encoder.encode(user)
            request.httpBody = userJSON
        } catch {
            NSLog("Error encoding user object: \(error)")
            completion(error)
            return
        }
        
        // Perform the request (data task)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Handle errors
            if let error = error {
                NSLog("Error signing user: \(error)")
                completion(error)
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                let statusCode = NSError(domain: "", code: response.statusCode, userInfo: nil)
                completion(statusCode)
            }
            
            completion(nil) // nil means there was no error. Everything succeeded.
        }.resume()
        
        // Decoded the data (optionally)
        
    }

    func signIn(with user: User, completion: @escaping (Error?) -> Void) {
        let requestURL = baseUrl
            .appendingPathComponent("users")
            .appendingPathComponent("login")
        
        var request = URLRequest(url: requestURL)
        request.setValue("application/json", forHTTPHeaderField: HeaderNames.contentType.rawValue)
        request.httpMethod = HTTPMethod.post.rawValue
        
        do {
            request.httpBody = try JSONEncoder().encode(user)
        } catch {
            NSLog("Error encoding user for sign in: \(error)")
            completion(error)
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                NSLog("Error signing in user: \(error)")
                completion(error)
                return
            }
            
            if let response = response as? HTTPURLResponse ,
                response.statusCode != 200 {
                let statusCodeError = NSError(domain: "", code: response.statusCode, userInfo: nil)
                completion(statusCodeError)
            }
            
            guard let data = data else {
                NSLog("no data returned from data task")
                let noDataError = NSError(domain: "", code: -1, userInfo: nil)
                completion(noDataError)
                return
            }
            
            do {
                let bearer = try JSONDecoder().decode(Bearer.self, from: data)
                self.bearer = bearer
            } catch {
                NSLog("Error decoding the bearer token: \(error)")
                completion(error)
            }
            
            completion(nil)
        }.resume()
    }
    
    func fetchAllAnimalNames(completion: @escaping AnimalNamesCompletionHandler) {
        guard let bearer = bearer else {
            completion(.failure(.noBearer))
            return
        }
        
        let allAnimalsURL = baseUrl
            .appendingPathComponent("animals")
            .appendingPathComponent("all")
        
        var request = URLRequest(url: allAnimalsURL)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: HeaderNames.authorization.rawValue)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                NSLog("Error fetching animal names: \(error)")
                completion(.failure(.serverError(error)))
                return
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                completion(.failure(.unexpectedStatusCode))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let animalNames = try decoder.decode([String].self, from: data)
                completion(.success(animalNames))
            } catch {
                NSLog("Error decoding animal names: \(error)")
                completion(.failure(.noDecode))
            }
        }.resume()
    }
    
    func fetchDetails(for animalName: String, completion: @escaping AnimalDetailCompletionHandler) {
        guard let bearer = bearer else {
            completion(.failure(.noBearer))
            return
        }
        
        let animalURL = baseUrl
            .appendingPathComponent("animals")
            .appendingPathComponent("\(animalName)")
        
        var request = URLRequest(url: animalURL)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: HeaderNames.authorization.rawValue)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                NSLog("Error fetching animal names: \(error)")
                completion(.failure(.serverError(error)))
                return
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                completion(.failure(.unexpectedStatusCode))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                let animal = try decoder.decode(Animal.self, from: data)
                completion(.success(animal))
            } catch {
                NSLog("Error decoding animal names: \(error)")
                completion(.failure(.noDecode))
            }
        }.resume()
    }
    
    func fetchImage(at urlString: String, completion: @escaping AnimailImageCompletionHandler) {
        let imageURL = URL(string: urlString)!
        let request = URLRequest(url: imageURL)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let _ = error {
                completion(.failure(.otherError))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let image = UIImage(data: data)!
            completion(.success(image))
        }.resume()
    }
}
