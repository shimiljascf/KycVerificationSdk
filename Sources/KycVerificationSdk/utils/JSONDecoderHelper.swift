//
//  JSONDecoderHelper.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 03/07/24.
//

import Foundation

func decodeJSON<T: Decodable>(from jsonData: Data, as type: T.Type) -> T? {
    do {
        let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
        return decodedObject
    } catch {
        print("Failed to decode JSON: \(error)")
        return nil
    }
}
