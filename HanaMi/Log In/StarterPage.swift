import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

struct StarterPage: View {
    @State private var errorMessge: String = ""
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var nonce: String?
    @State private var showSmallSheet = false // 控制小型 sheet 的顯示
    @AppStorage("log_Status") private var logStatus: Bool = false
    
    var body: some View {
        if logStatus {
            MainTabView()
        } else {
            VStack(spacing: 20) {
                Text("Welcome")
                    .font(.largeTitle)
                    .foregroundColor(Color(hex: "#522504"))
                    .padding()
                Image("Cat")
                    .resizable()
                    .frame(width: 200, height: 220)
                    .scaledToFit()
                
                NavigationLink(destination: LogInPage()) {
                    Text("LOG IN")
                        .foregroundColor(Color(hex: "#522504"))
                        .padding()
                        .frame(width: 250, height: 50)
                        .background(Color(hex: "#FFF7EF"))
                        .cornerRadius(25)
                }
                
                // 其他登入方式按鈕
                Button(action: {
                    showSmallSheet.toggle() // 點擊時顯示小型 sheet
                }) {
                    Text("Other login methods")
                        .foregroundColor(Color(hex: "#522504"))
                        .padding()
                        .frame(width: 250, height: 50)
                        .background(Color(hex: "#FFF7EF"))
                        .cornerRadius(25)
                }
                .sheet(isPresented: $showSmallSheet) {
                    // 使用自定義的 small sheet 模仿 ActionSheet 大小
                    VStack {
                        Text("Select a login method")
                            .font(.subheadline) // 字體變小
                            .padding(.top, 10) // 調整字和按鈕間距
                        
                        // 原本的 Sign in with Apple 按鈕，會自動使用預設樣式
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = randomNonceString()
                            self.nonce = nonce
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                loginWithFirebase(authorization)
                            case .failure(let error):
                                showError(error.localizedDescription)
                            }
                        }
                        .frame(width: 250, height: 50)
                        .cornerRadius(25)
                        .padding()
                    }
                    .padding()
                    .presentationDetents([.fraction(0.2)]) // 設定大小接近 ActionSheet
                }

                HStack {
                    Text("Don’t have an account?")
                        .foregroundColor(.gray)
                        .font(.footnote) // 調整字體大小變小
                    NavigationLink(destination: SignUpPage()) {
                        Text("Sign Up")
                            .foregroundColor(Color(hex: "#522504"))
                            .font(.footnote) // 調整字體大小變小
                    }
                }
                .padding(.top, -5) 
            }
            .alert(errorMessge, isPresented: $showAlert) { }
            .overlay {
                if isLoading {
                    LoadingScreen()
                }
            }
        }
    }
    
    @ViewBuilder
    func LoadingScreen() -> some View {
        ZStack {
//            Rectangle()
//                .fill(.ultraThinMaterial)
//                .ignoresSafeArea() // 確保背景充滿整個螢幕
            
            ProgressView()
                .frame(width: 45, height: 45)
//                .background(Color.white.opacity(0.8))
                .cornerRadius(5)
        }
    }

    
    func showError(_ message: String) {
        errorMessge = message
        showAlert.toggle()
        isLoading = false
    }
    
    func loginWithFirebase(_ authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            isLoading = true
            
            guard let nonce else {
                showError("Cannot process your request")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                showError("Cannot process your request")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                showError("Cannot process your request")
                return
            }
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                    showError(error.localizedDescription)
                }
                logStatus = true
                isLoading = false
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    StarterPage()
}
