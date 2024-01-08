//
//  Credentials.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation

private struct _StructCredentials {
    let token: String
    let refreshToken: String?
    let tokenExpirationInstant: Date
}

public final class Credentials: NSObject, Codable {
    public let token: String
    public let refreshToken: String?
    public let tokenExpirationInstant: Date
    
    init(token: String, refreshToken: String?, tokenExpirationInstant: Date) {
        self.token = token
        self.refreshToken = refreshToken
        self.tokenExpirationInstant = tokenExpirationInstant
    }
}

// MARK: - NSSecureCoding

extension Credentials: NSSecureCoding {

    /// `NSSecureCoding` decoding initializer.
    public convenience init?(coder aDecoder: NSCoder) {
        let token = aDecoder.decodeObject(of: NSString.self, forKey: "token")
        let refreshToken = aDecoder.decodeObject(of: NSString.self, forKey: "refreshToken")
        let expiresIn = aDecoder.decodeObject(of: NSDate.self, forKey: "tokenExpirationInstant")
        
        self.init(token: token as String? ?? "",
                  refreshToken: refreshToken as String? ?? "",
                  tokenExpirationInstant: expiresIn as Date? ?? Date())
    }

    /// `NSSecureCoding` encoding method.
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.token as NSString, forKey: "token")
        aCoder.encode(self.refreshToken as NSString?, forKey: "refreshToken")
        aCoder.encode(self.tokenExpirationInstant as NSDate, forKey: "tokenExpirationInstant")
    }

    /// Property that enables secure coding. Equals to `true`.
    public static var supportsSecureCoding: Bool { return true }

}
