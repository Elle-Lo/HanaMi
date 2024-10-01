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
    @State private var showCharacterAlert = false
    @State private var newCharacterName: String = ""
    @State private var characterName: String = "Loading..."
    @State private var isEditingName = false  // 狀態來控制編輯模式
    @State private var newUserName: String = ""
    private let firestoreService = FirestoreService()
    private let storageRef = Storage.storage().reference()
    private let uid = Auth.auth().currentUser!.uid  // 直接获取 uid

    var body: some View {
        ZStack {
            VStack {
                // 頭像和名字部分
                ZStack {
                    Color.white
                        .frame(height: 250) // 固定白色背景區域高度
                        .edgesIgnoringSafeArea(.all)
                    
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
                        
                        HStack {
                            if isEditingName {
                                // 编辑模式：TextField 显示用户可以编辑的名称
                                TextField("輸入新名稱", text: $newUserName)
                                    .background(Color.clear)
                                    .onSubmit {
                                        saveUserName()
                                    }
                                
                                // 完成編輯按鈕
                                Button("完成") {
                                    saveUserName()
                                }
                            } else {
                                // 顯示用戶名稱及編輯圖示
                                Text(userName)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#522504"))
                                
                                // 編輯圖示按鈕
                                Button(action: {
                                    isEditingName.toggle() // 切換到編輯模式
                                    newUserName = userName // 將當前名稱填入編輯框
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 80)
                    }
                    .padding(.top, 40)
                }
                
                ZStack {
                    GeometryReader { geometry in
                        // 圓弧背景
                        RoundedRectangle(cornerRadius: 60, style: .continuous)
                                       .fill(Color(hex: "#FFF7EF"))
                                       .frame(maxHeight: geometry.size.height * 3) // 設定圓弧背景高度
                                       .offset(y: 50)
                            .overlay(
                                ScrollView {
                                    VStack(spacing: 10) {
                                        // 更換背景按鈕
                                        SettingsButton(iconName: "photo.on.rectangle", text: "更換背景") {
                                            isSelectingBackgroundImage = true
                                            isPhotoPickerPresented = true
                                        }
                                        .onChange(of: selectedBackgroundImage) { newImage in
                                            if let newImage = newImage {
                                                uploadBackgroundImageToStorage(image: newImage)
                                            }
                                        }
                                        
                                        // 移除背景按鈕
                                        SettingsButton(iconName: "trash", text: "移除背景圖") {
                                            isRemoveBackgroundEnabled = true
                                            removeBackgroundImage()
                                        }
                                        
                                        // 登出按鈕
                                        SettingsButton(iconName: "arrow.right.square", text: "登出") {
                                            try? Auth.auth().signOut()
                                            UserDefaults.standard.removeObject(forKey: "userID")
                                            logStatus = false
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 30)
                                }
                            )
                        
                        // 收藏和角色按鈕
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(hex: "#F1F1F1"))
                                .frame(width: 250, height: 50)
                            
                            HStack {
                                NavigationLink(destination: FavoritesPage()) {
                                    Text("收藏")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(hex: "#522504"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .background(Color.clear)
                                
                                Button(action: {
                                    showCharacterAlert = true // 顯示角色名字修改警告框
                                }) {
                                    Text("角色")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(hex: "#522504"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .background(Color.clear)
                            }
                        }
                        .frame(width: 250, height: 50)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.01) // 動態調整按鈕位置
                    }
                }
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
                    .alert("修改角色名字", isPresented: $showCharacterAlert, actions: {
                        TextField("輸入新角色名字", text: $newCharacterName)
                        Button("確認", action: updateCharacterName)
                        Button("取消", role: .cancel, action: {})
                    }, message: {
                        Text("請輸入新的角色名字")
                    })
        }
    
    func saveUserName() {
            guard !newUserName.isEmpty else { return }
        firestoreService.updateUserName(uid: uid, name: newUserName)
            userName = newUserName
            isEditingName = false // 結束編輯模式
        }
    
    func updateCharacterName() {
        guard !newCharacterName.isEmpty else { return }

        firestoreService.updateUserCharacterName(uid: uid, characterName: newCharacterName)
        characterName = newCharacterName
        print("角色名字已更新：\(newCharacterName)")
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
        firestoreService.fetchUserData(uid: uid) { name, profileImageUrl, backgroundImageUrl, characterName in
            self.userName = name ?? "No name"
            if let profileImageUrlString = profileImageUrl, let url = URL(string: profileImageUrlString) {
                self.userProfileImageUrl = url
            }
            if let backgroundImageUrlString = backgroundImageUrl, let url = URL(string: backgroundImageUrlString) {
                self.backgroundImageUrl = url
            }
            // Fetch character name and update it
            self.characterName = characterName ?? "No character"
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
                    .foregroundColor(.brown)
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
            .background(Color.clear) // 背景透明
            .cornerRadius(10)
        }
        .padding(.vertical, 5)
    }
}

