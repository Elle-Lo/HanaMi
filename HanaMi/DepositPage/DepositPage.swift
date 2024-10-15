import SwiftUI
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import MapKit
import CoreLocation
import AVKit
import AVFoundation
import UniformTypeIdentifiers
import MediaPicker

struct DepositPage: View {
    @State private var isPublic: Bool = true
    @State private var categories: [String] = []
    @State private var selectedCategory: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation: Bool = true
    @State private var showErrorMessage = false // 用來控制是否顯示錯誤訊息
    @State private var errorMessage: String?
    @State private var textContent: String = ""  // 使用 TextEditor 替換富文本編輯器
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var selectedMediaItems: [(url: URL, type: String)] = []  // 存儲選擇的圖片/影片
    @State private var isShowingCameraPicker = false  // 控制相機的顯示
    @State private var isShowingMediaPicker = false  // 控制媒體庫的顯示
    @State private var mediaURLs: [URL] = []  // 存儲多選的媒體 URL
    @State private var mediaType: ImagePicker.MediaType?
    @State private var cameraMediaURL: URL?  // 單個 URL 來處理相機拍攝
    @State private var isShowingActionSheet = false // 控制 ActionSheet 的顯示
    
    @State private var showingLinkAlert = false
    @State private var linkURL = ""
    
    @State private var customAlert = false
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording: Bool = false
    @State private var isPlaying: Bool = false
    @State private var uploadedAudioURL: URL?
    
    @State private var isSaveAnimationPlaying: Bool = false
    @State private var isSaving: Bool = false
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchViewModel = LocationSearchViewModel()
    
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    private var canSave: Bool {
           let trimmedText = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
           return selectedCoordinate != nil &&
                  (!trimmedText.isEmpty || !selectedMediaItems.isEmpty || audioRecorder.recordingURL != nil)
       }
    
    var body: some View {
        ZStack {
            
            Color(.colorGrayBlue)  // 這裡可以替換成任何你想要的顏色或圖片
                .edgesIgnoringSafeArea(.all)  // 擴展到整個屏幕
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TopControlsView(isPublic: $isPublic, selectedCategory: $selectedCategory, categories: $categories, userID: userID)
                    
//                    HStack(spacing: 0) {
//                        ToggleButton(isPublic: $isPublic)
//                        CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
//                    }
//                    .padding(.horizontal)
                    
                    LocationSelectionView(
                        selectedCoordinate: $selectedCoordinate,
                        selectedLocationName: $selectedLocationName,
                        shouldZoomToUserLocation: $shouldZoomToUserLocation,
                        locationManager: locationManager,
                        searchViewModel: searchViewModel,
                        userID: userID
                    )
                    
                    MediaScrollView(selectedMediaItems: $selectedMediaItems)
                   
//                    ScrollView(.horizontal) {  // 改為橫向滑動
//                        HStack(spacing: 10) {  // 使用 HStack 水平排列項目
//                            ForEach(selectedMediaItems.indices, id: \.self) { index in
//                                let item = selectedMediaItems[index]
//                                
//                                ZStack(alignment: .topTrailing) {
//                                    if item.type == "image" {
//                                        ImageViewWithPreview(
//                                            image: UIImage(contentsOfFile: item.url.path)!
//                                        )
//                                        .frame(width: 300, height: 300)  // 確保圖片高度和寬度一致
//                                        .cornerRadius(8)
//                                    } else if item.type == "video" {
//                                        // 正確顯示影片播放器
//                                        VideoPlayerView(url: item.url)
//                                            .frame(width: 300, height: 300)
//                                            .cornerRadius(8)
//                                    } else if item.type == "audio" {
//                                        AudioPlayerView(audioURL: item.url)
//                                            .frame(width: 300, height: 300)
//                                    } else if item.type == "link" {
//                                        // 顯示連結預覽
//                                        LinkPreviewView(url: item.url)
//                                            .frame(width: 350, height: 300)
//                                            .cornerRadius(8)
//                                    }
//                                    
//                                    // 添加刪除按鈕
//                                    Button(action: {
//                                        deleteMediaItem(at: IndexSet(integer: index))
//                                    }) {
//                                        Image(systemName: "xmark.circle.fill")
//                                            .resizable()
//                                            .frame(width: 24, height: 24)
//                                            .foregroundColor(.white)
//                                            .background(Color.black.opacity(0.7))
//                                            .clipShape(Circle())
//                                            .padding(8)
//                                    }
//                                }
//                                .padding(.bottom, 10)  // 確保每個項目之間有間距
//                            }
//                        }
//                        .padding(.horizontal)  // 保證水平有邊距
//                    }
//                    .scrollIndicators(.hidden)
                    
                    // TextEditor 文字輸入區域
                    PlaceholderTextEditor(text: $textContent, placeholder: "一個故事、一場經歷、一個情緒 \n任何想紀錄的事情都寫下來吧～")
                        .lineSpacing(10)
                        .frame(height: 150)
                        .padding(.horizontal, 15)
                        .background(Color.clear)
                }
                .padding(.top, 20)  // 確保內容不會超出螢幕上方
            }
            .padding(.horizontal, 15)


