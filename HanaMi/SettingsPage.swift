import SwiftUI
import FirebaseAuth
import FirebaseStorage
import Kingfisher
import AuthenticationServices
import IQKeyboardManagerSwift
import Lottie

struct SettingsPage: View {
    // MARK: - State Properties
    
    @AppStorage("log_Status") private var logStatus: Bool = false
    @State private var userName: String = "Ning"
    @State private var newUserName: String = ""
    @State private var isEditingName: Bool = false
    
    @State private var characterName: String = "HanaMi"
    @State private var newCharacterName: String = ""
    @State private var showCharacterAlert: Bool = false
    
    @State private var selectedProfileImage: UIImage?
    @State private var userProfileImageUrl: URL?
    @State private var isProfilePhotoPickerPresented: Bool = false
    
    @State private var selectedBackgroundImage: UIImage?
    @State private var backgroundImageUrl: URL?
    @State private var isBackgroundPhotoPickerPresented: Bool = false
    @State private var isRemoveBackgroundEnabled: Bool = false
    @State private var isPrivacyPolicyPresented = false
    @State private var isLottiePlaying: Bool = false
    
    @State private var showActionSheet: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var showLogOutAccountAlert: Bool = false
    @State private var errorMessage: String = ""
    
    @FocusState private var isNameFocused: Bool
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Services and References
    
