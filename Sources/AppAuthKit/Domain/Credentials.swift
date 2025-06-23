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
    let expiresIn: Date
}

public final class Credentials: NSObject, Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Date
    
    public init(accessToken: String, refreshToken: String?, expiresIn: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
    
    init(otpCredentials: OtpCredentials) {
        self.accessToken = otpCredentials.token
        self.refreshToken = otpCredentials.refreshToken
        self.expiresIn = otpCredentials.tokenExpirationInstant ?? Date().addingTimeInterval(60*60*24*365)
    }
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

// MARK: - NSSecureCoding

extension Credentials: NSSecureCoding {

    /// `NSSecureCoding` decoding initializer.
    public convenience init?(coder aDecoder: NSCoder) {
        let accessToken = aDecoder.decodeObject(of: NSString.self, forKey: "accessToken")
        let refreshToken = aDecoder.decodeObject(of: NSString.self, forKey: "refreshToken")
        let expiresIn = aDecoder.decodeObject(of: NSDate.self, forKey: "expiresIn")
        
        self.init(accessToken: accessToken as String? ?? "",
                  refreshToken: refreshToken as String? ?? "",
                  expiresIn: expiresIn as Date? ?? Date())
    }

    /// `NSSecureCoding` encoding method.
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken as NSString, forKey: "accessToken")
        aCoder.encode(refreshToken as NSString?, forKey: "refreshToken")
        aCoder.encode(expiresIn as NSDate, forKey: "expiresIn")
    }

    /// Property that enables secure coding. Equals to `true`.
    public static var supportsSecureCoding: Bool { return true }

}
