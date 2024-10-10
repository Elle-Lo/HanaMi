import SwiftUI
import FirebaseAuth

struct SignUpPage: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible = false // 控制密碼是否可見
    
    @State private var passwordError: String = ""
    @State private var generalErrorMessage: String = "" // 用來顯示 Firebase 錯誤訊息
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("log_Status") private var logStatus: Bool = false // 追蹤登入狀態
    private let firestoreService = FirestoreService() // FirestoreService 實例
    
    var body: some View {
        VStack(spacing: 35) {
            // Name field
            VStack(alignment: .leading, spacing: 15) {
                Text("Name")
                    .foregroundColor(Color(hex: "#522504"))
                    .font(.system(size: 16, weight: .medium))
                
                TextField("", text: $name)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#FFF7EF"), lineWidth: 4))
                    .frame(height: 40)
            }
            
            // Email field
            VStack(alignment: .leading, spacing: 15) {
                Text("Email")
                    .foregroundColor(Color(hex: "#522504"))
                    .font(.system(size: 16, weight: .medium))
                
                TextField("", text: $email)
                    .padding()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .background(RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#FFF7EF"), lineWidth: 4))
                    .frame(height: 40)
                
                if !generalErrorMessage.isEmpty {
                    Text(generalErrorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 15) {
                Text("Password")
                    .foregroundColor(Color(hex: "#522504"))
                    .font(.system(size: 16, weight: .medium))
                
                ZStack(alignment: .trailing) {
                    if isPasswordVisible {
                        TextField("", text: $password) // 顯示明文密碼
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                            )
                            .frame(height: 45)
                    } else {
                        SecureField("", text: $password) // 顯示密文密碼
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                            )
                            .frame(height: 45)
                    }
                    
                    // 眼睛圖示，用來切換顯示或隱藏密碼
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                            .padding(.trailing, 15)
                    }
                }
            }
          
            // Confirm password field
            VStack(alignment: .leading, spacing: 15) {
                Text("Confirm Password")
                    .foregroundColor(Color(hex: "#522504"))
                    .font(.system(size: 16, weight: .medium))
                
                
                ZStack(alignment: .trailing) {
                    if isPasswordVisible {
                        TextField("", text: $confirmPassword) // 顯示明文密碼
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                            )
                            .frame(height: 45)
                    } else {
                        SecureField("", text: $confirmPassword) // 顯示密文密碼
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                            )
                            .frame(height: 45)
                    }
                    
                    // 眼睛圖示，用來切換顯示或隱藏密碼
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                            .padding(.trailing, 15)
                    }
                }
                
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            
            // Register button
            Button(action: {
                validateAndSignUp()
            }) {
                Text("REGISTER")
                    .foregroundColor(isButtonDisabled() ? .white : Color(hex: "#522504"))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(isButtonDisabled() ? Color.gray.opacity(0.5) : Color(hex: "#FFF7EF"))
                    .cornerRadius(25)
            }
            .padding(.top, 20)
            .disabled(isButtonDisabled()) // Disable button if any errors or fields are empty
        }
        .padding(.horizontal, 30)
        .navigationBarBackButtonHidden(true)  // 隱藏系統默認的返回按鈕
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()  // 返回到上一頁
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.colorBrown)
                }
            }
        }
    }
    
    // 驗證並註冊使用者
    func validateAndSignUp() {
        // 密碼匹配檢查
        if password != confirmPassword {
            passwordError = "Passwords do not match"
        } else {
            passwordError = ""
        }
        
        // 確保密碼匹配後，進行 Firebase 註冊
        if passwordError.isEmpty {
            createUser()
        }
    }
    
    // Firebase 創建使用者
    func createUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                // 根據 Firebase 返回的錯誤代碼來顯示提示訊息
                switch error.code {
                case AuthErrorCode.invalidEmail.rawValue:
                    generalErrorMessage = "The email format is invalid."
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    generalErrorMessage = "This email is already in use."
                case AuthErrorCode.weakPassword.rawValue:
                    generalErrorMessage = "The password is too weak."
                default:
                    generalErrorMessage = error.localizedDescription
                }
            } else if let uid = authResult?.user.uid {
                generalErrorMessage = ""
                logStatus = true // 註冊成功後自動登入
                print("User created successfully!")
                
                UserDefaults.standard.set(uid, forKey: "userID") // 存入 UserDefaults
                print("Stored userID: \(uid)")
                // 在 Firestore 中創建新使用者
                firestoreService.createUserInFirestore(uid: uid, name: name, email: email)
            }
        }
    }
    
    // 判斷按鈕是否應該被禁用
    func isButtonDisabled() -> Bool {
        return email.isEmpty || password.isEmpty || confirmPassword.isEmpty || name.isEmpty || !passwordError.isEmpty
    }
}

#Preview {
    SignUpPage()
}
