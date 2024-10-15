import Foundation
import FirebaseFirestore

enum ContentType: String, Codable {
    case text
    case image
    case video
    case link
    case audio
}

struct Users: Identifiable, Codable {
    @DocumentID var id: String? // 用戶的 Firestore document ID
    var name: String
    var email: String
    var treasureList: [String]
    var categories: [String]
    var characterName: String
    var image: String
    var backgroundImage: String
    var collectionTreasureList: [String]
    var blockList: [String]
    var wasBlockedByList: [String]
}

struct Treasure: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var category: String
    var createdTime: Date
    var isPublic: Bool
    var latitude: Double
    var longitude: Double
    var locationName: String
    var contents: [TreasureContent]
    var userID: String
}

struct TreasureContent: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var type: ContentType
    var content: String
    var index: Int
    var displayText: String?
    var timestamp: Date = Date()
}

struct LinkMetadata: Codable {
    var title: String
    var description: String
    var imageUrl: String?
}

struct TreasureSummary: Codable {
    let id: String
    let latitude: Double
    let longitude: Double
    let userID: String
}

struct Report: Codable {
    var id: String = UUID().uuidString
    var reason: String
    var reporter: String
    var reportedUser: String
}
