import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

struct StarterPage: View {
    @State private var errorMessge: String = ""
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var nonce: String?
    @State private var showSmallSheet = false
    @AppStorage("log_Status") private var logStatus: Bool = false
    
    var body: some View {
        if logStatus {
            MainTabView()
        } else {
            VStack(spacing: 10) {
               
                Text("HanaMi")
                    .font(.custom("LexendDeca-SemiBold", size: 30))
                    .foregroundColor(Color(hex: "#522504"))
                    .padding(.bottom, 30)
                
                Image("capybaraLeft")
                    .resizable()
                    .frame(width: 200, height: 150)
                    .scaledToFit()
                    .padding(.bottom, 30)
                
                NavigationLink(destination: LogInPage()) {
                    Text("LOG IN")
                        .foregroundColor(Color(hex: "#522504"))
                        .font(.custom("LexendDeca-Regular", size: 18))
                        .padding()
                        .frame(width: 250, height: 50)
                        .background(Color(hex: "#FFF7EF"))
                        .cornerRadius(25)
                }
                .padding(.bottom, 10)
                
                Button(action: {
                    showSmallSheet.toggle()
                }) {
                    Text("OTHER LOGIN METHODS")
                        .foregroundColor(Color(hex: "#522504"))
                        .font(.custom("LexendDeca-Regular", size: 15))
                        .padding()
                        .frame(width: 250, height: 50)
                        .background(Color(hex: "#FFF7EF"))
                        .cornerRadius(25)
                }
                .sheet(isPresented: $showSmallSheet) {
                 
                    VStack {
                        Text("Select a login method")
                            .font(.subheadline)
                            .padding(.top, 10)
                        
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
                    .presentationDetents([.fraction(0.2)])
                }

                HStack {
                    Text("Don’t have an account?")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    NavigationLink(destination: SignUpPage()) {
                        Text("Sign Up")
                            .foregroundColor(Color(hex: "#522504"))
                            .font(.footnote)
                            .fontWeight(.bold)
                    }
                }
                .padding(.top, 5)
                
                Button(action: openEULA) {
                    Text("End User License Agreement (EULA)")
                        .underline()
                        .foregroundColor(.blue)
                        .font(.custom("LexendDeca-Regular", size: 10))
                        .padding(.top, 1)
                }
                
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
            ProgressView()
                .frame(width: 45, height: 45)
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
                if let error = error {
                    showError(error.localizedDescription)
                    return
                }
                
                if let uid = authResult?.user.uid {
                    let email = authResult?.user.email ?? "Unknown email"
                    let fullName = appleIDCredential.fullName?.formatted() ?? "Unknown name"
                    print("Apple Full Name: \(fullName)")
                    createUserInFirestoreIfNeeded(uid: uid, name: fullName, email: email)
                    UserDefaults.standard.set(uid, forKey: "userID")
                }
                
                logStatus = true
                isLoading = false
            }
        }
    }

    func createUserInFirestoreIfNeeded(uid: String, name: String, email: String) {
        let firestoreService = FirestoreService()
        
        firestoreService.checkUserExists(uid: uid) { exists in
            if !exists {
                firestoreService.createUserInFirestore(uid: uid, name: name, email: email)
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
    
    private func openEULA() {
            if let url = URL(string: "https://www.privacypolicies.com/live/dd18a0b6-f1e4-4a93-b142-146fe5b80b6c") {
                UIApplication.shared.open(url)
            }
        }
}

#Preview {
    StarterPage()
}
