import Foundation

public final class OtpCredentials: Codable {
    let token: String
    let refreshToken: String?
    let tokenExpirationInstant: Date?
    
    private enum CodingKeys: String, CodingKey {
        case token
        case tokenExpirationInstant
        case refreshToken
    }
    
    public func mapToCredentials() -> Credentials {
        .init(otpCredentials: self)
    }
}
