//import SwiftUI
//import UIKit
//
//import Firebase
//import FirebaseFirestore
//import FirebaseStorage
//
//import MapKit
//import CoreLocation
//
////import PhotosUI
//import AVKit
//import AVFoundation
//import UniformTypeIdentifiers
//import MediaPicker
//
//struct DepositPage: View {
//    @State private var isPublic: Bool = true
//    @State private var categories: [String] = []
//    @State private var selectedCategory: String = "Creative"
//    @State private var selectedCoordinate: CLLocationCoordinate2D?
//    @State private var selectedLocationName: String? = "未知地點"
//    @State private var shouldZoomToUserLocation: Bool = true
//    @State private var errorMessage: String?
//    @State private var richText: NSAttributedString = NSAttributedString(string: "")
//    @State private var keyboardHeight: CGFloat = 0
//    @State private var richTextHeight: CGFloat = 300
//
//    @State private var selectedImage: UIImage?
////    @State private var showingImagePicker = false
//    @State private var showingLinkAlert = false
//    @State private var linkURL = ""
//
//    @State private var mediaURLs: [URL] = []  // 用來存儲選擇的多媒體 URL
//    @State private var isShowingMediaPicker = false  // 控制 media picker 是否顯示
//    @State private var selectedMediaItems: [(url: URL, type: String)] = []  // 用來存儲選擇的圖片/影片的資訊
//
//    @State private var isShowingImagePicker = false
//    @State private var mediaURL: URL?
//    @State private var mediaType: ImagePicker.MediaType?
//    @State private var sourceType: UIImagePickerController.SourceType = .camera
//
//    @State private var showingAudioAlert = false
//    @State private var customAlert = false
//    @StateObject private var audioRecorder = AudioRecorder()
//    @State private var isRecording: Bool = false
//    @State private var isPlaying: Bool = false
//    @State private var uploadedAudioURL: URL?
//
//    @StateObject private var locationManager = LocationManager()
//    @StateObject private var searchViewModel = LocationSearchViewModel()
//
//    private var userID: String {
//        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
//    }
//
//    var body: some View {
//        ScrollView {
//        ZStack {
//                   VStack(alignment: .leading, spacing: 20) {
//                       // 頂部的切換按鈕和類別選擇
//                       HStack(spacing: 0) {
//                           ToggleButton(isPublic: $isPublic)
//                           CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
//                       }
//                       .padding(.horizontal)
//
//                       // 地點選擇視圖
//                       LocationSelectionView(
//                           selectedCoordinate: $selectedCoordinate,
//                           selectedLocationName: $selectedLocationName,
//                           shouldZoomToUserLocation: $shouldZoomToUserLocation,
//                           locationManager: locationManager,
//                           searchViewModel: searchViewModel,
//                           userID: userID
//                       )
//
//                       // 主體內容
//                       ScrollView {
//                           // 富文本編輯器
//                           RichTextEditorView(text: $richText, onVideoTapped: { videoURL in
//                               playVideo(url: videoURL)
//                           })
//                           .background(Color.clear)
//                           .frame(height: richTextHeight)
//                           .padding(.horizontal)
//                           .padding(.bottom, keyboardHeight)
//
//                           // 錯誤信息顯示
//                           if let errorMessage = errorMessage {
//                               Text(errorMessage)
//                                   .foregroundColor(.red)
//                                   .font(.caption)
//                           }
//                       }
//                       .scrollIndicators(.hidden)
//                       .padding(.bottom, 0)
//
//                       Spacer()
//
//                       // 工具欄按鈕
//                       HStack {
//                           // 插入圖片按鈕
//                           Button(action: {
//                               isShowingMediaPicker = true
//                           }) {
//                               Image(systemName: "photo.on.rectangle.angled")
//                                   .resizable()
//                                   .frame(width: 30, height: 30)
//                                   .foregroundColor(.colorBrown)
//                                   .padding(10)
//                           }
//                           .mediaImporter(isPresented: $isShowingMediaPicker,
//                                          allowedMediaTypes: .all,
//                                          allowsMultipleSelection: true) { result in
//                               switch result {
//                               case .success(let urls):
//                                   self.mediaURLs = urls
//                                   displayMediaInRichTextEditor(urls: urls)
//                               case .failure(let error):
//                                   print(error)
//                                   self.mediaURLs = []
//                               }
//                           }
//
//                           // 相機按鈕
//                           Button(action: {
//                               isShowingImagePicker = true
//                           }) {
//                               Image(systemName: "camera")
//                                   .resizable()
//                                   .frame(width: 30, height: 30)
//                                   .foregroundColor(.colorBrown)
//                                   .padding(10)
//                           }
//
//                           // 插入連結按鈕
//                           Button(action: {
//                               showingLinkAlert = true
//                           }) {
//                               Image(systemName: "link")
//                                   .resizable()
//                                   .frame(width: 30, height: 30)
//                                   .foregroundColor(.colorBrown)
//                                   .padding(10)
//                           }
//                           .alert("插入連結", isPresented: $showingLinkAlert) {
//                               TextField("連結網址", text: $linkURL)
//                               Button("確認", action: insertLink)
//                               Button("取消", role: .cancel) { }
//                           } message: {
//                               Text("請輸入要插入的連結")
//                           }
//
//                           // 錄音按鈕
//                           Button(action: {
//                               withAnimation {
//                                   customAlert.toggle()
//                               }
//                           }) {
//                               Image(systemName: audioRecorder.recordingURL != nil ? "waveform.circle.fill" : "mic.circle.fill")
//                                   .resizable()
//                                   .frame(width: 30, height: 30)
//                                   .foregroundColor(.brown)
//                                   .padding(10)
//                           }
//
//                           Spacer()
//
//                           // 保存按鈕
//                           SaveButtonView(
//                               userID: userID,
//                               selectedCoordinate: selectedCoordinate,
//                               selectedLocationName: selectedLocationName,
//                               selectedCategory: selectedCategory,
//                               isPublic: isPublic,
//                               contents: richText,
//                               errorMessage: $errorMessage,
//                               audioRecorder: audioRecorder,
//                               onSave: resetFields
//                           )
//
//                       }
//                       .padding(.horizontal, 20)
//                       .padding(.vertical, 40)
//                   }
//
//                   // CustomAlert 彈出視窗
//                   if customAlert {
//                       ZStack {
//
//                           CustomAlert(
//                               show: $customAlert,
//                               audioRecorder: audioRecorder,
//                               richText: $richText,
//                               isRecording: $isRecording,
//                               isPlaying: $isPlaying,
//                               uploadedAudioURL: $uploadedAudioURL
//                           )
//                       }
//                   }
//               }
//        .sheet(isPresented: $isShowingImagePicker) {
//            ImagePicker(mediaURL: $mediaURL, mediaType: $mediaType, sourceType: sourceType)
//                .onDisappear {
//                    if let mediaURL = mediaURL, let mediaType = mediaType {
//                        handlePickedMedia(url: mediaURL, mediaType: mediaType)
//                    }
//                }
//        }
//               }
//           }
//
//    // 订阅键盘事件
////    func subscribeToKeyboardEvents() {
////        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
////            if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
////                keyboardHeight = keyboardSize.height
////            }
////        }
////
////        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
////            keyboardHeight = 0
////        }
////    }
//
//    func handlePickedMedia(url: URL, mediaType: ImagePicker.MediaType) {
//            if mediaType == .photo {
//                // 插入照片到富文本编辑器
//                insertImageToRichTextEditor(from: url)
//            } else if mediaType == .video {
//                // 插入视频到富文本编辑器
//                insertVideoToRichTextEditor(from: url)
//            }
//        }
//
////    // 调整富文本编辑器高度
////    func adjustRichTextHeight() {
////        DispatchQueue.main.async {
////            let maxHeight = UIScreen.main.bounds.height / 2
////            let newHeight = richText.size().height + 20
////            richTextHeight = min(max(newHeight, 300), maxHeight)
////        }
////    }
//
//    // 將選擇的多媒體顯示在富文本編輯器中
//    func displayMediaInRichTextEditor(urls: [URL]) {
//        for url in urls {
//            let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
//
//            if contentType?.conforms(to: .image) == true {
//                // 先將圖片加入到選取的媒體項目
//                selectedMediaItems.append((url: url, type: "image"))
//                // 插入圖片到富文本編輯器
//                insertImageToRichTextEditor(from: url)
//            } else if contentType?.conforms(to: .audiovisualContent) == true {
//                // 先將影片加入到選取的媒體項目
//                selectedMediaItems.append((url: url, type: "video"))
//                // 插入影片到富文本編輯器
//                insertVideoToRichTextEditor(from: url)
//            } else if contentType?.conforms(to: .livePhoto) == true {
//                // 先將 livePhoto 加入到選取的媒體項目
//                selectedMediaItems.append((url: url, type: "livePhoto"))
//                // 這裡可以根據需要處理 livePhoto，或者和影片相同處理
//                insertVideoToRichTextEditor(from: url) // 或者你可以新增專門處理 livePhoto 的方法
//            }
//        }
//    }
//
//    func insertImageToRichTextEditor(from url: URL) {
//        guard let image = UIImage(contentsOfFile: url.path) else { return }
//
//        let maxWidth: CGFloat = 200 // 设置图片最大宽度
//        let aspectRatio = image.size.width / image.size.height
//        let targetHeight = maxWidth / aspectRatio
//
//        let attachment = NSTextAttachment()
//        attachment.image = image
//        attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: targetHeight) // 设置缩小的图片尺寸
//
//        let attributedString = NSAttributedString(attachment: attachment)
//        let mutableRichText = NSMutableAttributedString(attributedString: richText)
//        mutableRichText.append(attributedString)
//        richText = mutableRichText // 更新 richText 变量
//    }
//
//    func insertVideoToRichTextEditor(from url: URL) {
//        let asset = AVAsset(url: url)
//        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
//        assetImageGenerator.appliesPreferredTrackTransform = true
//
//        let time = CMTime(seconds: 1.0, preferredTimescale: 600) // 取第一秒的帧作为缩略图
//
//        if let cgImage = try? assetImageGenerator.copyCGImage(at: time, actualTime: nil) {
//            let thumbnail = UIImage(cgImage: cgImage)
//
//            let maxWidth: CGFloat = 200 // 设置视频预览最大宽度
//            let aspectRatio = thumbnail.size.width / thumbnail.size.height
//            let targetHeight = maxWidth / aspectRatio
//
//            let attachment = NSTextAttachment()
//            attachment.image = thumbnail
//            attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: targetHeight) // 设置缩小的影片缩图尺寸
//
//            // 创建带有附件的 NSMutableAttributedString
//            let attributedString = NSMutableAttributedString(attachment: attachment)
//            // 添加 .link 属性，将视频的 URL 添加到缩略图上
//            attributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: attributedString.length))
//
//            let mutableRichText = NSMutableAttributedString(attributedString: richText)
//            mutableRichText.append(attributedString)
//            richText = mutableRichText
//        }
//    }
//
//        func playVideo(url: URL) {
//            let player = AVPlayer(url: url)
//            let playerViewController = AVPlayerViewController()
//            playerViewController.player = player
//
//            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//               let rootVC = windowScene.windows.first?.rootViewController {
//                rootVC.present(playerViewController, animated: true) {
//                    player.play()
//                }
//            }
//        }
//
//    // 插入圖片或影片到富文本
////    func insertMedia(_ url: URL, mediaType: String) {
////        let editor = RichTextEditorView(text: $richText)
////        if mediaType == "image" {
////            if let image = UIImage(contentsOfFile: url.path) {
////                editor.insertImage(image)
////            }
////        } else if mediaType == "video" {
////            editor.insertVideoPreview(from: url)
////        }
////    }
//
//
//    // 插入链接到富文本
//    func insertLink() {
//        guard let url = URL(string: linkURL) else { return }
//        let editor = RichTextEditorView(text: $richText, onVideoTapped: { _ in })
//        editor.insertLinkPreview(url: url)
//        linkURL = ""
//    }
//
//    // 重置所有字段
//    func resetFields() {
//        if let audioURL = audioRecorder.recordingURL {
//            do {
//                try FileManager.default.removeItem(at: audioURL)
//                print("音訊檔案已成功刪除：\(audioURL)")
//            } catch {
//                print("無法刪除音訊檔案：\(error.localizedDescription)")
//            }
//        }
//
//        richText = NSAttributedString(string: "")
//        selectedCategory = categories.first ?? "未分類"
//        selectedCoordinate = nil
//        selectedLocationName = "未知地點"
//        isPublic = true
//        errorMessage = nil
//        audioRecorder.recordingURL = nil
//        isRecording = false
//        isPlaying = false
//    }
//}

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
import AVKit

