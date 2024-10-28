import SwiftUI
import WebKit

struct PrivacyPolicyPage: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
           
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("完成")
                        .font(.system(size: 16))
                        .foregroundColor(.colorBrown)
                })
                .padding()

                Spacer()
            }

            WebView(url: URL(string: "https://www.privacypolicies.com/live/87b7a63c-e519-440a-9f90-370fcdff9b0a")!)
                .edgesIgnoringSafeArea(.all)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
