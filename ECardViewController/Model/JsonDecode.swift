//
//  JsonDecode.swift
//  PlasticCardView
//
//  Created by Алексей Милахин on 19.09.17.
//  Copyright © 2017 Alexey Milakhin. All rights reserved.
//

import Foundation

struct Banks: Decodable {
    var banks: [String: Bank]?
    var prefixes: [String: String]?
}

struct Bank: Decodable {
    var name: String
    var nameEn: String
    var url: URL
    var backgroundColor: String
    var backgroundColors: [String]
    var text: String
    var logoStyle: String
    var logoPng: String
}

struct Brand: Decodable {
    
    var alias: String
    var name: String
    var codeName: String
    var codeLength: Int
    var gaps: [Int]
    var lengths: [Int]
    var pattern: String
    var image: String
}
