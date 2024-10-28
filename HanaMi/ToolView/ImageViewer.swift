import SwiftUI
import Kingfisher

struct ImageViewer: View {
    var imageURL: URL
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            KFImage(imageURL)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { _ in
                         
                            if scale < 1.0 {
                                scale = 1.0
                            }
                        }
                )
                .overlay(
               
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding()
                    },
                    alignment: .topTrailing
                )
        }
        .onTapGesture {
            isPresented = false
        }
    }
}
