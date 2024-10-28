import SwiftUI
import FirebaseAuth

struct LogInPage: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isPasswordVisible = false
    @AppStorage("log_Status") private var logStatus: Bool = false
    @State private var errorMessage: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#522504"))
                    
                    TextField("", text: $email)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                        )
                        .frame(height: 45)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Password")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#522504"))
                    
                    ZStack(alignment: .trailing) {
                        if isPasswordVisible {
                            TextField("", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                                )
                                .frame(height: 45)
                        } else {
                            SecureField("", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                                )
                                .frame(height: 45)
                        }
                        
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
                
                HStack {
                    Button(action: {
                        rememberMe.toggle()
                    }) {
                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                            .foregroundColor(rememberMe ? .black : .gray)
                    }
                    Text("Remember this password")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#522504"))
                }
                .padding(.top, -5)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                
                Button(action: {
                    logIn()
                }) {
                    Text("Log In")
                        .foregroundColor(Color(hex: "#522504"))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#FFF7EF"))
                        .cornerRadius(25)
                }
                .padding(.top, 25)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity)
            
            Spacer()

            Image("capybaraRight")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .offset(x: -100, y: 20)
            
        }
        .padding(.top, 50)
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
    }
    
    func logIn() {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error as NSError? {
               
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
             
                errorMessage = ""
                print("Login successful")
                
                if rememberMe {
                    saveCredentials()
                } else {
                    clearCredentials()
                }
                
                if let uid = result?.user.uid {
                    UserDefaults.standard.set(uid, forKey: "userID")
                    print("Stored userID: \(uid)")
                }
                
                logStatus = true
            }
        }
    }
    
    func saveCredentials() {
        UserDefaults.standard.set(email, forKey: "savedEmail")
        UserDefaults.standard.set(password, forKey: "savedPassword")
        UserDefaults.standard.set(true, forKey: "rememberMe")
    }
    
    func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: "savedEmail")
        UserDefaults.standard.removeObject(forKey: "savedPassword")
        UserDefaults.standard.set(false, forKey: "rememberMe")
    }
}

#Preview {
    LogInPage()
}
