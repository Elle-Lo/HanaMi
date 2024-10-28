import SwiftUI
import FirebaseAuth

struct SignUpPage: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible = false
    
    @State private var passwordError: String = ""
    @State private var generalErrorMessage: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("log_Status") private var logStatus: Bool = false
    private let firestoreService = FirestoreService()
    
    var body: some View {
        VStack(spacing: 35) {
           
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
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Password")
                    .foregroundColor(Color(hex: "#522504"))
                    .font(.system(size: 16, weight: .medium))
                
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
          
            VStack(alignment: .leading, spacing: 15) {
                Text("Confirm Password")
                    .foregroundColor(Color(hex: "#522504"))
                    .font(.system(size: 16, weight: .medium))
                
                
                ZStack(alignment: .trailing) {
                    if isPasswordVisible {
                        TextField("", text: $confirmPassword)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#FFF7EF"), lineWidth: 4)
                            )
                            .frame(height: 45)
                    } else {
                        SecureField("", text: $confirmPassword)
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
                
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            
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
            .disabled(isButtonDisabled())
        }
        .padding(.horizontal, 30)
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
    
    func validateAndSignUp() {
     
        if password != confirmPassword {
            passwordError = "Passwords do not match"
        } else {
            passwordError = ""
        }
        
        if passwordError.isEmpty {
            createUser()
        }
    }
    
    func createUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
           
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
                logStatus = true
                print("User created successfully!")
                
                UserDefaults.standard.set(uid, forKey: "userID")
                print("Stored userID: \(uid)")
                firestoreService.createUserInFirestore(uid: uid, name: name, email: email)
            }
        }
    }
    
    func isButtonDisabled() -> Bool {
        return email.isEmpty || password.isEmpty || confirmPassword.isEmpty || name.isEmpty || !passwordError.isEmpty
    }
}

#Preview {
    SignUpPage()
}
