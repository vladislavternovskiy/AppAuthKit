import XCTest
@testable import AppAuthKit

final class AppAuthKitTests: XCTestCase {
    func testDecodedJWTReadsTierAndTierLevelClaims() throws {
        let token = try makeJWT(payload: [
            "sub": "user-123",
            "tier": "unlimited",
            "tier_level": "1"
        ])

        let decoded = try decode(jwt: token)

        XCTAssertEqual(decoded.sessionTierName, "unlimited")
        XCTAssertEqual(decoded.sessionTierLevel, 1)
    }

    func testDecodedJWTReturnsNilWhenTierClaimsMissing() throws {
        let token = try makeJWT(payload: [
            "sub": "user-123"
        ])

        let decoded = try decode(jwt: token)

        XCTAssertNil(decoded.sessionTierName)
        XCTAssertNil(decoded.sessionTierLevel)
    }

    func testDecodedJWTNormalizesTierName() throws {
        let token = try makeJWT(payload: [
            "sub": "user-123",
            "tier": " unlimited "
        ])

        let decoded = try decode(jwt: token)

        XCTAssertEqual(decoded.sessionTierName, "unlimited")
    }

    func testCredentialsFallbackToFreeWhenTierClaimsMissing() throws {
        let token = try makeJWT(payload: [
            "sub": "user-123"
        ])
        let credentials = Credentials(
            accessToken: token,
            refreshToken: "refresh-token",
            userId: "user-123",
            expiresIn: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(credentials.sessionTierName, "free")
        XCTAssertEqual(credentials.sessionTierLevel, 0)
    }

    func testCredentialsClampNegativeTierLevelToZero() throws {
        let token = try makeJWT(payload: [
            "sub": "user-123",
            "tier": "free",
            "tier_level": "-5"
        ])
        let credentials = Credentials(
            accessToken: token,
            refreshToken: "refresh-token",
            userId: "user-123",
            expiresIn: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(credentials.sessionTierName, "free")
        XCTAssertEqual(credentials.sessionTierLevel, 0)
    }

    func testCredentialsFallbackTierLevelFromUnlimitedName() throws {
        let token = try makeJWT(payload: [
            "sub": "user-123",
            "tier": "unlimited"
        ])
        let credentials = Credentials(
            accessToken: token,
            refreshToken: "refresh-token",
            userId: "user-123",
            expiresIn: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(credentials.sessionTierName, "unlimited")
        XCTAssertEqual(credentials.sessionTierLevel, 1)
    }

    func testCredentialsExposeSessionTierFieldsFromAccessToken() throws {
        let token = try makeJWT(payload: [
            "sub": "user-123",
            "tier": "unlimited",
            "tier_level": "2"
        ])
        let credentials = Credentials(
            accessToken: token,
            refreshToken: "refresh-token",
            userId: "user-123",
            expiresIn: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(credentials.sessionTierName, "unlimited")
        XCTAssertEqual(credentials.sessionTierLevel, 2)
    }
}

private extension AppAuthKitTests {
    func makeJWT(payload: [String: Any]) throws -> String {
        let header: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT"
        ]

        return [
            try encodeBase64URL(header),
            try encodeBase64URL(payload),
            "signature"
        ]
        .joined(separator: ".")
    }

    func encodeBase64URL(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object)
        return data
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
