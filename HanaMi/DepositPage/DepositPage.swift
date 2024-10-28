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
import MusicKit

struct DepositPage: View {
    @State private var isPublic: Bool = true
    @State private var categories: [String] = []
    @State private var selectedCategory: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var shouldZoomToUserLocation: Bool = true
    @State private var showErrorMessage = false
    @State private var errorMessage: String?
    @State private var textContent: String = ""
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var selectedMediaItems: [(url: URL, type: String)] = []
    @State private var isShowingCameraPicker = false
    @State private var isShowingMediaPicker = false
    @State private var mediaURLs: [URL] = []
    @State private var mediaType: ImagePicker.MediaType?
    @State private var cameraMediaURL: URL?
    @State private var isShowingActionSheet = false
    
    @State private var showingLinkAlert = false
    @State private var linkURL = ""
    
    @State private var customAlert = false
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording: Bool = false
    @State private var isPlaying: Bool = false
    @State private var uploadedAudioURL: URL?
    
    @State private var isSaveAnimationPlaying: Bool = false
    @State private var isSaving: Bool = false
    
    @State private var isShowingMusicPicker = false
    @State private var searchTerm = ""
    @State private var musicResults: [Song] = []
    @State private var selectedMusic: Song?
    
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
            
            Color(.colorGrayBlue)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TopControlsView(isPublic: $isPublic, selectedCategory: $selectedCategory, categories: $categories, userID: userID)
                    
                    LocationSelectionView(
                        selectedCoordinate: $selectedCoordinate,
                        selectedLocationName: $selectedLocationName,
                        shouldZoomToUserLocation: $shouldZoomToUserLocation,
                        locationManager: locationManager,
                        searchViewModel: searchViewModel,
                        userID: userID
                    )
                    
                    MediaScrollView(selectedMediaItems: $selectedMediaItems)
                    
                    PlaceholderTextEditor(text: $textContent, placeholder: "一個故事、一場經歷、一個情緒 \n任何想紀錄的事情都寫下來吧～")
                        .lineSpacing(10)
                        .frame(height: 150)
                        .padding(.horizontal, 15)
                        .background(Color.clear)
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 15)
            
            VStack {
                
                Spacer()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.gray)
                        .font(.custom("LexendDeca-SemiBold", size: 11))
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                HStack {
                    
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
                    
                    .sheet(isPresented: $isShowingCameraPicker) {
                        ImagePicker(mediaURL: $cameraMediaURL, mediaType: $mediaType, sourceType: .camera)
                            .edgesIgnoringSafeArea(.all)
                            .onDisappear {
                                if let cameraMediaURL = cameraMediaURL, let mediaType = mediaType {
                                    handlePickedMedia(urls: [cameraMediaURL], mediaType: mediaType)
                                }
                            }
                    }
                    
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
                    
                    Button(action: {
                        isShowingMusicPicker = true
                    }) {
                        Image(systemName: "music.note")
                            .font(.system(size: 22))
                            .foregroundColor(.colorBrown)
                            .padding(10)
                    }
                    .sheet(isPresented: $isShowingMusicPicker) {
                        MusicSearchView(searchTerm: $searchTerm, musicResults: $musicResults, onMusicSelected: { musicItem in
                            if let musicURL = musicItem.url {
                                
                                self.selectedMediaItems.append((url: musicURL, type: "music"))
                            }
                            isShowingMusicPicker = false
                        })
                    }
                    .presentationDetents([.height(650), .large])
                    
                    if let selectedMusic = selectedMusic {
                        Text("Selected Song: \(selectedMusic.title)")
                            .padding()
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
                            showErrorMessage = false
                            isSaveAnimationPlaying = true
                            isSaving = true
                        }
                    )
                    .opacity(canSave ? 1 : 0.5)
                    .disabled(isSaving)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(Color.clear)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            if isSaveAnimationPlaying {
                LottieView(animationFileName: "flying", isPlaying: $isSaveAnimationPlaying)
                    .frame(width: 300, height: 300)
                    .scaleEffect(0.2)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isSaveAnimationPlaying = false
                        }
                    }
                    .zIndex(1)
            }
            
            if customAlert {
                Color.black.opacity(0.4).ignoresSafeArea()
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2.5)
            }
        }
        .onAppear {
            
            if let firstCategory = categories.first {
                selectedCategory = firstCategory
            } else {
                selectedCategory = "未分類"
            }
        }
        .onChange(of: categories) { newCategories in
            
            if let firstCategory = newCategories.first {
                selectedCategory = firstCategory
            } else {
                selectedCategory = "未分類"
            }
        }
    }
    
    func handlePickedMedia(urls: [URL], mediaType: ImagePicker.MediaType?) {
        for url in urls {
            
            do {
                let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
                
                if let contentType = resourceValues.contentType {
                    if contentType.conforms(to: .image) {
                        
                        selectedMediaItems.append((url: url, type: "image"))
                    } else if contentType.conforms(to: .audiovisualContent) {
                        
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
    
    func insertLink() {
        guard let url = URL(string: linkURL) else { return }
        selectedMediaItems.append((url: url, type: "link"))
        linkURL = ""
    }
    
    func deleteMediaItem(at offsets: IndexSet) {
        selectedMediaItems.remove(atOffsets: offsets)
    }
    
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
        selectedMediaItems.removeAll()
        DispatchQueue.main.async {
            isSaving = false
        }
    }
}

struct PlaceholderTextEditor: View {
    @FocusState private var keyboardFocused: Bool
    @Binding var text: String
    var placeholder = ""
    
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
