import Foundation
import FirebaseFirestore

enum ContentType: String, Codable {
    case text
    case image
    case video
    case link
    case map
    case audio
}

struct Users: Identifiable, Codable {
    @DocumentID var id: String? 
    var name: String
    var email: String
    var password: String
    var treasureList: [String]
    var categories: [String]
}

struct Treasure: Identifiable, Codable {
    @DocumentID var id: String?
    var category: String
    var createdTime: Date
    var isPublic: Bool
    var latitude: Double
    var longitude: Double
    var locationName: String
    var contents: [TreasureContent]
}

struct TreasureContent: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: ContentType
    var content: String
    var index: Int
    var displayText: String?
    var timestamp: Date = Date()
}

struct LinkMetadata {
    var title: String
    var description: String
    var imageUrl: String?
}
