import SwiftUI

struct ImageViewWithPreview: View {
    @State private var isPresented = false
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0  // 縮放比例
    @State private var lastScale: CGFloat = 1.0  // 上次縮放的比例

    let image: UIImage

    var body: some View {
        ZStack(alignment: .center) {
            // 縮略圖顯示
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .onTapGesture {
                    isPresented.toggle()
                }
                .fullScreenCover(isPresented: $isPresented) {
                    ZStack {
                        Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)

                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .scaleEffect(scale)  // 將縮放效果應用於圖片
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        // 計算縮放比例
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale *= delta
                                    }
                                    .onEnded { _ in
                                        // 手勢結束時重置 lastScale
                                        lastScale = 1.0
                                    }
                                    .simultaneously(with: DragGesture()
                                        .onChanged { value in
                                            if value.translation.height > 0 {
                                                dragOffset = value.translation
                                            }
                                        }
                                        .onEnded { value in
                                            if value.translation.height > 100 {
                                                isPresented = false
                                            }
                                            dragOffset = .zero
                                        }
                                    )
                            )
                            .offset(y: dragOffset.height)  // 允許拖動以退出全屏

                        // 右上角的關閉按鈕
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    isPresented = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                            }
                            Spacer()
                        }
                    }
                }
        }
    }
}
