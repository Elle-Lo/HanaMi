import SwiftUI

struct ImageViewWithPreview: View {
    @State private var isPresented = false
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset = CGSize.zero 

    let image: UIImage

    var body: some View {
        ZStack(alignment: .center) {
          
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

                        Image(uiImage: image)
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

                                            if value.translation.height > 200 {
                                                isPresented = false
                                            }
                                        }
                                    )
                            )

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

    private func resetImagePosition() {
        scale = 1.0
        dragOffset = .zero
        imageOffset = .zero
        lastScale = 1.0
    }
}
