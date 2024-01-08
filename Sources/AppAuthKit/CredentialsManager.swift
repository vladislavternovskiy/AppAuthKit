//
//  CredentialsManager.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation
import SimpleKeychain
import Combine

public struct CredentialsManager {

    private let storage: CredentialsStorage
    private let storeKey: String
    private let authentication: Authentication
    private let dispatchQueue = DispatchQueue(label: "com.fusionAuth.credentialsmanager.serial")
    private let dispatchGroup = DispatchGroup()

    public init(authentication: Authentication,
                storeKey: String = "credentials",
                storage: CredentialsStorage = SimpleKeychain()) {
        self.storeKey = storeKey
        self.storage = storage
        self.authentication = authentication
    }

    public func store(credentials: Credentials) -> Bool {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: credentials, requiringSecureCoding: true) else {
            return false
        }

        return self.storage.setEntry(data, forKey: storeKey)
    }

    public func clear() -> Bool {
        return self.storage.deleteEntry(forKey: storeKey)
    }

    public func revoke(headers: [String: String] = [:],
                       _ callback: @escaping (CredentialsManagerResult<Void>) -> Void) {
        guard let data = self.storage.getEntry(forKey: self.storeKey),
              let credentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data),
              let refreshToken = credentials.refreshToken else {
                  _ = self.clear()
                  return callback(.success(()))
        }

        self.authentication
            .revoke(refreshToken: refreshToken)
            .headers(headers)
            .start { result in
                switch result {
                case .failure(let error):
                    callback(.failure(CredentialsManagerError(code: .revokeFailed, cause: error)))
                case .success:
                    _ = self.clear()
                    callback(.success(()))
                }
            }
    }

    public func hasValid(minTTL: Int = 0) -> Bool {
        guard let credentials = self.retrieveCredentials() else { return false }
        return !self.hasExpired(credentials) && !self.willExpire(credentials, within: minTTL)
    }

    public func canRenew() -> Bool {
        guard let credentials = self.retrieveCredentials() else { return false }
        return credentials.refreshToken != nil
    }
   
    public func credentials(minTTL: Int = 0,
                            parameters: [String: Any] = [:],
                            headers: [String: String] = [:],
                            callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        self.retrieveCredentials(minTTL: minTTL, parameters: parameters, headers: headers, callback: callback)
    }

    public func renew(parameters: [String: Any] = [:],
                      headers: [String: String] = [:],
                      callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        self.retrieveCredentials(parameters: parameters, headers: headers, forceRenewal: true, callback: callback)
    }

    private func retrieveCredentials() -> Credentials? {
        guard let data = self.storage.getEntry(forKey: self.storeKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)
    }

    private func retrieveCredentials(minTTL: Int = 0,
                                     parameters: [String: Any],
                                     headers: [String: String],
                                     forceRenewal: Bool = false,
                                     callback: @escaping (CredentialsManagerResult<Credentials>) -> Void) {
        self.dispatchQueue.async {
            self.dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                guard let credentials = retrieveCredentials() else {
                    self.dispatchGroup.leave()
                    return callback(.failure(.noCredentials))
                }
                guard forceRenewal ||
                      self.hasExpired(credentials) ||
                      self.willExpire(credentials, within: minTTL) else {
                    self.dispatchGroup.leave()
                    return callback(.success(credentials))
                }
                guard let refreshToken = credentials.refreshToken else {
                    self.dispatchGroup.leave()
                    return callback(.failure(.noRefreshToken))
                }

                self.authentication
                    .renew(withRefreshToken: refreshToken)
                    .parameters(parameters)
                    .headers(headers)
                    .start { result in
                        switch result {
                        case .success(let credentials):
                            let newCredentials = Credentials(
                                token: credentials.token,
                                refreshToken: credentials.refreshToken ?? refreshToken,
                                tokenExpirationInstant: credentials.tokenExpirationInstant
                            )
                            if self.willExpire(newCredentials, within: minTTL) {
                                let tokenLifetime = Int(credentials.tokenExpirationInstant.timeIntervalSinceNow)
                                let error = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: tokenLifetime))
                                self.dispatchGroup.leave()
                                callback(.failure(error))
                            } else if !self.store(credentials: newCredentials) {
                                self.dispatchGroup.leave()
                                callback(.failure(CredentialsManagerError(code: .storeFailed)))
                            } else {
                                self.dispatchGroup.leave()
                                callback(.success(newCredentials))
                            }
                        case .failure(let error):
                            self.dispatchGroup.leave()
                            callback(.failure(CredentialsManagerError(code: .renewFailed, cause: error)))
                        }
                    }
            }

            self.dispatchGroup.wait()
        }
    }

    func willExpire(_ credentials: Credentials, within ttl: Int) -> Bool {
        return credentials.tokenExpirationInstant < Date(timeIntervalSinceNow: TimeInterval(ttl))
    }

    func hasExpired(_ credentials: Credentials) -> Bool {
        return credentials.tokenExpirationInstant < Date()
    }
}

// MARK: - Combine
public extension CredentialsManager {

    func revoke(headers: [String: String] = [:]) -> AnyPublisher<Void, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.revoke(headers: headers, callback)
            }
        }.eraseToAnyPublisher()
    }

    func credentials(minTTL: Int = 0,
                     parameters: [String: Any] = [:],
                     headers: [String: String] = [:]) -> AnyPublisher<Credentials, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.credentials(minTTL: minTTL,
                                        parameters: parameters,
                                        headers: headers,
                                        callback: callback)
            }
        }.eraseToAnyPublisher()
    }

    func renew(parameters: [String: Any] = [:],
               headers: [String: String] = [:]) -> AnyPublisher<Credentials, CredentialsManagerError> {
        return Deferred {
            Future { callback in
                return self.renew(parameters: parameters, headers: headers, callback: callback)
            }
        }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if canImport(_Concurrency)
public extension CredentialsManager {

    /// Calls the `/oauth/revoke` endpoint to revoke the refresh token and then clears the credentials if the request
    /// was successful. Otherwise, the credentials are not cleared and an error is thrown.
    func revoke(headers: [String: String] = [:]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.revoke(headers: headers, continuation.resume)
        }
    }

    /// Retrieves credentials from the Keychain and yields new credentials using the refresh token if the access token
    /// is expired. Otherwise, return the retrieved credentials as they are not expired. Renewed credentials will be
    /// stored in the Keychain. **This method is thread-safe**.
    func credentials(minTTL: Int = 0,
                     parameters: [String: Any] = [:],
                     headers: [String: String] = [:]) async throws -> Credentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.credentials(minTTL: minTTL,
                             parameters: parameters,
                             headers: headers,
                             callback: continuation.resume)
        }
    }

    /// Renews credentials using the refresh token and stores them in the Keychain. **This method is thread-safe**.
    func renew(parameters: [String: Any] = [:], headers: [String: String] = [:]) async throws -> Credentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.renew(parameters: parameters, headers: headers, callback: continuation.resume)
        }
    }

}
#endif
