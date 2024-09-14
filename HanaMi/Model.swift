import Foundation

struct Treasure: Identifiable {
    var id: String
    var category: String
    var createdTime: Date
    var isPublic: Bool
    var latitude: Double
    var longitude: Double
    var contents: [TreasureContent]
}

struct TreasureContent: Identifiable {
    var id: String
    var type: String
    var content: String
}

struct Users: Identifiable {
    var id: String
    var name: String
    var email: String
    var password: String
    var treasureList: [String]
}


