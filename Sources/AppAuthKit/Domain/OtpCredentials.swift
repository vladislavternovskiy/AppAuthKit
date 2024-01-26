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
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        token = try values.decode(String.self, forKey: .token)
        refreshToken = try? values.decode(String.self, forKey: .refreshToken)
        if let exp = try? values.decode(Date.self, forKey: .tokenExpirationInstant) {
            tokenExpirationInstant = exp
        } else if let jwt = try? decode(jwt: token) {
            tokenExpirationInstant = jwt.expiresAt
        } else {
            tokenExpirationInstant = nil
        }
    }
}
