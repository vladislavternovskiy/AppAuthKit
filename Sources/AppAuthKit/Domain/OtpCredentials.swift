import Foundation

public final class OtpCredentials: Codable {
    public let token: String
    public let refreshToken: String?
    public let tokenExpirationInstant: Date
    
    private enum CodingKeys: String, CodingKey {
        case token
        case tokenExpirationInstant
        case refreshToken
    }
}