            // 固定工具欄
            VStack {
                
                Spacer()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.gray)
                        .font(.custom("LexendDeca-SemiBold", size: 11))
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                // 工具欄按鈕
                HStack {
                    // 相機按鈕
                    Button(action: {
                        isShowingActionSheet = true
                        errorMessage = nil
                    }) {
                        Image("camera")
                            .frame(width: 30, height: 30)
                            .font(.system(size: 24))
                            .foregroundColor(.colorBrown)
                            .padding(10)
                    }
                    .actionSheet(isPresented: $isShowingActionSheet) {
                        ActionSheet(title: Text("選擇來源"), buttons: [
                            .default(Text("相機")) {
                                isShowingCameraPicker = true
                            },
                            .default(Text("媒體庫")) {
                                isShowingMediaPicker = true
                            },
                            .cancel()
                        ])
                    }
                    // 打開相機的 Sheet
                    .sheet(isPresented: $isShowingCameraPicker) {
                        ImagePicker(mediaURL: $cameraMediaURL, mediaType: $mediaType, sourceType: .camera)
                            .edgesIgnoringSafeArea(.all)
                            .onDisappear {
                                if let cameraMediaURL = cameraMediaURL, let mediaType = mediaType {
                                    handlePickedMedia(urls: [cameraMediaURL], mediaType: mediaType)
                                }
                            }
                    }
                    // 打開媒體庫的 MediaImporter
                    .mediaImporter(isPresented: $isShowingMediaPicker, allowedMediaTypes: .all, allowsMultipleSelection: true) { result in
                        switch result {
                        case .success(let urls):
                            mediaURLs = urls
                            handlePickedMedia(urls: mediaURLs, mediaType: nil)
                        case .failure(let error):
                            print("Error selecting media: \(error)")
                        }
                    }
                    .background(Color.clear.edgesIgnoringSafeArea(.all))
                    
                    // 插入連結按鈕
                    Button(action: {
                        showingLinkAlert = true
                        errorMessage = nil
                    }) {
                        Image(systemName: "link")
                            .font(.system(size: 22))
                            .foregroundColor(.colorBrown)
                            .padding(10)
                    }
                    .alert("插入連結", isPresented: $showingLinkAlert) {
                        TextField("連結網址", text: $linkURL)
                        Button("確認", action: insertLink)
                        Button("取消", role: .cancel) { }
                    }
                    
                    // 錄音按鈕
                    Button(action: {
                        withAnimation {
                            customAlert.toggle()
                            errorMessage = nil
                        }
                    }) {
                        Image(systemName: audioRecorder.recordingURL != nil ? "checkmark.seal.fill" : "mic.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.colorBrown)
                            .padding(10)
                    }
                    
                    Spacer()
                    
                    SaveButtonView(
                        userID: userID,
                        selectedCoordinate: selectedCoordinate,
                        selectedLocationName: selectedLocationName,
                        selectedCategory: selectedCategory,
                        isPublic: isPublic,
                        textContent: textContent,
                        selectedMediaItems: selectedMediaItems,
                        errorMessage: $errorMessage,
                        isSaving: $isSaving,
                        audioRecorder: audioRecorder,
                        onSave: {
                            resetFields()
                            showErrorMessage = false  // 成功保存後，隱藏錯誤訊息
                            isSaveAnimationPlaying = true
                            isSaving = true
                        }
                    )
                    .opacity(canSave ? 1 : 0.5)  // 不可保存時降低不透明度
                    .disabled(isSaving)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(Color.clear)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            // 顯示保存成功動畫
            if isSaveAnimationPlaying {
                LottieView(animationFileName: "flying", isPlaying: $isSaveAnimationPlaying)
                    .frame(width: 300, height: 300)
                    .scaleEffect(0.2)  // 調整動畫大小
                    .cornerRadius(10)
                    .shadow(radius: 3)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isSaveAnimationPlaying = false
                        }
                    }
                    .zIndex(1)
            }
            
