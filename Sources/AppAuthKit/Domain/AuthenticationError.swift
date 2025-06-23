//
//  AuthenticationError.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

public struct AuthenticationError: AuthAPIError {

    /// Additional information about the error.
    public let info: [String: Any]

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response from Auth0.
    ///   - statusCode: HTTP status code of the response.
    ///
    /// - Returns: A new `AuthenticationError`.
    public init(info: [String: Any], statusCode: Int) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
        self.statusCode = statusCode
    }

    /// HTTP status code of the response.
    public let statusCode: Int

    /// The underlying `Error` value, if any. Defaults to `nil`.
    public var cause: Error? {
        return self.info["cause"] as? Error
    }

    /// The code of the error as a string.
    public var code: String {
        let code = self.info["error"] ?? self.info["code"]
        return code as? String ?? unknownError
    }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        self.appendCause(to: self.message)
    }

    public var isNetworkError: Bool {
        guard let code = (self.cause as? URLError)?.code else {
            return false
        }

        let networkErrorCodes: [URLError.Code] = [
            .notConnectedToInternet,
            .networkConnectionLost,
            .dnsLookupFailed,
            .cannotFindHost,
            .cannotConnectToHost,
            .timedOut,
            .internationalRoamingOff,
            .callIsActive
        ]
        return networkErrorCodes.contains(code)
    }
}

// MARK: - Error Messages

extension AuthenticationError {

    var message: String {
        let description = self.info["description"] ?? self.info["error_description"]

        if let string = description as? String {
            return string
        }
        if self.code == unknownError {
            return "Failed with unknown error \(self.info)."
        }

        return "Received error with code \(self.code)."
    }

}

// MARK: - Equatable

extension AuthenticationError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}
