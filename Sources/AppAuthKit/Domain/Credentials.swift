//
//  Credentials.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation

private struct _StructCredentials {
    let accessToken: String
    let refreshToken: String?
    let userId: String
    let expiresIn: Date
}

public final class Credentials: NSObject, Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let userId: String
    public let expiresIn: Date
    
    private let defaultExpPeriod: TimeInterval = 60*60*24*365
    
    public init(accessToken: String, refreshToken: String?, userId: String, expiresIn: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.expiresIn = expiresIn
    }
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
        case expiresIn = "expiresIn"
        case userId = "userId"
        case refreshToken = "refreshToken"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        refreshToken = try? values.decode(String.self, forKey: .refreshToken)
        userId = try values.decode(String.self, forKey: .userId)
        if let exp = try? values.decode(Date.self, forKey: .expiresIn) {
            expiresIn = exp
        } else {
            let jwt = try? decode(jwt: accessToken)
            expiresIn = jwt?.expiresAt ?? Date().addingTimeInterval(defaultExpPeriod)
        }
    }
}

// MARK: - NSSecureCoding

extension Credentials: NSSecureCoding {

    /// `NSSecureCoding` decoding initializer.
    public convenience init?(coder aDecoder: NSCoder) {
        let accessToken = aDecoder.decodeObject(of: NSString.self, forKey: "accessToken")
        let refreshToken = aDecoder.decodeObject(of: NSString.self, forKey: "refreshToken")
        let expiresIn = aDecoder.decodeObject(of: NSDate.self, forKey: "expiresIn")
        let userId = aDecoder.decodeObject(of: NSString.self, forKey: "userId")
        
        self.init(accessToken: accessToken as String? ?? "",
                  refreshToken: refreshToken as String? ?? "",
                  userId: userId as String? ?? "",
                  expiresIn: expiresIn as Date? ?? Date())
    }

    /// `NSSecureCoding` encoding method.
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken as NSString, forKey: "accessToken")
        aCoder.encode(refreshToken as NSString?, forKey: "refreshToken")
        aCoder.encode(userId as NSString, forKey: "userId")
        aCoder.encode(expiresIn as NSDate, forKey: "expiresIn")
    }

    /// Property that enables secure coding. Equals to `true`.
    public static var supportsSecureCoding: Bool { return true }

}
