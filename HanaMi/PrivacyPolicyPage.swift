import SwiftUI
import WebKit

struct PrivacyPolicyPage: View {
    @Environment(\.presentationMode) var presentationMode  // 用於控制返回操作

    var body: some View {
        VStack {
            // "完成" 按鈕，左上角返回到設置頁面
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()  // 返回到上一頁
                }) {
                    Text("完成")
                        .font(.system(size: 16))
                        .foregroundColor(.colorBrown)
                }
                .padding()

                Spacer()
            }

            // WebView 顯示隱私權政策
            WebView(url: URL(string: "https://www.privacypolicies.com/live/87b7a63c-e519-440a-9f90-370fcdff9b0a")!)
                .edgesIgnoringSafeArea(.all)
        }
        .navigationBarBackButtonHidden(true)  // 隱藏系統默認的返回按鈕
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

