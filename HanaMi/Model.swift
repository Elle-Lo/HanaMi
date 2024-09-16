import Foundation

enum ContentType: Int {
    case text = 0
    case image = 1
    case video = 2
    case link = 3
    case map = 4
    case audio = 5
}

struct Treasure: Identifiable {
    var id: String
    var category: String
    var createdTime: Date
    var isPublic: Bool
    var latitude: Double
    var longitude: Double
    var locationName: String
    var contents: [TreasureContent]
}

struct TreasureContent: Identifiable {
    var id: String
    var type: ContentType
    var content: String
}

struct Users: Identifiable {
    var id: String
    var name: String
    var email: String
    var password: String // 密碼（注意：應該加密存儲）
    var treasureList: [String]
    var categories: [String]
}
