import SwiftUI

struct BlockListPage: View {
    @State private var blockedUsers: [(id: String, name: String)] = []
    @State private var isEditing = false
    @Environment(\.presentationMode) var presentationMode
    private let firestoreService = FirestoreService()
    
    var body: some View {
        ZStack {
            Color(.colorYellow)
                .edgesIgnoringSafeArea(.all)
            VStack {

                    Text("Block")
                        .foregroundColor(.colorBrown)
                        .font(.custom("LexendDeca-Bold", size: 30))
                
                ScrollView {
                    
                    ForEach(blockedUsers, id: \.id) { user in
                        BlockedUserCard(userID: user.id, userName: user.name) {
                            removeBlock(userID: user.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchBlockedUsers()
        }
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
    
    private func fetchBlockedUsers() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else { return }
        firestoreService.fetchBlockedUsers(for: userID) { result in
            switch result {
            case .success(let users):
                self.blockedUsers = users.map { ($0.id, $0.name) }
            case .failure(let error):
                print("無法取得封鎖名單: \(error.localizedDescription)")
            }
        }
    }
    
    private func removeBlock(userID: String) {
        guard let currentUserID = UserDefaults.standard.string(forKey: "userID") else { return }
        firestoreService.removeBlock(for: currentUserID, blockedUserID: userID) { success in
            if success {
                blockedUsers.removeAll { $0.id == userID }
                print("已移除封鎖：\(userID)")
            } else {
                print("移除封鎖失敗")
            }
        }
    }
}

struct BlockedUserCard: View {
    let userID: String
    let userName: String
    let removeAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(userName)
                    .font(.custom("LexendDeca-Bold", size: 18))
                    .foregroundColor(.colorBrown)
                Text(userID)
                    .font(.custom("LexendDeca-SemiBold", size: 10))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: removeAction) {
                Text("解除封鎖")
                    .font(.custom("LexendDeca-SemiBold", size: 15))
                    .foregroundColor(.colorYellow)
                    .padding(8)
                    .background(.colorGray)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
