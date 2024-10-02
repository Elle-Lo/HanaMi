import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

import MapKit
import CoreLocation

//import PhotosUI
import AVKit
import AVFoundation
import MediaPicker

struct DepositPage: View {
    @State private var isPublic: Bool = true
    @State private var categories: [String] = []
    @State private var selectedCategory: String = "Creative"
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String? = "未知地點"
    @State private var shouldZoomToUserLocation: Bool = true
    @State private var errorMessage: String?
    @State private var richText: NSAttributedString = NSAttributedString(string: "")
    @State private var keyboardHeight: CGFloat = 0
    @State private var richTextHeight: CGFloat = 300
    
    @State private var selectedImage: UIImage?
//    @State private var showingImagePicker = false
    @State private var showingLinkAlert = false
    @State private var linkURL = ""
    
    @State private var mediaURLs: [URL] = []  // 用來存儲選擇的多媒體 URL
    @State private var isShowingMediaPicker = false  // 控制 media picker 是否顯示
    @State private var selectedMediaItems: [(url: URL, type: String)] = []  // 用來存儲選擇的圖片/影片的資訊
    
    @State private var showingAudioSheet = false
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording: Bool = false
    @State private var isPlaying: Bool = false
    @State private var uploadedAudioURL: URL?
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchViewModel = LocationSearchViewModel()
    
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 顶部的切换按钮和类别选择
            HStack(spacing: 0) {
                ToggleButton(isPublic: $isPublic)
                CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
            }
            .padding(.horizontal)
            
            // 地点选择视图
            LocationSelectionView(
                selectedCoordinate: $selectedCoordinate,
                selectedLocationName: $selectedLocationName,
                shouldZoomToUserLocation: $shouldZoomToUserLocation,
                locationManager: locationManager,
                searchViewModel: searchViewModel,
                userID: userID
            )
            
            // 主体内容
            ScrollView {
                // 富文本编辑器
                RichTextEditorView(text: $richText, onVideoTapped: { videoURL in
                                // 點擊縮圖播放影片
                                playVideo(url: videoURL)
                            })
                    .background(Color.clear)
                    .frame(height: richTextHeight)
                    .padding(.horizontal)
//                    .onAppear {
//                        adjustRichTextHeight()
//                    }
                    .padding(.bottom, keyboardHeight)
                    .padding(.horizontal)
                
                
                // 错误信息显示
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.bottom, 0)
            .scrollIndicators(.hidden)
            
            Spacer()
            
            // 工具栏按钮
            HStack {
                // 插入图片按钮
                Button(action: {
                    isShowingMediaPicker = true
                }) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.colorBrown)
                        .padding(10)
                }
                .mediaImporter(isPresented: $isShowingMediaPicker,
                               allowedMediaTypes: .all,
                               allowsMultipleSelection: true) { result in
                    switch result {
                    case .success(let urls):
                        self.mediaURLs = urls
                        displayMediaInRichTextEditor(urls: urls)
                    case .failure(let error):
                        print(error)
                        self.mediaURLs = []
                    }
                }
                
//                ForEach(selectedMediaItems, id: \.url) { mediaItem in
//                    if mediaItem.type == "image" {
//                        AsyncImage(url: mediaItem.url) { image in
//                            image
//                                .resizable()
//                                .scaledToFit()
//                        } placeholder: {
//                            ProgressView()
//                        }
//                    } else if mediaItem.type == "video" {
//                        VideoPlayer(player: AVPlayer(url: mediaItem.url))
//                            .scaledToFit()
//                    } else if mediaItem.type == "livePhoto" {
//                        VStack {
//                            Text("Live Photo (Image + Video)")
//                                .font(.headline)
//                            
//                            // 顯示靜態圖像部分
//                            AsyncImage(url: mediaItem.url) { image in
//                                image
//                                    .resizable()
//                                    .scaledToFit()
//                            } placeholder: {
//                                ProgressView()
//                            }
//                            
//                            // 顯示短視頻部分
//                            VideoPlayer(player: AVPlayer(url: mediaItem.url))
//                                .scaledToFit()
//                        }
//                    }
//                }

