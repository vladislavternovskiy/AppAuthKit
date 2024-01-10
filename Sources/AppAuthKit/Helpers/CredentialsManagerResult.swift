//
//  CredentialsManagerResult.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 07.01.2024.
//

import Foundation

/**
 `Result` wrapper for Credentials Manager operations.
 */
public typealias CredentialsManagerResult<T> = Result<T, CredentialsManagerError>
