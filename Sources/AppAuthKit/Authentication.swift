//
//  Authentication.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation

public protocol Authentication {

    // MARK: - Methods
    func startPasswordless(email: String) -> FusionRequest<OtpCode, AuthenticationError>
    
    func sendPasswordless(code: String) -> FusionRequest<Void, AuthenticationError>
    
    func login(otp: String) -> FusionRequest<OtpCredentials, AuthenticationError>
    
    func login(usernameOrEmail username: String, password: String) -> FusionRequest<Credentials, AuthenticationError>

    func forgotPassword(email: String) -> FusionRequest<Void, AuthenticationError>
    
    func renew(withRefreshToken refreshToken: String) -> FusionRequest<Credentials, AuthenticationError>
    
    func renewPasswordless(withRefreshToken refreshToken: String) -> FusionRequest<OtpCredentials, AuthenticationError>

    func revoke(refreshToken: String) -> FusionRequest<Void, AuthenticationError>
}
