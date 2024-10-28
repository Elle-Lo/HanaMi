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
                .padding(.vertical, 10)
                .multilineTextAlignment(.center)
                .font(.custom("LexendDeca-SemiBold", size: 16))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray),
                    alignment: .bottom
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
                Text("添加")
                    .font(.custom("LexendDeca-SemiBold", size: 16))
                    .foregroundColor(.colorYellow)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(Color.colorBrown)
                    .cornerRadius(8) 
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
