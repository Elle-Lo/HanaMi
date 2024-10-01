import SwiftUI
import FirebaseAuth
import FirebaseStorage
import Kingfisher

struct SettingsPage: View {
    @AppStorage("log_Status") private var logStatus: Bool = false
    @State private var userName: String = "Loading..."
    @State private var selectedProfileImage: UIImage?
    @State private var userProfileImageUrl: URL?
    @State private var backgroundImageUrl: URL?
    @State private var selectedBackgroundImage: UIImage?
    @State private var isPhotoPickerPresented = false
    @State private var isSelectingProfileImage = false
    @State private var isSelectingBackgroundImage = false
    @State private var isRemoveBackgroundEnabled = false
    private let firestoreService = FirestoreService()
    private let storageRef = Storage.storage().reference()
    private let uid = Auth.auth().currentUser!.uid  // 直接获取 uid

    var body: some View {
        ZStack {
            // 背景图片
            if let backgroundImageUrl = backgroundImageUrl {
                KFImage(backgroundImageUrl)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            }

            ScrollView {
                VStack(spacing: 0) {
                    // 头像和名字部分
                    VStack {
                        Button(action: {
                            isSelectingProfileImage = true
                            isPhotoPickerPresented = true
                        }) {
                            if let profileImageUrl = userProfileImageUrl {
                                KFImage(profileImageUrl)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 5)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 100, height: 100)
                                    .overlay(Text("T").font(.largeTitle).foregroundColor(.white))
                            }
                        }
                        .onChange(of: selectedProfileImage) { newImage in
                            if let newImage = newImage {
                                uploadProfileImageToStorage(image: newImage)
                            }
                        }

                        Text(userName)
                            .font(.headline)
                            .padding(.top, 5)
                    }
                    .padding(.top, 40)

                    // 其他设置按钮

                    // 更换背景按钮
                    SettingsButton(iconName: "photo.on.rectangle", text: "更換背景") {
                        isSelectingBackgroundImage = true
                        isPhotoPickerPresented = true
                    }
                    .onChange(of: selectedBackgroundImage) { newImage in
                        if let newImage = newImage {
                            uploadBackgroundImageToStorage(image: newImage)
                        }
                    }

                    // 移除背景按钮
                    SettingsButton(iconName: "trash", text: "移除背景圖") {
                        isRemoveBackgroundEnabled = true
                        removeBackgroundImage()
                    }

                    // 登出按钮
                    SettingsButton(iconName: "arrow.right.square", text: "登出") {
                        try? Auth.auth().signOut()
                        UserDefaults.standard.removeObject(forKey: "userID")
                        print("User successfully logged out.")
                        logStatus = false
                    }

                    Spacer()
                }
                .padding(.bottom, 50)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPhotoPickerPresented, onDismiss: {
            // 重置选择标记
            isSelectingProfileImage = false
            isSelectingBackgroundImage = false
        }) {
            if isSelectingProfileImage {
                PhotoPicker(image: $selectedProfileImage)
            } else if isSelectingBackgroundImage {
                PhotoPicker(image: $selectedBackgroundImage)
            }
        }
        .onAppear {
            fetchUserNameAndProfileImage()
        }
    }

    // 上传头像到 Firebase Storage
    func uploadProfileImageToStorage(image: UIImage) {
        let imageName = UUID().uuidString
        let imagePath = "user_images/\(uid)/profile/\(imageName).jpg"
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let storagePath = storageRef.child(imagePath)

        storagePath.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("上傳頭像失敗: \(error.localizedDescription)")
                return
            }

            // 获取下载 URL 并保存到 Firestore
            storagePath.downloadURL { url, error in
                if let error = error {
                    print("獲取頭像下載 URL 失敗: \(error.localizedDescription)")
                    return
                }

                if let downloadURL = url {
                    // 更新 Firestore 中的 userImage 字段
                    firestoreService.updateUserProfileImage(uid: uid, imageUrl: downloadURL.absoluteString)

                    // 更新界面显示
                    self.userProfileImageUrl = downloadURL
                }
            }
        }

        // 重置状态
        selectedProfileImage = nil
        isSelectingProfileImage = false
    }

    // 上传背景图片到 Firebase Storage
    func uploadBackgroundImageToStorage(image: UIImage) {
        let imageName = UUID().uuidString
        let imagePath = "background_images/\(uid)/\(imageName).jpg"
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let storagePath = storageRef.child(imagePath)

        storagePath.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("上傳背景圖片失敗: \(error.localizedDescription)")
                return
            }

            // 获取下载 URL 并保存到 Firestore
            storagePath.downloadURL { url, error in
                if let error = error {
                    print("獲取下載背景圖片 URL 失敗: \(error.localizedDescription)")
                    return
                }

                if let downloadURL = url {
                    // 更新 Firestore 中的 backgroundImage 字段
                    firestoreService.updateUserBackgroundImage(uid: uid, imageUrl: downloadURL.absoluteString)

                    // 更新界面显示
                    self.backgroundImageUrl = downloadURL
                }
            }
        }

        // 重置状态
        selectedBackgroundImage = nil
        isSelectingBackgroundImage = false
    }

    // 移除背景图片
    func removeBackgroundImage() {
        firestoreService.updateUserBackgroundImage(uid: uid, imageUrl: "")
        self.backgroundImageUrl = nil
        print("背景圖片已移除！")
    }

    // 从 Firestore 加载用户名字和头像/背景 URL
    func fetchUserNameAndProfileImage() {
        firestoreService.fetchUserNameAndProfileImage(uid: uid) { name, profileImageUrl, backgroundImageUrl in
            self.userName = name ?? "No name"
            if let profileImageUrlString = profileImageUrl, let url = URL(string: profileImageUrlString) {
                self.userProfileImageUrl = url
            }
            if let backgroundImageUrlString = backgroundImageUrl, let url = URL(string: backgroundImageUrlString) {
                self.backgroundImageUrl = url
            }
        }
    }
}



struct SettingsButton: View {
    var iconName: String
    var text: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(Color.brown)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                
                Text(text)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.brown)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(.vertical, 5)
    }
}

