import SwiftUI
import LinkPresentation

struct LinkPreviewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)

        // 获取元数据并动态更新 LinkView
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let metadata = metadata {
                DispatchQueue.main.async {
                    linkView.metadata = metadata
                    linkView.sizeToFit()  // 确保大小自适应内容
                    linkView.layoutIfNeeded()  // 更新布局
                }
            }
        }

        return linkView
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {
        // 更新时确保尺寸和布局同步
        uiView.sizeToFit()
        uiView.layoutIfNeeded()
    }
}