struct DepositPage: View {
    @State private var isPublic: Bool = true
    @State private var categories: [String] = []
    @State private var selectedCategory: String = "Creative"
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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 顯示頂部類別選擇等功能
                    HStack(spacing: 0) {
                        ToggleButton(isPublic: $isPublic)
                        CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
                            .padding(.leading, 10)
                    }
                    .padding(.horizontal)
                    
                    // 地點選擇視圖
                    LocationSelectionView(
                        selectedCoordinate: $selectedCoordinate,
                        selectedLocationName: $selectedLocationName,
                        shouldZoomToUserLocation: $shouldZoomToUserLocation,
                        locationManager: locationManager,
                        searchViewModel: searchViewModel,
                        userID: userID
                    )
                    
                    // ScrollView 顯示已插入的媒體 (圖片、影片、音訊、連結)
                    ScrollView(.horizontal) {  // 改為橫向滑動
                        HStack(spacing: 10) {  // 使用 HStack 水平排列項目
                            ForEach(selectedMediaItems.indices, id: \.self) { index in
                                let item = selectedMediaItems[index]
                                
                                ZStack(alignment: .topTrailing) {
                                    if item.type == "image" {
                                        ImageViewWithPreview(
                                            image: UIImage(contentsOfFile: item.url.path)!
                                        )
                                        .frame(width: 300, height: 300)  // 確保圖片高度和寬度一致
                                        .cornerRadius(8)
                                    } else if item.type == "video" {
                                        // 正確顯示影片播放器
                                        VideoPlayerView(url: item.url)
                                            .frame(width: 300, height: 300)
                                            .cornerRadius(8)
                                    } else if item.type == "audio" {
                                        AudioPlayerView(audioURL: item.url)
                                            .frame(width: 300, height: 300)
                                    } else if item.type == "link" {
                                        // 顯示連結預覽
                                        LinkPreviewView(url: item.url)
                                            .frame(width: 350, height: 300)
                                            .cornerRadius(8)
                                    }
                                    
                                    // 添加刪除按鈕
                                    Button(action: {
                                        deleteMediaItem(at: IndexSet(integer: index))
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                            .padding(8)
                                    }
                                }
                                .padding(.bottom, 10)  // 確保每個項目之間有間距
                            }
                        }
                        .padding(.horizontal)  // 保證水平有邊距
                    }
                    .scrollIndicators(.hidden)
                    
                    // TextEditor 文字輸入區域
                    PlaceholderTextEditor(text: $textContent, placeholder: "任何想紀錄的事情都寫下來吧～")
                        .frame(height: 150)
                        .padding()
                        .background(Color.clear)
                }
                .padding(.top, 20)  // 確保內容不會超出螢幕上方
            }


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
                        Image(systemName: "camera")
                            .resizable()
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
                    // 插入連結按鈕
                    Button(action: {
                        showingLinkAlert = true
                        errorMessage = nil
                    }) {
                        Image(systemName: "link")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .font(.system(size: 24))
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
                        Image(systemName: audioRecorder.recordingURL != nil ? "waveform.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .font(.system(size: 24))
                            .foregroundColor(.colorBrown)
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
                        audioRecorder: audioRecorder,
                        onSave: {
                            resetFields()
                            showErrorMessage = false  // 成功保存後，隱藏錯誤訊息
                        }
                    )
                    .opacity(canSave ? 1 : 0.5)  // 不可保存時降低不透明度
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color.clear)
                
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // CustomAlert 彈出視窗，並添加背景遮罩和顯示在中間
            if customAlert {
                Color.black.opacity(0.4).ignoresSafeArea()  // 遮罩
                    .zIndex(1)
                CustomAlert(
                    show: $customAlert,
                    audioRecorder: audioRecorder,
                    richText: .constant(NSAttributedString(string: "")),
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
    }
}

struct PlaceholderTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
            
            TextEditor(text: $text)
                .padding(4)
                .background(Color.white)
                .cornerRadius(8)
        }
    }
}
