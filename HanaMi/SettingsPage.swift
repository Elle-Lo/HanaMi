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
        @State private var showActionSheet = false
        @State private var isProfilePhotoPickerPresented = false
        @State private var isBackgroundPhotoPickerPresented = false
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
            // 背景圓弧包裹 ScrollView
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(Color(hex: "#FFF7EF"))
                .frame(height: UIScreen.main.bounds.height * 0.75)  // 設定圓弧高度
                .offset(y: UIScreen.main.bounds.height * 0.2)  // 上移圓弧使它能覆蓋底部
            
            VStack(spacing: 0) {
                // 頭像與名字
                VStack {
                    
                    Button(action: {
                        showActionSheet = true
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
                            Image("userImagePlaceholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 5)
                        }
                    }
                    .actionSheet(isPresented: $showActionSheet) {
                                            ActionSheet(title: Text("選擇操作"), buttons: [
                                                .default(Text("更換大頭貼")) {
                                                    isProfilePhotoPickerPresented = true
                                                },
                                                .destructive(Text("刪除大頭貼")) {
                                                    removeProfileImage()
                                                },
                                                .cancel()
                                            ])
                                        }

                    Text(userName)
                        .font(.headline)
                        .foregroundColor(Color(hex: "#522504"))
                    
                    Text(characterName)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                .padding(.top, 40)

                // Capybara 圖片，站在圓弧上
                Image("capybaraRight")
                    .resizable()
                    .frame(width: 60, height: 40)
                    .offset(x: -120, y: 10)  // 調整 Capybara 的位置
                
                ScrollView {
                    VStack(spacing: 10) {
                        // 更換背景按鈕
                        SettingsButton(iconName: "photo.on.rectangle", text: "更換背景") {
                            isBackgroundPhotoPickerPresented = true
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
                        
                        // 收藏按鈕
                        NavigationLink(destination: FavoritesPage()) {
                            SettingsButton(iconName: "heart", text: "收藏") {
                            }
                        }

                        // 角色按鈕
                        Button(action: {
                            showCharacterAlert = true
                        }) {
                            SettingsButton(iconName: "hare", text: "更改角色名稱") {
                                showCharacterAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isProfilePhotoPickerPresented, onDismiss: {
                   // 在这里无需清空 selectedProfileImage，因为我们需要在 .onChange 中获取它的值
               }) {
                   PhotoPicker(image: $selectedProfileImage)
               }
               // 监听 selectedProfileImage 的变化
               .onChange(of: selectedProfileImage) { newImage in
                   if let newImage = newImage {
                       uploadProfileImageToStorage(image: newImage)
                   }
               }
                // 背景圖片選擇器的 sheet
               .sheet(isPresented: $isBackgroundPhotoPickerPresented, onDismiss: {
                          // 同样，这里无需清空 selectedBackgroundImage
                      }) {
                          PhotoPicker(image: $selectedBackgroundImage)
                      }
                      // 监听 selectedBackgroundImage 的变化
                      .onChange(of: selectedBackgroundImage) { newImage in
                          if let newImage = newImage {
                              uploadBackgroundImageToStorage(image: newImage)
                          }
                      }

        
        .alert("修改角色名字", isPresented: $showCharacterAlert, actions: {
            TextField("輸入新角色名字", text: $newCharacterName)
            Button("確認", action: updateCharacterName)
            Button("取消", role: .cancel, action: {})
        }, message: {
            Text("請輸入新的角色名字")
        })
        .onAppear {
            fetchUserNameAndProfileImage()
        }
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
    }

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
            storagePath.downloadURL { url, error in
                if let error = error {
                    print("獲取頭像下載 URL 失敗: \(error.localizedDescription)")
                    return
                }
                if let downloadURL = url {
                    firestoreService.updateUserProfileImage(uid: uid, imageUrl: downloadURL.absoluteString)
                    self.userProfileImageUrl = downloadURL
                }
            }
        }
        selectedProfileImage = nil
//        isSelectingProfileImage = false
    }

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
            storagePath.downloadURL { url, error in
                if let error = error {
                    print("獲取下載背景圖片 URL 失敗: \(error.localizedDescription)")
                    return
                }
                if let downloadURL = url {
                    firestoreService.updateUserBackgroundImage(uid: uid, imageUrl: downloadURL.absoluteString)
                    self.backgroundImageUrl = downloadURL
                }
            }
        }
        selectedBackgroundImage = nil
//        isSelectingBackgroundImage = false
    }

    
    func removeProfileImage() {
        guard let currentImageUrl = userProfileImageUrl?.absoluteString else {
            print("No profile image to remove.")
            return
        }
        
        firestoreService.removeUserProfileImage(uid: uid, currentImageUrl: currentImageUrl) { success in
            if success {
                self.userProfileImageUrl = nil  // 清除 UI 上的圖片
                print("大頭貼已成功移除")
            } else {
                print("大頭貼移除失敗")
            }
        }
    }

    func removeBackgroundImage() {
        guard let imageUrl = backgroundImageUrl?.absoluteString else { return }
        
        firestoreService.removeUserBackgroundImage(uid: uid, imageUrl: imageUrl) { success in
            if success {
                self.backgroundImageUrl = nil  // UI 更新，移除背景圖片
                print("背景圖片已刪除")
            } else {
                print("刪除背景圖片失敗")
            }
        }
    }


    func fetchUserNameAndProfileImage() {
        firestoreService.fetchUserData(uid: uid) { name, profileImageUrl, backgroundImageUrl, characterName in
            self.userName = name ?? "No name"
            if let profileImageUrlString = profileImageUrl, let url = URL(string: profileImageUrlString) {
                self.userProfileImageUrl = url
            }
            if let backgroundImageUrlString = backgroundImageUrl, let url = URL(string: backgroundImageUrlString) {
                self.backgroundImageUrl = url
            }
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

