//
//  Authenticator.swift
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

public struct Authenticator: Authentication {
    
    public struct Configuration {
        let clientSecret: String
        let url: URL
        
        public init(clientSecret: String, url: URL) {
            self.clientSecret = clientSecret
            self.url = url
        }
    }
    
    private let clientSecret: String
    private let url: URL
    
    let session: URLSession
    
    public init(config: Configuration, session: URLSession = URLSession.shared) {
        self.clientSecret = config.clientSecret
        self.url = config.url
        self.session = session
    }
    
    public func login(usernameOrEmail username: String, password: String) -> AuthRequest<Credentials, AuthenticationError> {
        let url = URL(string: "/api/auth/login", relativeTo: url)!
        let payload: [String: Any] = [
            "email": username,
            "password": password,
            "token": clientSecret,
            "provider": "email",
        ]
        
        return AuthRequest(session: session,
                           url: url,
                           method: "POST",
                           handle: codable,
                           parameters: payload,
                           contentType: .json)
    }
    
    public func loginWithApple(idToken: String) -> AuthRequest<Credentials, AuthenticationError> {
        let url = URL(string: "/api/auth/login", relativeTo: url)!
        let payload: [String: Any] = [
            "email": "",
            "password": "",
            "token": idToken,
            "provider": "apple",
        ]
        
        return AuthRequest(session: session,
                           url: url,
                           method: "POST",
                           handle: codable,
                           parameters: payload,
                           contentType: .json)
    }
    
    public func forgotPassword(email: String) -> AuthRequest<Void, AuthenticationError> {
        let payload: [String: Any] = ["email": email]
        let resetPassword = URL(string: "/api/auth/forgot_password", relativeTo: url)!
        return AuthRequest(session: session,
                           url: resetPassword,
                           method: "POST",
                           handle: noBody,
                           parameters: payload,
                           contentType: .json)
    }
    
    public func renew(withRefreshToken refreshToken: String) -> AuthRequest<Credentials, AuthenticationError> {
        let payload: [String: Any] = [
            "refresh_token": refreshToken
        ]
        let oauthToken = URL(string: "/api/auth/refresh_token", relativeTo: url)!
        return AuthRequest(session: session,
                           url: oauthToken,
                           method: "POST",
                           handle: codable,
                           parameters: payload,
                           contentType: .json
        )
    }
}
