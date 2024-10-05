import SwiftUI
import FirebaseAuth
import FirebaseStorage
import Kingfisher
import AuthenticationServices

struct SettingsPage: View {
    // MARK: - State Properties
    
    @AppStorage("log_Status") private var logStatus: Bool = false
    @State private var userName: String = "Loading..."
    @State private var newUserName: String = ""
    @State private var isEditingName: Bool = false
    
    @State private var characterName: String = "Loading..."
    @State private var newCharacterName: String = ""
    @State private var showCharacterAlert: Bool = false
    
    @State private var selectedProfileImage: UIImage?
    @State private var userProfileImageUrl: URL?
    @State private var isProfilePhotoPickerPresented: Bool = false
    
    @State private var selectedBackgroundImage: UIImage?
    @State private var backgroundImageUrl: URL?
    @State private var isBackgroundPhotoPickerPresented: Bool = false
    @State private var isRemoveBackgroundEnabled: Bool = false
    
    @State private var showActionSheet: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var errorMessage: String = ""
    
    @FocusState private var isNameFocused: Bool

    
    // MARK: - Services and References
    
    private let firestoreService = FirestoreService()
    private let storageRef = Storage.storage().reference()
    private let uid = Auth.auth().currentUser!.uid
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 背景圆角矩形
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(Color(hex: "#FFF7EF"))
                .frame(height: UIScreen.main.bounds.height * 0.75)
                .offset(y: UIScreen.main.bounds.height * 0.2)
            