//                .sheet(isPresented: $isShowingMediaPicker) {
//                    PhotoPicker(image: $selectedImage)
//                }
//                .onChange(of: selectedImage) { newImage in
//                    if let image = newImage {
//                        insertMedia(image, mediaType: "image")
//                    }
//                }
                
                // 插入链接按钮
                Button(action: {
                    showingLinkAlert = true
                }) {
                    Image(systemName: "link")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.colorBrown)
                        .padding(10)
//                        .background(Color(UIColor.systemGray6))
//                        .cornerRadius(5)
                }
                .alert("插入連結", isPresented: $showingLinkAlert) {
                    TextField("連結網址", text: $linkURL)
                    Button("確認", action: insertLink)
                    Button("取消", role: .cancel) { }
                } message: {
                    Text("請輸入要插入的連結")
                }
                
                // 录音按钮
                Button(action: {
                    showingAudioSheet = true
                }) {
                    Image(systemName: "mic.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.colorBrown)
                        .padding(10)
//                        .background(Color(UIColor.systemGray6))
//                        .cornerRadius(5)
                }
                .sheet(isPresented: $showingAudioSheet) {
                    RecordingSheet(
                        audioRecorder: audioRecorder,
                        richText: $richText,
                        isRecording: $isRecording,
                        isPlaying: $isPlaying,
                        uploadedAudioURL: $uploadedAudioURL
                    )
                }
                Spacer()
                // 保存按钮
                SaveButtonView(
                    userID: userID,
                    selectedCoordinate: selectedCoordinate,
                    selectedLocationName: selectedLocationName,
                    selectedCategory: selectedCategory,
                    isPublic: isPublic,
                    contents: richText,
                    errorMessage: $errorMessage,
                    onSave: resetFields
                )
                
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            
            
            .onAppear(perform: subscribeToKeyboardEvents)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // 订阅键盘事件
    func subscribeToKeyboardEvents() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardSize.height
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
        }
    }
    
//    // 调整富文本编辑器高度
//    func adjustRichTextHeight() {
//        DispatchQueue.main.async {
//            let maxHeight = UIScreen.main.bounds.height / 2
//            let newHeight = richText.size().height + 20
//            richTextHeight = min(max(newHeight, 300), maxHeight)
//        }
//    }
    
    // 將選擇的多媒體顯示在富文本編輯器中
    func displayMediaInRichTextEditor(urls: [URL]) {
        for url in urls {
            let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType

            if contentType?.conforms(to: .image) == true {
                // 先將圖片加入到選取的媒體項目
                selectedMediaItems.append((url: url, type: "image"))
                // 插入圖片到富文本編輯器
                insertImageToRichTextEditor(from: url)
            } else if contentType?.conforms(to: .audiovisualContent) == true {
                // 先將影片加入到選取的媒體項目
                selectedMediaItems.append((url: url, type: "video"))
                // 插入影片到富文本編輯器
                insertVideoToRichTextEditor(from: url)
            } else if contentType?.conforms(to: .livePhoto) == true {
                // 先將 livePhoto 加入到選取的媒體項目
                selectedMediaItems.append((url: url, type: "livePhoto"))
                // 這裡可以根據需要處理 livePhoto，或者和影片相同處理
                insertVideoToRichTextEditor(from: url) // 或者你可以新增專門處理 livePhoto 的方法
            }
        }
    }
        // 保存圖片和影片到 Firebase Storage
