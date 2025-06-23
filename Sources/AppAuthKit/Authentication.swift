//
//  Authentication.swift
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation

public protocol Renewable {
    func renew(withRefreshToken refreshToken: String) -> AuthRequest<Credentials, AuthenticationError>
}

public protocol Authentication: Renewable {
    
    func login(usernameOrEmail username: String, password: String) -> AuthRequest<Credentials, AuthenticationError>

    func forgotPassword(email: String) -> AuthRequest<Void, AuthenticationError>
}
