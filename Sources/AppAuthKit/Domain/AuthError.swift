//
//  FusionAuthError.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

let unknownError = "api.internal_error.unknown"
let nonJSONError = "api.internal_error.plain"
let emptyBodyError = "api.internal_error.empty"

public protocol AuthError: LocalizedError, CustomDebugStringConvertible {

    /// The underlying `Error` value, if any.
    var cause: Error? { get }

}

public extension AuthError {

    /// The underlying `Error` value, if any. Defaults to `nil`.
    var cause: Error? { return nil }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    var localizedDescription: String { return self.debugDescription }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    var errorDescription: String? { return self.debugDescription }

}

extension AuthError {

    func appendCause(to errorMessage: String) -> String {
        guard let cause = self.cause else {
            return errorMessage
        }

        let separator = errorMessage.hasSuffix(".") ? "" : "."
        return "\(errorMessage)\(separator) CAUSE: \(String(describing: cause))"
    }

}

/// Generic representation of Fusion API errors.
public protocol AuthAPIError: AuthError {

    /// Additional information about the error.
    var info: [String: Any] { get }

    /// The code of the error as a string.
    var code: String { get }

    /// HTTP status code of the response.
    var statusCode: Int { get }

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response from FusionAuth.
    ///   - statusCode: HTTP status code of the response.
    ///
    /// - Returns: A new `FusionAuthAPIError`.
    init(info: [String: Any], statusCode: Int)

}

extension AuthAPIError {

    init(info: [String: Any], statusCode: Int = 0) {
        self.init(info: info, statusCode: statusCode)
    }

    init(cause error: Error, statusCode: Int = 0) {
        let info: [String: Any] = [
            "code": nonJSONError,
            "description": "Unable to complete the operation.",
            "cause": error
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(description: String?, statusCode: Int = 0) {
        let info: [String: Any] = [
            "code": description != nil ? nonJSONError : emptyBodyError,
            "description": description ?? "Empty response body."
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(from response: AuthResponse<Self>) {
        self.init(description: string(response.data), statusCode: response.response?.statusCode ?? 0)
    }
}
