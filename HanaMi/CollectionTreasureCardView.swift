import SwiftUI

struct CollectionTreasureCardView: View {
    let treasure: Treasure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(treasure.category)
                .font(.headline)
                .foregroundColor(.colorBrown)
            Text(treasure.locationName)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // 這裡可加上圖片或其他內容
            if let imageURL = URL(string: treasure.imageUrl) {
                URLImageViewWithPreview(imageURL: imageURL)
                    .frame(height: 200)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}
