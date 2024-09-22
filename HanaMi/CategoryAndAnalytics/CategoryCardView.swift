import SwiftUI
import Kingfisher

// 寶藏卡片視圖
struct CategoryCardView: View {
    var treasure: Treasure
    
    var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                
                Text(treasure.category)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                Text("地點: \(treasure.locationName)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                    .padding(.vertical, 5)
                
                ForEach(treasure.contents.sorted(by: { $0.index < $1.index })) { content in
                    VStack(alignment: .leading, spacing: 10) {
                        
                        switch content.type {
                        case .text:
                            
                            Text(content.content)
                                .font(.body)
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true) // 确保文本换行时不会拉伸
                            
                        case .image:
                            
                            if let imageURL = URL(string: content.content) {
                                KFImage(imageURL)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(10)
                            }
                            
                        case .link:
                            
                            if let url = URL(string: content.content) {
                                Text(content.displayText ?? url.absoluteString)
                                    .font(.body)
                                    .foregroundColor(.blue)
                                    .underline()
                                    .onTapGesture {
                                        UIApplication.shared.open(url)
                                    }
                            }
                            
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.bottom, 5)
                }
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }

