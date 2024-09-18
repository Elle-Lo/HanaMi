//
//  TreasureMapPage.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/9/14.
//

import SwiftUI

struct TreasureMapPage: View {
    var body: some View {
        VStack {
            Text("地圖頁面")
                .font(.largeTitle)
                .padding()

            // 這裡可以添加各種設定選項
            Text("在這裡添加各種設定選項")
                .padding()

            Spacer()
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
           }

#Preview {
    TreasureMapPage()
}