            VStack(spacing: 0) {
                // 个人信息区域
                profileSection
                
                // 水豚图片
                Image("capybaraRight")
                    .resizable()
                    .frame(width: 60, height: 40)
                    .offset(x: -120, y: 10)
                
                // 设置选项
                ScrollView {
                    settingsOptions
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
            }
            .alert("确认要删除帐号吗？", isPresented: $showDeleteAccountAlert) {
                Button("确认", role: .destructive) {
                    Task {
                        let success = await deleteAccount()
                        if success {
                            logStatus = false
                        }
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("这个操作无法还原，帐号和所有数据将永久删除。")
            }
        }
        .navigationTitle("设定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isProfilePhotoPickerPresented) {
            PhotoPicker(image: $selectedProfileImage)
        }
        .onChange(of: selectedProfileImage) { newImage in
            if let newImage = newImage {
                uploadProfileImageToStorage(image: newImage)
            }
        }
        .sheet(isPresented: $isBackgroundPhotoPickerPresented) {
            PhotoPicker(image: $selectedBackgroundImage)
        }
        .onChange(of: selectedBackgroundImage) { newImage in
            if let newImage = newImage {
                uploadBackgroundImageToStorage(image: newImage)
            }
        }
        .alert("修改角色名字", isPresented: $showCharacterAlert) {
            TextField("输入新角色名字", text: $newCharacterName)
            Button("确认", action: updateCharacterName)
            Button("取消", role: .cancel) {}
        } message: {
            Text("请输入新的角色名字")
        }
        .onAppear {
            fetchUserNameAndProfileImage()
        }
    }
    
    // MARK: - Subviews
    
    private var profileSection: some View {
        VStack {
            // 头像按钮
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
                ActionSheet(title: Text("选择操作"), buttons: [
                    .default(Text("更换大头贴")) {
                        isProfilePhotoPickerPresented = true
                    },
                    .destructive(Text("删除大头贴")) {
                        removeProfileImage()
                    },
                    .cancel()
                ])
            }
            .padding(.bottom, 10)
            
            // 用户名和编辑按钮
            HStack {
                if isEditingName {
                    TextField("输入名字", text: $newUserName)
                        .padding(10)
                        .background(Color.clear)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .submitLabel(.done)
                        .padding(.horizontal)
                        .focused($isNameFocused)
                        .onSubmit {
                            saveUserName()
                            isEditingName = false
                        }
                        .onChange(of: isNameFocused) { focused in
                            if !focused {
                                saveUserName()
                                isEditingName = false
                            }
                        }
                } else {
                
                        Text(userName)
                            .font(.headline)
                            .foregroundColor(Color(hex: "#522504"))
                            .multilineTextAlignment(.center)
                    }
                
                if !isEditingName {
                    Button(action: {
                        isEditingName = true
                        newUserName = userName
                        isNameFocused = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }
                    // 调整铅笔图标的位置，使其不影响文本居中
                    .offset(x: 80, y: 0) // 根据需要调整 x 和 y 值
                }
            }

            .padding(.bottom, 5)
            
            // 角色名字
            Text(characterName)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 40)
    }
    
    private var settingsOptions: some View {
        VStack(spacing: 10) {
            // 更换背景按钮
            SettingsButton(iconName: "photo.on.rectangle", text: "更换背景") {
                isBackgroundPhotoPickerPresented = true
            }
            
            // 移除背景按钮
            SettingsButton(iconName: "trash", text: "移除背景图") {
                isRemoveBackgroundEnabled = true
                removeBackgroundImage()
            }
            
            // 登出按钮
            SettingsButton(iconName: "arrow.right.square", text: "登出") {
                try? Auth.auth().signOut()
                UserDefaults.standard.removeObject(forKey: "userID")
                logStatus = false
            }
            
            FavoriteButton()
            
            // 更改角色名称按钮
            SettingsButton(iconName: "capybaraIcon", text: "更改角色名称") {
                showCharacterAlert = true
            }
            
            // 删除帐号按钮
            SettingsButton(iconName: "trash.circle", text: "删除帐号") {
                showDeleteAccountAlert = true
            }
        }
    }
    
    // MARK: - Functions
    
    private func saveUserName() {
        guard !newUserName.isEmpty else { return }
        firestoreService.updateUserName(uid: uid, name: newUserName)
        userName = newUserName
        isEditingName = false
    }
    
    private func updateCharacterName() {
        guard !newCharacterName.isEmpty else { return }
        firestoreService.updateUserCharacterName(uid: uid, characterName: newCharacterName)
        characterName = newCharacterName
    }
    
    private func uploadProfileImageToStorage(image: UIImage) {
        let imageName = UUID().uuidString
        let imagePath = "user_images/\(uid)/profile/\(imageName).jpg"
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let storagePath = storageRef.child(imagePath)
        storagePath.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("上传头像失败: \(error.localizedDescription)")
                return
            }
            storagePath.downloadURL { url, error in
                if let error = error {
                    print("获取头像下载 URL 失败: \(error.localizedDescription)")
                    return
                }
                if let downloadURL = url {
                    firestoreService.updateUserProfileImage(uid: uid, imageUrl: downloadURL.absoluteString)
                    self.userProfileImageUrl = downloadURL
                }
            }
        }
        selectedProfileImage = nil
    }
    
    private func uploadBackgroundImageToStorage(image: UIImage) {
        let imageName = UUID().uuidString
        let imagePath = "background_images/\(uid)/\(imageName).jpg"
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let storagePath = storageRef.child(imagePath)
        storagePath.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("上传背景图片失败: \(error.localizedDescription)")
                return
            }
            storagePath.downloadURL { url, error in
                if let error = error {
                    print("获取下载背景图片 URL 失败: \(error.localizedDescription)")
                    return
                }
                if let downloadURL = url {
                    firestoreService.updateUserBackgroundImage(uid: uid, imageUrl: downloadURL.absoluteString)
                    self.backgroundImageUrl = downloadURL
                }
            }
        }
        selectedBackgroundImage = nil
    }
    
    private func removeProfileImage() {
        guard let currentImageUrl = userProfileImageUrl?.absoluteString else {
            print("没有头像可移除。")
            return
        }
        
        firestoreService.removeUserProfileImage(uid: uid, currentImageUrl: currentImageUrl) { success in
            if success {
                self.userProfileImageUrl = nil
                print("大头贴已成功移除")
            } else {
                print("大头贴移除失败")
            }
        }
    }
    
    private func removeBackgroundImage() {
        guard let imageUrl = backgroundImageUrl?.absoluteString else { return }
        
        firestoreService.removeUserBackgroundImage(uid: uid, imageUrl: imageUrl) { success in
            if success {
                self.backgroundImageUrl = nil
                print("背景图片已删除")
            } else {
                print("删除背景图片失败")
            }
        }
    }
    
    private func fetchUserNameAndProfileImage() {
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
    
    private func deleteAccount() async -> Bool {
        guard let user = Auth.auth().currentUser else {
            return false
        }
        guard let lastSignInDate = user.metadata.lastSignInDate else {
            return false
        }
        let needsReauth = !lastSignInDate.isWithinPast(minutes: 5)
        let needsTokenRevocation = user.providerData.contains { $0.providerID == "apple.com" }
        
        do {
            var appleIDCredential: ASAuthorizationAppleIDCredential?
            
            if needsReauth || needsTokenRevocation {
                let signInWithApple = SignInWithApple()
                appleIDCredential = try await signInWithApple()
                
                guard let appleIDToken = appleIDCredential?.identityToken else {
                    print("无法获取身份验证凭证")
                    return false
                }
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("无法序列化身份验证 Token")
                    return false
                }
                
                let nonce = randomNonceString()
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                
                try await user.reauthenticate(with: credential)
            }
            
            if needsTokenRevocation {
                guard let authorizationCode = appleIDCredential?.authorizationCode else {
                    return false
                }
                guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
                    return false
                }
                try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
            }
            
            // 删除 Firestore 中的用户数据
            await deleteUserFromFirestore(uid: user.uid)
            
            // 删除用户帐号
            try await user.delete()
            errorMessage = ""
            print("帳號刪除成功")
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            print("刪除帳號失敗: \(error.localizedDescription)")
            return false
        }
    }
    
    private func deleteUserFromFirestore(uid: String) async {
        firestoreService.deleteUserAccount(uid: uid) { success in
            if success {
                print("Firestore 中的用户数据已删除")
            } else {
                print("删除 Firestore 中的用户数据失败")
            }
        }
    }
    
    // 生成随机字符串
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).compactMap { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode == errSecSuccess {
                    return random
                } else {
                    print("无法生成随机数。SecRandomCopyBytes 失败，错误码 \(errorCode)")
                    return nil
                }
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}

struct FavoriteButton: View {
    var body: some View {
        NavigationLink(destination: FavoritesPage()) {
            HStack {
                Image(systemName: "heart")
                    .foregroundColor(.brown)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                
                Text("收藏")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.brown)
                    .font(.system(size: 16))
            }
            .padding()
            .frame(maxWidth: .infinity)  // 让按钮填满可用宽度
            .background(
                Rectangle()
                    .fill(Color.clear)
                    .cornerRadius(10)
            )
            .contentShape(Rectangle())  // 确保整个区域可点击
        }
    }
}

// MARK: - SettingsButton 视图

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
            .background(Color.clear)
            .cornerRadius(10)
            
        }
        .padding(.vertical, 5)
    }
}
