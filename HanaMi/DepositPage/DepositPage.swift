import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import MapKit
import CoreLocation
import PhotosUI
import AVFoundation

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
    @State private var showingImagePicker = false
    @State private var showingLinkAlert = false
    @State private var linkURL = ""

    @State private var showingAudioSheet = false
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording: Bool = false
    @State private var isPlaying: Bool = false
    @State private var uploadedAudioURL: URL?

    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchViewModel = LocationSearchViewModel()

    let userID = "g61HUemIJIRIC1wvvIqa"

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
//                VStack {
                    // 富文本编辑器
                    RichTextEditorView(text: $richText)
                        .background(Color.clear)
                        .frame(height: richTextHeight)
                        .padding(.horizontal)
                        .onAppear {
                            adjustRichTextHeight()
                        }
                        .padding(.bottom, keyboardHeight)

                   
//                        Spacer()
//                    }
                    .padding(.horizontal)

                    Spacer()

                    // 错误信息显示
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            .padding(.bottom, 0)
            .scrollIndicators(.hidden)
            
            // 工具栏按钮
            HStack {
                // 插入图片按钮
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(5)
                }
                .sheet(isPresented: $showingImagePicker) {
                    PhotoPicker(image: $selectedImage)
                }
                .onChange(of: selectedImage) { newImage in
                    if let image = newImage {
                        insertImage(image)
                    }
                }

                // 插入链接按钮
                Button(action: {
                    showingLinkAlert = true
                }) {
                    Image(systemName: "link")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(5)
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
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(5)
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

    // 调整富文本编辑器高度
    func adjustRichTextHeight() {
        DispatchQueue.main.async {
            let maxHeight = UIScreen.main.bounds.height / 2
            let newHeight = richText.size().height + 20
            richTextHeight = min(max(newHeight, 300), maxHeight)
        }
    }

    // 插入图片到富文本
    func insertImage(_ image: UIImage) {
        let editor = RichTextEditorView(text: $richText)
        editor.insertImage(image)
    }

    // 插入链接到富文本
    func insertLink() {
        guard let url = URL(string: linkURL) else { return }
        let editor = RichTextEditorView(text: $richText)
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