    private let firestoreService = FirestoreService()
    private let storageRef = Storage.storage().reference()
    private var uid: String? {
        return Auth.auth().currentUser?.uid
    }
    private var userID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? "Unknown User"
    }
    
    // MARK: - Body
    
    var body: some View {

        ZStack {
            
            ScrollView {
              
                RoundedRectangle(cornerRadius: 60, style: .continuous)
                    .fill(Color.colorYellow)
                    .frame(height: UIScreen.main.bounds.height * 0.75)
                    .offset(y: UIScreen.main.bounds.height * 0.25)
            }
                VStack(spacing: 0) {
                    
                    profileSection
                        .padding(.top, 40)
                    
                    Image("capybaraRight")
                        .resizable()
                        .frame(width: 60, height: 40)
                        .offset(x: -120, y: -20)
                    
                ScrollView {
                    VStack {
                        settingsOptions
                            .padding(.horizontal, 20)
                    }
                }
            }
            .alert("確認要刪除帳號嗎？取消好嗎:)", isPresented: $showDeleteAccountAlert) {
                Button("確認", role: .destructive) {
                    Task {
                        let success = await deleteAccount()
                        if success {
                            logStatus = false
                        }
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("我會很難過～而且這個操作無法還原，帳號和所有數據將永遠刪除。")
            }
            .alert("登出", isPresented: $showLogOutAccountAlert) {
                Button("確認", role: .destructive) {
                    try? Auth.auth().signOut()
                    UserDefaults.standard.removeObject(forKey: "userID")
                    logStatus = false
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("您確認要登出嗎？")
            }
            
            if isLottiePlaying {
                LottieView(animationFileName: "check", isPlaying: $isLottiePlaying)
                    .frame(width: 140, height: 140)
                    .scaleEffect(0.15)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLottiePlaying = false
                        }
                    }
                    .zIndex(1)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.colorBrown)
                }
            }
        }
        .sheet(isPresented: $isProfilePhotoPickerPresented) {
            PhotoPicker(image: $selectedProfileImage)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: selectedProfileImage) { newImage in
            if let newImage = newImage {
                uploadProfileImageToStorage(image: newImage)
            }
        }
        .sheet(isPresented: $isBackgroundPhotoPickerPresented) {
            PhotoPicker(image: $selectedBackgroundImage)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: selectedBackgroundImage) { newImage in
            if let newImage = newImage {
                uploadBackgroundImageToStorage(image: newImage)
            }
        }
        .alert("修改角色名字", isPresented: $showCharacterAlert) {
            TextField("輸入新角色名字", text: $newCharacterName)
            Button("確認", action: updateCharacterName)
            Button("取消", role: .cancel) {}
        } message: {
            Text("請輸入新的角色名字")
        }
        .onAppear {
            fetchUserNameAndProfileImage()
        }
    
}
    
    // MARK: - Subviews
    
    private var profileSection: some View {
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
            .padding(.bottom, 10)
            
            if isEditingName {
                TextField("\(userName)", text: $newUserName, onCommit: {
                    saveUserName()
                })
                .focused($isNameFocused)
                .background(Color.clear)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .onSubmit {
                    saveUserName()
                    isEditingName = false
                }
                .onAppear {
                    newUserName = userName
                    isNameFocused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    if isEditingName {
                        saveUserName()
                        isEditingName = false
                    }
                }
            } else {
                Text(userName)
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(Color(hex: "#522504"))
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        isEditingName = true
                        newUserName = userName
                    }
            }
               
            Text(characterName)
                .font(.custom("LexendDeca-SemiBold", size: 13))
                .foregroundColor(.gray)
                .padding(.top, 2)
                .padding(.bottom, 15)
        }
        
    }
    
    private var settingsOptions: some View {
        VStack(spacing: 10) {
            
            FavoriteButton()
            
            SettingsButton(iconName: "pencil", text: "更換用戶名") {
                isEditingName = true
            }
            
            CharacterButton() {
                showCharacterAlert = true
            }
            
            SettingsButton(iconName: "photo", text: "更換背景") {
                isBackgroundPhotoPickerPresented = true
            }
            
            SettingsButton(iconName: "trash", text: "移除背景圖") {
                isRemoveBackgroundEnabled = true
                removeBackgroundImage()
            }
            
            BlockListButton()
            
            SettingsButton(iconName: "arrow.right.square", text: "登出") {
                showLogOutAccountAlert = true
            }
            
            Divider()
            
            SettingsButton(iconName: "trash.circle", text: "刪除帳號") {
                showDeleteAccountAlert = true
            }
            
            PrivacyPolicyButton()
        }
    }
    
    // MARK: - Functions
    
    private func saveUserName() {
        guard let uid = uid, !newUserName.isEmpty else { return }
        firestoreService.updateUserName(uid: uid, name: newUserName)
        userName = newUserName
        isEditingName = false
    }
    
    private func updateCharacterName() {
        guard let uid = uid, !newCharacterName.isEmpty else { return }
        firestoreService.updateUserCharacterName(uid: uid, characterName: newCharacterName)
        characterName = newCharacterName
    }
    
    private func uploadProfileImageToStorage(image: UIImage) {
        guard let uid = uid else { return }
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
        guard let uid = uid else { return }
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
                    
                    isLottiePlaying = true
                }
            }
        }
        selectedBackgroundImage = nil
    }
    
    private func removeProfileImage() {
        guard let uid = uid, let currentImageUrl = userProfileImageUrl?.absoluteString else {
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
        guard let uid = uid, let imageUrl = backgroundImageUrl?.absoluteString else { return }
        
        firestoreService.removeUserBackgroundImage(uid: uid, imageUrl: imageUrl) { success in
            if success {
                self.backgroundImageUrl = nil
                isLottiePlaying = true
                print("背景图片已删除")
            } else {
                print("删除背景图片失败")
            }
        }
    }
    
    private func fetchUserNameAndProfileImage() {
        guard let uid = uid else { return }
        
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
            
            await deleteUserFromFirestore(uid: user.uid)
            
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

struct CharacterButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image("capybaraIcon")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                    .frame(width: 40)
                
                Text("更換角色名稱")
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorBrown)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 16))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .cornerRadius(10)
            
        }
        .padding(.vertical, 5)
    }
}

struct FavoriteButton: View {
    var body: some View {
        NavigationLink(destination: CollectionsPage()) {
            
            HStack {
                
                Image(systemName: "heart")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                    .frame(width: 40)
                
                Text("收藏")
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorBrown)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.brown)
                    .font(.system(size: 16))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Rectangle()
                    .fill(Color.clear)
                    .cornerRadius(10)
            )
            .contentShape(Rectangle())
        }
    }
}

struct PrivacyPolicyButton: View {
    var body: some View {
        NavigationLink(destination: PrivacyPolicyPage()) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                    .frame(width: 40)

                Text("隱私權政策")
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorBrown)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 16))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .cornerRadius(10)
        }
        .padding(.vertical, 5)
    }
}

struct BlockListButton: View {
    var body: some View {
        NavigationLink(destination: BlockListPage()) {
            HStack {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                    .frame(width: 40)
                
                Text("封鎖列表")
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorBrown)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 16))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .cornerRadius(10)
        }
        .padding(.vertical, 5)
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
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                    .frame(width: 40)
                
                Text(text)
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorBrown)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.colorBrown)
                    .font(.system(size: 16))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .cornerRadius(10)
            
        }
        .padding(.vertical, 5)
    }
}
