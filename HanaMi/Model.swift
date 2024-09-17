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
    @DocumentID var id: String? // Firestore 自動生成的 ID
    var name: String
    var email: String
    var password: String // 密碼不應該直接存儲在 Firestore 中，應該考慮使用 Firebase Auth 管理
    var treasureList: [String] // 包含寶藏的ID，與 Treasure 進行關聯
    var categories: [String]
}

struct Treasure: Identifiable, Codable {
    @DocumentID var id: String? // 自動由 Firestore 設置的文檔 ID
    var category: String
    var createdTime: Date
    var isPublic: Bool
    var latitude: Double
    var longitude: Double
    var locationName: String
    var contents: [TreasureContent]
}

struct TreasureContent: Identifiable, Codable {
    var id: String = UUID().uuidString  // 每个内容都有唯一的 ID
    var type: ContentType               // 内容的类型
    var content: String                 // 存储数据本身（文字、图片链接、视频链接等）
    var index: Int                      // 新增的字段，用于标记顺序
    var displayText: String?            // 显示在链接上的文本（可选）
    var timestamp: Date = Date()        // 每个内容的创建时间（可选）
}

struct LinkMetadata {
    var title: String
    var description: String
    var imageUrl: String?
}
