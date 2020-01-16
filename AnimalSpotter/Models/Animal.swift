//
//  Animal.swift
//  AnimalSpotter
//
//  Created by Tobi Kuyoro on 16/01/2020.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

class Animal: Codable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let timeSeen: Date
    let description: String
    let imageURL: String
}
