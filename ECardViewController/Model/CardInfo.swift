//
//  CardInfo.swift
//  PlasticCardView
//
//  Created by Алексей Милахин on 19.09.17.
//  Copyright © 2017 Alexey Milakhin. All rights reserved.
//

import Foundation

public struct Expires {
    /// MM format
    public var month: String?
    
    /// YY format
    public var year: String?
}

open class CardInfo: NSObject {
    static let current = CardInfo()
    
    open var cardNumber: String?
    open var cardHolder: String?
    internal var expiresStr: String?
    open var cvvCode: String?
    open var expires: Expires?
    
    internal func getIssuer() -> Bank? {
        guard let cardNumber = cardNumber, cardNumber.count >= 6 else { return nil }
        let preffix = String(cardNumber.replacingOccurrences(of: " ", with: "").prefix(6))
        let bundle = Bundle(for: type(of: self))
        if let path = bundle.url(forResource: "Banks", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: path)
                let json = try JSONDecoder().decode(Banks.self, from: jsonData)
                guard let prefixes = json.prefixes, let banks = json.banks, let bankIdentifer = prefixes[preffix] else { return nil }
                let bank = banks[bankIdentifer]
                return bank
            } catch let error {
                print(error)
                return nil
            }
        }
        return nil
    }
    
    internal func getBrand() -> Brand? {
        guard let cardNumber = cardNumber, cardNumber.count >= 1 else { return nil }
        let bundle = Bundle(for: type(of: self))
        if let path = bundle.url(forResource: "Brands", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: path)
                let brands = try JSONDecoder().decode([Brand].self, from: jsonData)
                for brand in brands {
                    let regex = NSPredicate(format: "SELF MATCHES %@", brand.pattern)
                    if regex.evaluate(with: cardNumber.replacingOccurrences(of: " ", with: "")) {
                        return brand
                    }
                }
                return nil
            } catch let error {
                print(error)
                return nil
            }
        }
        return nil
    }
}