            // CustomAlert 彈出視窗，並添加背景遮罩和顯示在中間
            if customAlert {
                Color.black.opacity(0.4).ignoresSafeArea()  // 遮罩
                    .zIndex(1)
                CustomAlert(
                    show: $customAlert,
                    richText: .constant(NSAttributedString(string: "")), 
                    audioRecorder: audioRecorder,
                    isRecording: $isRecording,
                    isPlaying: $isPlaying,
                    uploadedAudioURL: $uploadedAudioURL
                )
                .zIndex(2)
                .transition(.scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // 滿版
                .background(Color.clear)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2.5)  // 顯示在螢幕中央
            }
        }
        .onAppear {
                // 在畫面出現時檢查類別並設定選中的類別
                if let firstCategory = categories.first {
                    selectedCategory = firstCategory
                } else {
                    selectedCategory = "未分類"
                }
            }
            .onChange(of: categories) { newCategories in
                // 類別變更時重新設定選中的類別
                if let firstCategory = newCategories.first {
                    selectedCategory = firstCategory
                } else {
                    selectedCategory = "未分類"
                }
            }
    }
    
    // 處理選取的多媒體並將其添加到 ScrollView
    func handlePickedMedia(urls: [URL], mediaType: ImagePicker.MediaType?) {
        for url in urls {
            // 根據 URL 的檔案屬性檢查媒體類型
            do {
                let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
                
                if let contentType = resourceValues.contentType {
                    if contentType.conforms(to: .image) {
                        // 確認是圖片
                        selectedMediaItems.append((url: url, type: "image"))
                    } else if contentType.conforms(to: .audiovisualContent) {
                        // 確認是影片
                        selectedMediaItems.append((url: url, type: "video"))
                    } else {
                        print("Unsupported media type: \(contentType)")
                    }
                } else {
                    print("Unable to determine content type for URL: \(url)")
                }
            } catch {
                print("Error retrieving content type for URL: \(url), error: \(error)")
            }
        }
    }
    
    // 插入連結
    func insertLink() {
        guard let url = URL(string: linkURL) else { return }
        selectedMediaItems.append((url: url, type: "link"))
        linkURL = ""
    }
    
    // 刪除 ScrollView 中的項目
    func deleteMediaItem(at offsets: IndexSet) {
        selectedMediaItems.remove(atOffsets: offsets)
    }
    
    // 重置所有字段
    func resetFields() {
        textContent = ""
        selectedCategory = categories.first ?? "未分類"
        selectedCoordinate = nil
        selectedLocationName = "選擇地點"
        isPublic = true
        errorMessage = ""
        audioRecorder.recordingURL = nil
        isRecording = false
        isPlaying = false
        selectedMediaItems.removeAll()  // 清空已選擇的媒體
        DispatchQueue.main.async {
               isSaving = false  // 重置完成後啟用按鈕
           }
    }
}

struct PlaceholderTextEditor: View {
    @FocusState private var keyboardFocused: Bool  // 用於跟踪 TextEditor 是否獲得焦點
        @Binding var text: String  // 綁定的文本
        var placeholder = ""  // 占位符文字

        // 判斷是否顯示占位符：當文本為空且鍵盤未聚焦時顯示
        var shouldShowPlaceholder: Bool {
            text.isEmpty && !keyboardFocused
        }

        var body: some View {
            ZStack(alignment: .topLeading) {
                
                TextEditor(text: $text)
                    .foregroundColor(.black)
                    .colorMultiply(shouldShowPlaceholder ? .clear : .colorGrayBlue)
                    .focused($keyboardFocused)
                
                if shouldShowPlaceholder {
                    Text(placeholder)
                        .padding(.top, 10)
                        .padding(.leading, 6)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            keyboardFocused = true
                        }
                }
            }
        }
}

struct TopControlsView: View {
    @Binding var isPublic: Bool
    @Binding var selectedCategory: String
    @Binding var categories: [String]
    let userID: String

    var body: some View {
        HStack(spacing: 0) {
            ToggleButton(isPublic: $isPublic)
            CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
        }
        .padding(.horizontal)
    }
}

struct MediaScrollView: View {
    @Binding var selectedMediaItems: [(url: URL, type: String)]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(selectedMediaItems.indices, id: \.self) { index in
                    MediaItemView(item: selectedMediaItems[index]) {
                        selectedMediaItems.remove(at: index)
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

struct MediaItemView: View {
    let item: (url: URL, type: String)
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if item.type == "image" {
                ImageViewWithPreview(image: UIImage(contentsOfFile: item.url.path)!)
                    .frame(width: 300, height: 300)
                    .cornerRadius(8)
            } else if item.type == "video" {
                VideoPlayerView(url: item.url)
                    .frame(width: 300, height: 300)
                    .cornerRadius(8)
            } else if item.type == "audio" {
                AudioPlayerView(audioURL: item.url)
                    .frame(width: 300, height: 300)
            } else if item.type == "link" {
                LinkPreviewView(url: item.url)
                    .frame(width: 350, height: 300)
                    .cornerRadius(8)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
    }
}
