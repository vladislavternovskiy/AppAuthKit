//
//  Handlers.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

enum DateDecodingStrategy {
    case sinceNow
    case since1970
}

func plainJson(from response: AuthResponse<AuthenticationError>, callback: AuthRequest<[String: Any], AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: Any] {
            callback(.success(dictionary))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch let error as AuthenticationError {
        callback(.failure(error))
    } catch {
        callback(.failure(AuthenticationError(cause: error)))
    }
}

public func codable<T: Codable>(
    from response: AuthResponse<AuthenticationError>,
    callback: AuthRequest<T, AuthenticationError>.Callback
) {
    codable(from: response, dateDecodingStrategy: .sinceNow, callback: callback)
}

func codable<T: Codable>(
    from response: AuthResponse<AuthenticationError>,
    dateDecodingStrategy: DateDecodingStrategy,
    callback: AuthRequest<T, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: Any] {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            let decoder = JSONDecoder()
            switch dateDecodingStrategy {
            case .since1970:
                decoder.dateDecodingStrategy = .millisecondsSince1970
            case .sinceNow:
                decoder.dateDecodingStrategy = .custom { decoder -> Date in
                    let container = try decoder.singleValueContainer()
                    let expirationPeriod = try container.decode(TimeInterval.self)
                    return Date().addingTimeInterval(expirationPeriod)
                }
            }
            
            let decodedObject = try decoder.decode(T.self, from: data)
            callback(.success(decodedObject))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch let error as AuthenticationError {
        callback(.failure(error))
    } catch {
        callback(.failure(AuthenticationError(cause: error)))
    }
}

func authenticationObject<T: JSONObjectPayload>(from response: AuthResponse<AuthenticationError>, callback: AuthRequest<T, AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result() as? [String: Any], let object = T(json: dictionary) {
            callback(.success(object))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch let error as AuthenticationError {
        callback(.failure(error))
    } catch {
        callback(.failure(AuthenticationError(cause: error)))
    }
}

public func noBody(from response: AuthResponse<AuthenticationError>, callback: AuthRequest<Void, AuthenticationError>.Callback) {
    do {
        let result = try response.result()
        if let dict = result as? [String: Any] {
            debugPrint(dict)
        }
        callback(.success(()))
    } catch let error as AuthenticationError where error.code == emptyBodyError {
        callback(.success(()))
    } catch let error as AuthenticationError {
        callback(.failure(error))
    } catch {
        callback(.failure(AuthenticationError(cause: error)))
    }
}
