//
//  LogInPage.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/9/13.
//

import SwiftUI

struct LogInPage: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isHomePresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Email 输入框
            VStack(alignment: .leading, spacing: 5) {
                Text("Email")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.brown)
                
                TextField("", text: $email)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(25)
                    .overlay(RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.brown.opacity(0.3), lineWidth: 2))
            }
            .padding(.horizontal, 40)
            
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Password")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.brown)
                
                ZStack {
                    
                    Image("Cat")
                        .resizable()
                        .frame(width: 120, height: 130)
                        .offset(x: 100, y: -17)
                    
                    SecureField("", text: $password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(25)
                        .overlay(RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.brown.opacity(0.3), lineWidth: 2))
                    
                }
            }
            .padding(.horizontal, 40)
            
            Toggle(isOn: $rememberMe) {
                Text("Remember this password")
                    .font(.system(size: 16))
                    .foregroundColor(.brown)
            }
            .padding(.horizontal, 40)
            
            
            Button(action: {
                // 按下按钮时，展示 HomePage
                isHomePresented = true
            }) {
                Text("Log In")
                    .foregroundColor(.brown)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 250, height: 50)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(25)
            }
            .padding(.top, 20)
            .fullScreenCover(isPresented: $isHomePresented) {
                // 进入 HomePage，新的导航系统
                HomePage()
            }
        }
        .padding(.top, 50)
    }
}

#Preview {
    LogInPage()
}
