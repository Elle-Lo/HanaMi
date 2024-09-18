import SwiftUI

struct StarterPage: View {
    var body: some View {
        VStack {
            Text("Welcome")
                .font(.largeTitle)
                .padding()
            Image("Cat")
                .resizable()
                .frame(width: 200, height: 220)
                .scaledToFit()
            
            NavigationLink(destination: LogInPage()) {
                Text("LOG IN")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            
            NavigationLink(destination: GmailLogInPage()) {
                Text("LOG IN WITH GMAIL")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
    }
}

#Preview {
    StarterPage()
}
