//
//  SettingsPage.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/9/15.
//

import SwiftUI

struct SettingsPage: View {
    var body: some View {
        VStack {
            Text("設定頁面")
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
