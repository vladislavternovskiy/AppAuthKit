//
//  Credentials.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation

public let defaultTokenExpPeriod: TimeInterval = 60*60*24*365

private struct _StructCredentials {
    let accessToken: String
    let refreshToken: String?
    let userId: String
    let expiresIn: Date
    let sessionTierName: String
    let sessionTierLevel: Int
}

public final class Credentials: NSObject, Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let userId: String
    public let expiresIn: Date
    public let sessionTierName: String
    public let sessionTierLevel: Int

    public init(accessToken: String, refreshToken: String?, userId: String, expiresIn: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.expiresIn = expiresIn
        let tier = Self.resolveSessionTier(from: accessToken)
        self.sessionTierName = tier.name
        self.sessionTierLevel = tier.level
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case expiresIn
        case userId
        case refreshToken
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        refreshToken = try? values.decode(String.self, forKey: .refreshToken)
        userId = try values.decode(String.self, forKey: .userId)

        let jwt = try? decode(jwt: accessToken)
        let exp = jwt?.expiresAt ?? (try? values.decode(Date.self, forKey: .expiresIn))
        expiresIn =  exp ?? Date().addingTimeInterval(defaultTokenExpPeriod)

        if let jwt {
            let tier = Self.resolveSessionTier(jwt: jwt)
            sessionTierName = tier.name
            sessionTierLevel = tier.level
        } else {
            sessionTierName = "free"
            sessionTierLevel = 0
        }
    }
}

private extension Credentials {
    static func resolveSessionTier(from accessToken: String) -> (name: String, level: Int) {
        guard let jwt = try? decode(jwt: accessToken) else {
            return ("free", 0)
        }

        return resolveSessionTier(jwt: jwt)
    }

    static func resolveSessionTier(jwt: JWT) -> (name: String, level: Int) {
        let normalizedName = jwt.sessionTierName
        let parsedLevel = jwt.sessionTierLevel
        let level = max(parsedLevel ?? (normalizedName == "unlimited" ? 1 : 0), 0)
        let name = (normalizedName?.isEmpty == false ? normalizedName : nil)
            ?? (level > 0 ? "unlimited" : "free")

        return (name, level)
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
