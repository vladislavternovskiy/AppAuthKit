//
//  JSONObjectPayload.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

protocol JSONObjectPayload {

    init?(json: [String: Any])
}
