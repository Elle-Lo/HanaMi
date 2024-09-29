import SwiftUI

struct AddCategoryForm: View {
    @Binding var newCategoryName: String
    @Binding var newCategoryValidationMessage: String?
    @Binding var categories: [String]
    var userID: String
    var onAddSuccess: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            Text("新增類別")
                .font(.headline)
                .padding(.top, 10)

            TextField("輸入新類別名稱", text: $newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
                .padding(.horizontal, 20)
                .onChange(of: newCategoryName) { _ in
                    validateNewCategoryName()
                }

            if let message = newCategoryValidationMessage {
                Text(message)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Button("添加類別") {
                let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
                FirestoreService().addCategory(userID: userID, category: trimmedName) { success in
                    if success {
                        onAddSuccess()
                    }
                }
            }
            .frame(width: 100)
            .disabled(newCategoryValidationMessage != nil)
        }
        .padding()
        .frame(width: 300, height: 300)
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
