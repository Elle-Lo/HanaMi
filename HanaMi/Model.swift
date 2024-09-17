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
    var id: String = UUID().uuidString // 每個內容都有唯一的 ID
    var type: ContentType              // 內容的類型
    var content: String                // 儲存資料本身（文字、圖片連結、影片連結等）
    
    // 可選元數據
    var displayText: String?           // 用於連結顯示的文本
    var imageSize: CGSize?             // 用於圖片顯示的大小 (如果需要的話)
    var timestamp: Date = Date()       // 每個內容的創建時間 (選擇性)
}

struct LinkMetadata {
    var title: String
    var description: String
    var imageUrl: String?
}
