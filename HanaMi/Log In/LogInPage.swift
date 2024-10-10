import SwiftUI
import FirebaseAuth

struct LogInPage: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isPasswordVisible = false // 控制密碼是否可見
    @AppStorage("log_Status") private var logStatus: Bool = false // 使用 AppStorage 來追蹤登入狀態
    @State private var errorMessage: String = "" // 顯示錯誤訊息的狀態變數
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Spacer()
            
            // Email 和 Password 區塊
            VStack(alignment: .leading, spacing: 20) {
                
                // Email 輸入框
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#522504"))
                    
                    TextField("", text: $email)
                        .padding()
                        .background(Color.white) // 中間為白色
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: "#FFF7EF"), lineWidth: 4) // 邊框顏色
                        )
                        .frame(height: 45)
                }
                
                // Password 輸入框
                VStack(alignment: .leading, spacing: 10) {
                    Text("Password")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#522504"))
                    
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
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 13))
                                .padding(.trailing, 15)
                        }
                    }
                }
                
                // Remember Me Checkbox（距離上方較近）
                HStack {
                    Button(action: {
                        rememberMe.toggle()
                    }) {
                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                            .foregroundColor(rememberMe ? .black : .gray)
                    }
                    Text("Remember this password")
                        .font(.system(size: 14)) // 字體變小
                        .foregroundColor(Color(hex: "#522504"))
                }
                .padding(.top, -5) // 與上方保持近一點的間距
                
                // 顯示錯誤訊息
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                
                // Log In 按鈕
                Button(action: {
                    logIn()
                }) {
                    Text("Log In")
                        .foregroundColor(Color(hex: "#522504"))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity) // 設置按鈕寬度和文字框一樣寬
                        .frame(height: 50)
                        .background(Color(hex: "#FFF7EF"))
                        .cornerRadius(25)
                }
                .padding(.top, 25)
            }
            .padding(.horizontal, 30) // 與邊框距離30
            .frame(maxWidth: .infinity) // 保證內容區塊居中
            
            Spacer() // 保證內容區塊在中間

            // 放置底部圖像
            Image("capybaraRight")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .offset(x: -100, y: 20)
            
        }
        .padding(.top, 50)
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
    
    // Log In function with error handling
    func logIn() {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error as NSError? {
                // 根據 Firebase 返回的錯誤代碼來顯示提示訊息
                switch error.code {
                case AuthErrorCode.wrongPassword.rawValue:
                    errorMessage = "Incorrect password. Please try again."
                case AuthErrorCode.invalidEmail.rawValue:
                    errorMessage = "Invalid email format."
                case AuthErrorCode.userNotFound.rawValue:
                    errorMessage = "No account found with this email."
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                // 登入成功，清除錯誤訊息
                errorMessage = ""
                print("Login successful")
                
                // 保存 Remember Me 狀態
                if rememberMe {
                    saveCredentials()
                } else {
                    clearCredentials()
                }
                
                if let uid = result?.user.uid {
                    UserDefaults.standard.set(uid, forKey: "userID") // 存入 UserDefaults
                    print("Stored userID: \(uid)")
                }
                
                // 設置登入狀態
                logStatus = true
            }
        }
    }
    
    // 保存用戶的 Email 和密碼到 UserDefaults
    func saveCredentials() {
        UserDefaults.standard.set(email, forKey: "savedEmail")
        UserDefaults.standard.set(password, forKey: "savedPassword")
        UserDefaults.standard.set(true, forKey: "rememberMe")
    }
    
    // 清除保存的 Email 和密碼
    func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: "savedEmail")
        UserDefaults.standard.removeObject(forKey: "savedPassword")
        UserDefaults.standard.set(false, forKey: "rememberMe")
    }
}

#Preview {
    LogInPage()
}
