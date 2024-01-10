//
//  Authentication.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation

public protocol Authentication {

    var clientId: String { get }
    var url: URL { get }

    // MARK: - Methods
    func login(email: String, code: String) -> FusionRequest<Credentials, AuthenticationError>

    func login(usernameOrEmail username: String, password: String) -> FusionRequest<Credentials, AuthenticationError>

    func forgotPassword(email: String) -> FusionRequest<Void, AuthenticationError>
    
    func renew(withRefreshToken refreshToken: String) -> FusionRequest<Credentials, AuthenticationError>

    func revoke(refreshToken: String) -> FusionRequest<Void, AuthenticationError>
}
