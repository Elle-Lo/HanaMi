import SwiftUI

struct AddCategoryForm: View {
    @Binding var newCategoryName: String
    @Binding var newCategoryValidationMessage: String?
    @Binding var categories: [String]
    var userID: String
    var onAddSuccess: () -> Void

    var body: some View {
        VStack(spacing: 15) {

            TextField("新增類別", text: $newCategoryName)
                .padding(.vertical, 10)  // 控制輸入框上下的間距
                .multilineTextAlignment(.center)
                .font(.custom("LexendDeca-SemiBold", size: 16))
                .overlay(
                    Rectangle()  // 使用矩形作為底線
                        .frame(height: 1)  // 底線的高度
                        .foregroundColor(.gray),  // 底線顏色
                    alignment: .bottom  // 將底線對齊到輸入框底部
                )
                .padding(.horizontal, 100)
                .onChange(of: newCategoryName) { _ in
                    validateNewCategoryName()
                }
            
            if let message = newCategoryValidationMessage {
                Text(message)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Button(action: {
                let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
                FirestoreService().addCategory(userID: userID, category: trimmedName) { success in
                    if success {
                        onAddSuccess()
                    }
                }
            }) {
                Text("添加")  // 包裝文字
                    .font(.custom("LexendDeca-SemiBold", size: 16))  // 設定字體和大小
                    .foregroundColor(.colorYellow)  // 設定文字顏色
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(Color.colorBrown)  // 背景色
                    .cornerRadius(8)  // 圓角
            }
            .padding(.top, 10)
            .disabled(newCategoryValidationMessage != nil)

        }
    }

    private func validateNewCategoryName() {
        
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            newCategoryValidationMessage = "類別名稱不能為空或全為空格"
        } else if categories.contains(trimmedName) {
            newCategoryValidationMessage = "類別已存在"
        } else {
            newCategoryValidationMessage = nil
        }
    }
}
