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
    func login(usernameOrEmail username: String, password: String, contentType: ContentType) -> FusionRequest<Credentials, AuthenticationError>

    func forgotPassword(email: String, contentType: ContentType) -> FusionRequest<Void, AuthenticationError>
    
    func renew(withRefreshToken refreshToken: String, contentType: ContentType) -> FusionRequest<Credentials, AuthenticationError>

    func revoke(refreshToken: String, contentType: ContentType) -> FusionRequest<Void, AuthenticationError>
}
