import SwiftUI
import Kingfisher

struct ImageViewer: View {
    var imageURL: URL
    @Binding var isPresented: Bool  // 控制圖片檢視器的顯示
    @State private var scale: CGFloat = 1.0  // 控制縮放

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)  // 全屏的黑色背景
            
            KFImage(imageURL)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value  // 更新縮放比例
                        }
                        .onEnded { _ in
                            // 確保縮放比例不會太小
                            if scale < 1.0 {
                                scale = 1.0
                            }
                        }
                )
                .overlay(
                    // 點擊關閉檢視器的按鈕
                    Button(action: {
                        isPresented = false  // 關閉圖片檢視器
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding()
                    },
                    alignment: .topTrailing  // 放置於右上角
                )
        }
        .onTapGesture {
            // 點擊任何地方也可以關閉
            isPresented = false
        }
    }
}
