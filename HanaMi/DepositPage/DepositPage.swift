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
    @State private var categories: [String] = ["Creative", "Technology", "Health", "Education"]
    @State private var selectedCategory: String = "Creative"
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String? = "未知地點"
    @State private var shouldZoomToUserLocation: Bool = true
    @State private var errorMessage: String?
    @State private var activeSheet: ActiveSheet? = nil
    @State private var richText: NSAttributedString = NSAttributedString(string: "")
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingLinkAlert = false
    @State private var linkURL = ""
    @State private var linkDisplayText = ""
    
    @State private var showingAudioSheet = false
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording: Bool = false
    @State private var isPlaying: Bool = false
    @State private var uploadedAudioURL: URL?
    
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchViewModel = LocationSearchViewModel()
    
    @State private var richTextHeight: CGFloat = 300
    @State private var keyboardHeight: CGFloat = 0
    
    let userID = "g61HUemIJIRIC1wvvIqa"
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    ToggleButton(isPublic: $isPublic)
                    CategorySelectionView(selectedCategory: $selectedCategory, categories: $categories, userID: userID)
                }
                .padding(.horizontal)
                
                LocationSelectionView(
                    selectedCoordinate: $selectedCoordinate,
                    selectedLocationName: $selectedLocationName,
                    shouldZoomToUserLocation: $shouldZoomToUserLocation,
                    locationManager: locationManager,
                    searchViewModel: searchViewModel
                )
                
                ScrollView {
                    VStack {
                        
                        RichTextEditorView(text: $richText)
                            .background(Color.clear)
                            .frame(height: richTextHeight)
                            .padding(.horizontal)
                            .onAppear {
                                adjustRichTextHeight()
                            }
                            .padding(.bottom, keyboardHeight)
                        
                        HStack {
                            
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
                                TextField("顯示文字", text: $linkDisplayText)
                                Button("確認", action: insertLink)
                                Button("取消", role: .cancel) { }
                            }
                            
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
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .onAppear(perform: subscribeToKeyboardEvents)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    
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
    
    
    func adjustRichTextHeight() {
        DispatchQueue.main.async {
            let maxHeight = UIScreen.main.bounds.height / 2
            let newHeight = richText.size().height + 20
            richTextHeight = min(max(newHeight, 300), maxHeight)
        }
    }
    
    func insertImage(_ image: UIImage) {
        let editor = RichTextEditorView(text: $richText)
        editor.insertImage(image)
    }
    
    func insertLink() {
        guard let url = URL(string: linkURL), !linkDisplayText.isEmpty else { return }
        let editor = RichTextEditorView(text: $richText)
        editor.insertLinkBlock(url, displayText: linkDisplayText)
        linkURL = ""
        linkDisplayText = ""
    }
    
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
        selectedCategory = "Creative"
        selectedCoordinate = nil
        selectedLocationName = "未知地點"
        isPublic = true
        errorMessage = nil
        audioRecorder.recordingURL = nil
        isRecording = false
        isPlaying = false
    }
}