//        func saveMediaToFirebase() {
//            let storageRef = Storage.storage().reference()
//
//            for mediaItem in selectedMediaItems {
//                let fileName = UUID().uuidString
//                let mediaRef: StorageReference
//
//                if mediaItem.type == "image" {
//                    mediaRef = storageRef.child("user_media/\(userID)/images/\(fileName).jpg")
//                } else if mediaItem.type == "video" {
//                    mediaRef = storageRef.child("user_media/\(userID)/videos/\(fileName).mp4")
//                } else if mediaItem.type == "livePhoto" {
//                    mediaRef = storageRef.child("user_media/\(userID)/livePhotos/\(fileName).mov")  // 儲存 Live Photo
//                }
//
//                // 將多媒體上傳到 Firebase Storage
//                do {
//                    let data = try Data(contentsOf: mediaItem.url)
//                    mediaRef.putData(data, metadata: nil) { metadata, error in
//                        if let error = error {
//                            print("上傳失敗: \(error.localizedDescription)")
//                        } else {
//                            mediaRef.downloadURL { url, error in
//                                if let error = error {
//                                    print("獲取下載連結失敗: \(error.localizedDescription)")
//                                } else if let downloadURL = url {
//                                    // 在此處將下載連結儲存到 Firestore
//                                    saveDownloadLinkToFirestore(url: downloadURL)
//                                }
//                            }
//                        }
//                    }
//                } catch {
//                    print("無法讀取文件數據: \(error.localizedDescription)")
//                }
//            }
//        }
    
    func processMediaURLs(_ urls: [URL]) {
            for url in urls {
                let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType

                if contentType?.conforms(to: .image) == true {
                    insertImageToRichTextEditor(from: url)
                } else if contentType?.conforms(to: .audiovisualContent) == true {
                    insertVideoToRichTextEditor(from: url)
                }
            }
        }

    func insertImageToRichTextEditor(from url: URL) {
        guard let image = UIImage(contentsOfFile: url.path) else { return }
        
        let maxWidth: CGFloat = 200 // 設置圖片最大寬度
        let aspectRatio = image.size.width / image.size.height
        let targetHeight = maxWidth / aspectRatio
        
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: targetHeight) // 設置縮小的圖片尺寸
        
        let attributedString = NSAttributedString(attachment: attachment)
        let mutableRichText = NSMutableAttributedString(attributedString: richText)
        mutableRichText.append(attributedString)
        richText = mutableRichText // 更新 richText 變量
    }

    func insertVideoToRichTextEditor(from url: URL) {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        if let cgImage = try? assetImageGenerator.copyCGImage(at: time, actualTime: nil) {
            let thumbnail = UIImage(cgImage: cgImage)
            
            let maxWidth: CGFloat = 200 // 設置影片預覽最大寬度
            let aspectRatio = thumbnail.size.width / thumbnail.size.height
            let targetHeight = maxWidth / aspectRatio
            
            let attachment = NSTextAttachment()
            attachment.image = thumbnail
            attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: targetHeight) // 設置縮小的影片縮圖尺寸
            
            let attributedString = NSAttributedString(attachment: attachment)
            let mutableRichText = NSMutableAttributedString(attributedString: richText)
            mutableRichText.append(attributedString)
            richText = mutableRichText // 更新 richText 變量
        }
    }


        func playVideo(url: URL) {
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(playerViewController, animated: true) {
                    player.play()
                }
            }
        }
    
    // 插入圖片或影片到富文本
//    func insertMedia(_ url: URL, mediaType: String) {
//        let editor = RichTextEditorView(text: $richText)
//        if mediaType == "image" {
//            if let image = UIImage(contentsOfFile: url.path) {
//                editor.insertImage(image)
//            }
//        } else if mediaType == "video" {
//            editor.insertVideoPreview(from: url)
//        }
//    }

    
    // 插入链接到富文本
    func insertLink() {
        guard let url = URL(string: linkURL) else { return }
        let editor = RichTextEditorView(text: $richText, onVideoTapped: { _ in })
        editor.insertLinkPreview(url: url)
        linkURL = ""
    }
    
    // 重置所有字段
    func resetFields() {
        if let audioURL = audioRecorder.recordingURL {
            do {
                try FileManager.default.removeItem(at: audioURL)
                print("音訊檔案已成功刪除：\(audioURL)")
            } catch {
                print("無法刪除音訊檔案：\(error.localizedDescription)")
            }
        }
        
        richText = NSAttributedString(string: "")
        selectedCategory = categories.first ?? "未分類"
        selectedCoordinate = nil
        selectedLocationName = "未知地點"
        isPublic = true
        errorMessage = nil
        audioRecorder.recordingURL = nil
        isRecording = false
        isPlaying = false
    }
}
