import SwiftUI

struct ImageViewWithPreview: View {
    @State private var isPresented = false
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset = CGSize.zero // 记录图片相对于初始位置的偏移量

    let image: UIImage

    var body: some View {
        ZStack(alignment: .center) {
            // 缩略图显示
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .onTapGesture {
                    isPresented.toggle()
                }
                .fullScreenCover(isPresented: $isPresented, onDismiss: {
                    resetImagePosition()
                }) {
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)

                        // 让图片居中，并支持拖动和缩放
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(x: dragOffset.width + imageOffset.width, y: dragOffset.height + imageOffset.height) // 累积偏移量
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
                                            dragOffset = value.translation // 跟踪当前手势的偏移量
                                        }
                                        .onEnded { value in
                                            imageOffset.width += value.translation.width
                                            imageOffset.height += value.translation.height
                                            dragOffset = .zero

                                            // 如果拖动超过100点高度，关闭全屏
                                            if value.translation.height > 200 {
                                                isPresented = false
                                            }
                                        }
                                    )
                            )

                        // 右上角的关闭按钮
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

    // 重置图片的位置和大小
    private func resetImagePosition() {
        scale = 1.0
        dragOffset = .zero
        imageOffset = .zero // 使图片返回初始位置
        lastScale = 1.0
    }
}
