import SwiftUI
import Kingfisher

struct URLImageViewWithPreview: View {
    @State private var isPresented = false
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset = CGSize.zero // 記錄圖片相對於初始位置的偏移量

    let imageURL: URL

    var body: some View {
        ZStack(alignment: .center) {
            // 縮略圖顯示並可點擊進入全屏
            KFImage(imageURL)
                .resizable()
                .scaledToFill()
                .frame(width: 350, height: 300)
                .cornerRadius(8)
                .onTapGesture {
                    isPresented.toggle()  // 點擊後顯示全屏預覽
                }
                .fullScreenCover(isPresented: $isPresented, onDismiss: {
                    resetImagePosition()
                }) {
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)

                        KFImage(imageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(x: dragOffset.width + imageOffset.width, y: dragOffset.height + imageOffset.height)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale *= delta
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                                    .simultaneously(with: DragGesture()
                                        .onChanged { value in
                                            dragOffset = value.translation
                                        }
                                        .onEnded { value in
                                            imageOffset.width += value.translation.width
                                            imageOffset.height += value.translation.height
                                            dragOffset = .zero

                                            // 如果拖動超過100點高度，關閉全屏
                                            if value.translation.height > 200 {
                                                isPresented = false
                                            }
                                        }
                                    )
                            )

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

    // 重置圖片的位置和大小
    private func resetImagePosition() {
        scale = 1.0
        dragOffset = .zero
        imageOffset = .zero
        lastScale = 1.0
    }
}
