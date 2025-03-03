import Foundation
// MARK: - Country Model
public struct Country: Codable, Identifiable, Hashable {
    public let id: UUID // Auto-generated UUID
    public let name: Name
    public let flag: String?
    // Custom CodingKeys to exclude `id` from decoding
    private enum CodingKeys: String, CodingKey {
        case name, flag
    }
    // Custom initializer for decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate UUID during decoding
        self.name = try container.decode(Name.self, forKey: .name)
        self.flag = try container.decodeIfPresent(String.self, forKey: .flag)
    }
    // Default initializer
    public init(name: Name, flag: String?) {
        self.id = UUID()
        self.name = name
        self.flag = flag
    }
}
// MARK: - Name Model
public struct Name: Codable, Hashable {
    public let common: String
    public let official: String
}
