import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
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
    
    @State private var richTextHeight: CGFloat = 300 // 预设高度
    
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
            RichTextEditorView(text: $richText) // 直接传递 $richText
                .background(Color.clear) // 背景透明
                .frame(height: richTextHeight)
                .padding(.horizontal)
                .onAppear {
                    // 动态调整高度
                    adjustRichTextHeight()
                }

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
                        insertImage(image) // 插入圖片到富文本，但不上传
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

            // 更新：将富文本直接传递给 SaveButtonView
            SaveButtonView(
                userID: userID,
                selectedCoordinate: selectedCoordinate,
                selectedLocationName: selectedLocationName,
                selectedCategory: selectedCategory,
                isPublic: isPublic,
                contents: richText, // 直接传递 NSAttributedString
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

    // 动态调整富文本高度
    func adjustRichTextHeight() {
        DispatchQueue.main.async {
            let maxHeight = UIScreen.main.bounds.height / 2 // 设置最大高度限制
            let newHeight = richText.size().height + 20 // 增加 padding
            richTextHeight = min(max(newHeight, 300), maxHeight) // 动态调整高度
        }
    }

    // 插入图片到富文本（不上传，只显示）
    func insertImage(_ image: UIImage) {
        let editor = RichTextEditorView(text: $richText)
        editor.insertImage(image)
    }

    // 插入連結到富文本
    func insertLink() {
        guard let url = URL(string: linkURL), !linkDisplayText.isEmpty else { return }
        let editor = RichTextEditorView(text: $richText)
        editor.insertLinkBlock(url, displayText: linkDisplayText)
        linkURL = "" // 重置連結和显示文字
        linkDisplayText = ""
    }

    // 插入音訊到富文本
    func insertAudio() {
        let editor = RichTextEditorView(text: $richText)
        editor.insertAudio()
    }
}
