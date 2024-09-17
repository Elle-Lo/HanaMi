import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit
import CoreLocation
import PhotosUI

struct DepositPage: View {
    @State private var isPublic: Bool = true
    @State private var categories: [String] = ["Creative", "Technology", "Health", "Education"]
    @State private var selectedCategory: String = "Creative"
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String? = "未知地點"
    @State private var shouldZoomToUserLocation: Bool = true
    @State private var errorMessage: String?
    @State private var activeSheet: ActiveSheet? = nil
    @State private var richText: NSAttributedString = NSAttributedString(string: "") // 富文本的內容

    @State private var selectedImage: UIImage? // 用來儲存選擇的圖片
    @State private var showingImagePicker = false // 控制顯示相片選擇器
    @State private var showingLinkAlert = false // 控制顯示連結插入的對話框
    @State private var linkURL = "" // 存儲用戶輸入的URL
    @State private var linkDisplayText = "" // 存儲顯示在文本中的鏈接文本

    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchViewModel = LocationSearchViewModel()
    
    let userID = "g61HUemIJIRIC1wvvIqa"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 公開/私人切換按鈕 和 類別選擇
            HStack(spacing: 20) {
                ToggleButton(isPublic: $isPublic)
                CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
            }
            .padding(.horizontal)

            // 地點選擇部分
            LocationSelectionView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                locationManager: locationManager,
                searchViewModel: searchViewModel
            )

            // 富文本編輯器
            RichTextEditorView(text: $richText)
                .frame(minHeight: 300)
                .border(Color.gray, width: 1)
                .padding(.horizontal)
            
            HStack {
                // 插入圖片按鈕
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                .sheet(isPresented: $showingImagePicker) {
                    PhotoPicker(image: $selectedImage)
                }
                .onChange(of: selectedImage) { newImage in
                    if let image = newImage {
                        insertImage(image)
                    }
                }

                // 插入連結按鈕
                Button(action: {
                    showingLinkAlert = true
                }) {
                    Image(systemName: "link")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                .alert("插入連結", isPresented: $showingLinkAlert) {
                    TextField("連結網址", text: $linkURL)
                    TextField("顯示文字", text: $linkDisplayText)
                    Button("確認", action: insertLink)
                    Button("取消", role: .cancel) { }
                }

                // 插入音訊按鈕
                Button(action: {
                    insertAudio()
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            Spacer()

            // 保存按鈕與錯誤訊息
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            SaveButtonView(
                userID: userID,
                selectedCoordinate: selectedCoordinate,
                selectedLocationName: selectedLocationName,
                selectedCategory: selectedCategory,
                isPublic: isPublic,
                contents: extractContentsFromRichText(richText), // 傳遞從富文本中提取的內容
                errorMessage: $errorMessage
            )
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .map:
                MapView(
                    selectedCoordinate: $selectedCoordinate,
                    selectedLocationName: $selectedLocationName,
                    shouldZoomToUserLocation: $shouldZoomToUserLocation
                )
            case .search:
                LocationSearchView(
                    viewModel: searchViewModel,
                    selectedCoordinate: $selectedCoordinate,
                    selectedLocationName: $selectedLocationName,
                    locationManager: locationManager
                )
            }
        }
    }

    // 插入圖片到富文本
    func insertImage(_ image: UIImage) {
        let editor = RichTextEditorView(text: $richText)
        editor.insertImage(image)
    }

    // 插入連結區塊到富文本
    func insertLink() {
        guard let url = URL(string: linkURL), !linkDisplayText.isEmpty else { return }
        let editor = RichTextEditorView(text: $richText)
        editor.insertLinkBlock(url, displayText: linkDisplayText)
        linkURL = "" // 重置鏈接和顯示文字
        linkDisplayText = ""
    }

    // 插入音訊到富文本
    func insertAudio() {
        let editor = RichTextEditorView(text: $richText)
        editor.insertAudio()
    }
    
    func extractContentsFromRichText(_ richText: NSAttributedString) -> [TreasureContent] {
        var contents: [TreasureContent] = []

        richText.enumerateAttributes(in: NSRange(location: 0, length: richText.length), options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment, let image = attachment.image {
                // 插入圖片內容
                if let imageData = image.pngData() {
                    let base64String = imageData.base64EncodedString() // 將圖片轉換成 base64
                    let content = TreasureContent(type: .image, content: base64String)
                    contents.append(content)
                }
            } else if let link = attributes[.link] as? URL {
                // 插入連結內容
                let displayText = richText.attributedSubstring(from: range).string
                let content = TreasureContent(type: .link, content: link.absoluteString, displayText: displayText)
                contents.append(content)
            } else {
                // 插入文字內容
                let text = richText.attributedSubstring(from: range).string
                let content = TreasureContent(type: .text, content: text)
                contents.append(content)
            }
        }

        return contents
    }

}

#Preview {
    DepositPage()
}
