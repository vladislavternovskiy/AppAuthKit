//
//  FusionAuthAuthentication.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation

struct FusionAuthAuthentication: Authentication {

    let clientId: String
    let url: URL

    let session: URLSession

    init(clientId: String, url: URL, session: URLSession = URLSession.shared) {
        self.clientId = clientId
        self.url = url
        self.session = session
    }

    func login(email: String, code: String) -> FusionRequest<Credentials, AuthenticationError> {
        return login(username: email, otp: code)
    }

    func login(usernameOrEmail username: String, password: String) -> FusionRequest<Credentials, AuthenticationError> {
        let url = URL(string: "/api/login", relativeTo: self.url)!
        let payload: [String: Any] = [
            "loginId": username,
            "password": password,
            "applicationId": clientId
        ]
        return FusionRequest(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload)
    }
    
    func forgotPassword(email: String) -> FusionRequest<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "loginId": email,
            "applicationId": clientId,
            "sendForgotPasswordEmail": true
        ]
        let resetPassword = URL(string: "/api/user/forgot-password", relativeTo: self.url)!
        return FusionRequest(session: session,
                       url: resetPassword,
                       method: "POST",
                       handle: noBody,
                       parameters: payload)
    }

    func renew(withRefreshToken refreshToken: String) -> FusionRequest<Credentials, AuthenticationError> {
        let payload: [String: Any] = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
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

    func revoke(refreshToken: String) -> FusionRequest<Void, AuthenticationError> {
        let payload: [String: Any] = [
            "refresh_token": refreshToken,
            "global": true
        ]
        let oauthToken = URL(string: "/api/logout", relativeTo: self.url)!
        return FusionRequest(session: session,
                       url: oauthToken,
                       method: "POST",
                       handle: noBody,
                       parameters: payload)
    }
}

// MARK: - Private Methods

private extension FusionAuthAuthentication {

    func login(username: String, otp: String) -> FusionRequest<Credentials, AuthenticationError> {
        let url = URL(string: "/oauth/token", relativeTo: self.url)!
        let payload: [String: Any] = [
            "username": username,
            "otp": otp,
            "client_id": self.clientId
        ]
        return FusionRequest(session: session,
                       url: url,
                       method: "POST",
                       handle: codable,
                       parameters: payload)
    }
}
