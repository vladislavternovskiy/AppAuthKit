//
//  Response.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

func json(_ data: Data?) -> Any? {
    guard let data = data else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [])
}

func string(_ data: Data?) -> String? {
    guard let data = data else { return nil }
    return String(data: data, encoding: .utf8)
}

public struct FusionResponse<E: FusionAuthAPIError> {
    let data: Data?
    let response: HTTPURLResponse?
    let error: Error?

    func result() throws -> Any? {
        guard error == nil else { throw E(cause: error!, statusCode: response?.statusCode ?? 0) }
        guard let response = self.response else { throw E(description: nil) }
        guard (200...300).contains(response.statusCode) else {
            if let json = json(data) as? [String: Any] {
                throw E(info: json, statusCode: response.statusCode)
            }
            throw E(from: self)
        }
        guard let data = self.data, !data.isEmpty else {
            if response.statusCode == 204 {
                return nil
            }
            // Not using the custom initializer because data could be empty
            throw E(description: nil, statusCode: response.statusCode)
        }
        if let json = json(data) {
            return json
        }
        throw E(from: self)
    }
}
