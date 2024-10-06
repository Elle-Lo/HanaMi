import SwiftUI

struct ImageViewWithPreview: View {
    @State private var isPresented = false
    @State private var dragOffset = CGSize.zero

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
                    ZStack(alignment: .topTrailing) {
                        Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)

                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .gesture(
                                DragGesture()
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
                            .offset(y: dragOffset.height)

                        // 右上角的關閉按鈕
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
                }
        }
    }
}
