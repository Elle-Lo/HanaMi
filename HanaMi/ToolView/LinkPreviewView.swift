import SwiftUI
import LinkPresentation

struct LinkPreviewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)

        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let metadata = metadata {
                DispatchQueue.main.async {
                    linkView.metadata = metadata

                }
            }
        }

        return linkView
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {

    }
}
