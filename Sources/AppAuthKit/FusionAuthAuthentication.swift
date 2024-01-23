//
//  FusionAuthAuthentication.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

public struct FusionAuthAuthentication: Authentication {
    
    public struct Configuration {
        let clientId: String
        let clientSecret: String
        let url: URL
        let apiKey: String
        
        public init(clientId: String, clientSecret: String, url: URL, apiKey: String = "") {
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.url = url
            self.apiKey = apiKey
        }
    }
    
    private let clientId: String
    private let clientSecret: String
    private let apiKey: String
    private let url: URL
    private let defaultScope = "offline_access openid"
    
    let session: URLSession
    
    public init(config: Configuration, session: URLSession = URLSession.shared) {
        self.clientId = config.clientId
        self.clientSecret = config.clientSecret
        self.url = config.url
        self.apiKey = config.apiKey
        self.session = session
    }
    
    public func startPasswordless(email: String) -> FusionRequest<OtpCode, AuthenticationError> {
        let url = URL(string: "/api/passwordless/start", relativeTo: self.url)!
        let payload: [String: Any] = [
            "applicationId": clientId,
            "loginId": email
        ]
        return FusionRequest(session: session,
                             url: url,
                             method: "POST",
                             handle: codable,
                             parameters: payload,
                             contentType: .json)
        .headers(["Authorization": apiKey])
    }
    
    public func sendPasswordless(code: String) -> FusionRequest<Void, AuthenticationError> {
        let url = URL(string: "/api/passwordless/send", relativeTo: self.url)!
        let payload: [String: Any] = [
            "code": code
        ]
        return FusionRequest(session: session,
                             url: url,
                             method: "POST",
                             handle: noBody,
                             parameters: payload,
                             contentType: .json)
        .headers(["Authorization": apiKey])
    }
    
    public func login(otp: String) -> FusionRequest<OtpCredentials, AuthenticationError> {
        let url = URL(string: "/api/passwordless/login", relativeTo: self.url)!
        let payload: [String: Any] = [
            "applicationId": clientId,
            "code": otp
        ]
        return FusionRequest(
            session: session,
            url: url,
            method: "POST",
            handle: { response, callback in
                codable(from: response, dateDecodingStrategy: .since1970, callback: callback)
            },
            parameters: payload,
            contentType: .json
        )
        .headers(["Authorization": apiKey])
    }
    
    public func login(usernameOrEmail username: String, password: String) -> FusionRequest<Credentials, AuthenticationError> {
        let url = URL(string: "/oauth2/token", relativeTo: self.url)!
        let payload: [String: Any] = [
            "username": username,
            "password": password,
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "password",
            "scope": defaultScope
        ]
        
        return FusionRequest(session: session,
                             url: url,
                             method: "POST",
                             handle: codable,
                             parameters: payload,
                             contentType: .urlEncoded)
    }
    
    public func forgotPassword(email: String) -> FusionRequest<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "loginId": email,
            "applicationId": clientId
        ]
        let resetPassword = URL(string: "/api/user/forgot-password", relativeTo: self.url)!
        return FusionRequest(session: session,
                             url: resetPassword,
                             method: "POST",
                             handle: noBody,
                             parameters: payload,
                             contentType: .json)
    }
    
    public func renew(withRefreshToken refreshToken: String) -> FusionRequest<Credentials, AuthenticationError> {
        let payload: [String: Any] = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "client_secret": clientSecret,
            "scope": defaultScope
        ]
        let oauthToken = URL(string: "/oauth2/token", relativeTo: self.url)!
        return FusionRequest(session: session,
                             url: oauthToken,
                             method: "POST",
                             handle: codable,
                             parameters: payload,
                             contentType: .urlEncoded
        )
    }
    
    public func revoke(refreshToken: String) -> FusionRequest<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "refresh_token": refreshToken,
            "global": true
        ]
        let oauthToken = URL(string: "/api/logout", relativeTo: self.url)!
        return FusionRequest(session: session,
                             url: oauthToken,
                             method: "POST",
                             handle: noBody,
                             parameters: payload,
                             contentType: .json)
    }
}
