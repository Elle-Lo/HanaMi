import SwiftUI

struct TreasureDetailView: View {
    let treasure: Treasure

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(treasure.locationName)
                    .font(.largeTitle)
                    .padding()

                Text("類別: \(treasure.category)")
                    .font(.headline)

                if !treasure.contents.isEmpty {
                    ForEach(treasure.contents) { content in
                        switch content.type {
                        case .text:
                            Text(content.content)
                        case .image:
                            if let url = URL(string: content.content) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                        case .audio:
                            Text("音頻內容")
                        default:
                            Text("其他內容類型")
                        }
                    }
                } else {
                    Text("無附加內容")
                }
                Spacer()
            }
            .padding()
        }
    }
}
