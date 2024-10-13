import SwiftUI
import SpriteKit
import FirebaseFirestore

// 角色頁面主結構
struct CharacterPage: View {
    
    @State private var scene = CharacterAnimationScene(size: UIScreen.main.bounds.size)  // 創建場景實例
    @State private var showSheet = false  // 控制狀態 Sheet 顯示
    @State private var characterName = ""
    @State private var currentStatusText = ""  // 初始狀態欄文字

    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            // 背景圖片
            Image("Homebg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()  // 背景填充整個屏幕
            
            // SpriteKitView 透明背景
            SpriteKitView(scene: scene)
                .ignoresSafeArea()   // 讓角色的場景填充整個頁面
            
            VStack {
                // 加長的通知欄
                Text(currentStatusText)
                    .font(.custom("LexendDeca-Semibold", size: 15))
                    .foregroundColor(.colorBrown)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 25)  // 圓角
                            .fill(Color.white.opacity(0.6))  // 半透明白色背景
                            .shadow(radius: 5)  // 添加陰影效果
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 30)  // 調整到頂部
                
                Spacer()
                
                // 底部按鈕區域
                HStack {
                    Button(action: {
                        showSheet = true  // 顯示狀態選擇 Sheet
                    }) {
                        Text("狀態")
                            .font(.body)
                            .bold()
                            .foregroundColor(.brown)
                            .frame(width: 80, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 3)
                            )
                    }
                }
                .padding(.bottom, 30)  // 底部按鈕的間距
            }
        }
        .onAppear {
            scene.scaleMode = .resizeFill
            fetchCharacterNameAndUpdateStatus()
        }
        .sheet(isPresented: $showSheet) {
            StatusSelectionSheet(
                            showSheet: $showSheet,
                            currentNotification: scene,
                            performActionAndUpdateStatus: performActionAndUpdateStatus
                        )
                .presentationDetents([.fraction(0.25)])  // 使用 fraction 設定 Sheet 高度為畫面的 25%
                .presentationDragIndicator(.visible)  // 顯示拖動條
        }
    }
    
    func fetchCharacterNameAndUpdateStatus() {
            guard let userID = UserDefaults.standard.string(forKey: "userID") else { return }

            db.collection("Users").document(userID).getDocument { document, error in
                if let error = error {
                    print("取得角色名稱錯誤: \(error.localizedDescription)")
                    return
                }

                if let document = document, let data = document.data(), let name = data["characterName"] as? String {
                    self.characterName = name
                    self.updateStatusText(for: "idle")  // 預設為 idle 動作的狀態
                } else {
                    self.characterName = "角色"
                    self.updateStatusText(for: "idle")  // 預設為 idle 動作的狀態
                }
            }
        }
    
    func performActionAndUpdateStatus(action: String) {
           scene.performAction(named: action)
           updateStatusText(for: action)
       }

    func updateStatusText(for action: String) {
        let messages: [String]
        let generalStatusMessages = [
            "\(characterName) 在看星星",
            "\(characterName) 在想今天要吃什麼",
            "\(characterName) 在構思一個笑話",
            "\(characterName) 正在發呆",
            "\(characterName) 在等待夢想中的飛碟出現",
            "\(characterName) 在思考人生的奧秘",
            "\(characterName) 正用小樹枝畫畫",
            "\(characterName) 在幻想自己變成超級英雄",
            "\(characterName) 在認真研究怎麼養一隻龍",
            "\(characterName) 覺得天氣有點適合睡午覺",
            "\(characterName) 發現一隻蟲子，好奇地觀察中",
            "\(characterName) 正打算寫一本小說",
            "\(characterName) 決定今天只做一件開心的事",
            "\(characterName) 準備打開一包零食犒賞自己",
            "\(characterName) 在研究為什麼咖啡總是那麼香",
            "\(characterName) 覺得太陽和月亮應該多聊聊天",
            "\(characterName) 認為今天適合發呆一整天",
            "\(characterName) 正在構思一場脫口秀",
            "\(characterName) 想去旅行卻忘了要去哪裡",
            "\(characterName) 現在是他和小草們的約會時間",
            "\(characterName) 和雲朵們分享了今天的秘密",
            "\(characterName) 在和蟲蟲們進行一場比賽",
            "\(characterName) 想著晚餐要不要吃披薩",
            "\(characterName) 在計劃下一場探險"
        ]
        
        switch action {
        case "walk":
            messages = [
                "\(characterName) 在散步中，順便數著地上的落葉",
                "\(characterName) 邊走邊想，該不會走丟了吧？",
                "\(characterName) 漫步在夕陽下，享受每一刻",
                "\(characterName) 在想扶老奶奶過馬路應該注意什麼",
                "\(characterName) 覺得自己今天很早起很值得鼓勵"
            ]
        case "roll":
            messages = [
                "\(characterName) 在地上滾來滾去，想變成搖過的小熊餅乾",
                "\(characterName) 發現用滾的比走的還快！",
                "\(characterName) 一不小心滾到樹叢裡了"
            ]
        case "stuned":
            messages = [
                "\(characterName) 想事情想到頭昏眼花",
                "\(characterName) 感覺天旋地轉，該補充點糖分了",
                "\(characterName) 覺得人生有點難，需要坐著休息一下"
            ]
        case "throwing":
            messages = [
                "\(characterName) 集中精神準備使出風切！",
                "\(characterName) 使出看家本領！",
                "\(characterName) 手中聚集著神秘的力量",
                "\(characterName) 在看最近鍛鍊的成果"
            ]
        case "jump":
            messages = [
                "\(characterName) 找到想吃的東西，覺得開心～",
                "\(characterName) 看到好久不見的朋友！",
                "\(characterName) 正在練習跳躍，試圖挑戰重力"
            ]
        case "idle":
            // 將「通用狀態消息」加入 idle 狀態的隨機顯示
            messages = generalStatusMessages
        case "hit":
            messages = [
                "\(characterName) 揮動魔杖，施放神秘咒語",
                "\(characterName) 正在施展魔法，一切變得不可思議",
                "\(characterName) 魔力滿滿，周圍的空氣都在震動",
                "\(characterName) 最近看了太多肌肉魔法使，想成為馬修"
            ]
        case "fly":
            messages = [
                "\(characterName) 正在天空中看底下的大家在做什麼",
                "\(characterName) 探索雲朵的秘密，彷彿沒有終點",
                "\(characterName) 慢慢的飄過了一個又一個城鎮"
            ]
        case "dead":
            messages = [
                "\(characterName) 被風吹倒了，看來是瘦了",
                "\(characterName) 累倒在草地上，夢見了奇幻的國度",
                "\(characterName) 在做一個巧克力王國的夢",
                "\(characterName) 決定暫時放棄，躺平才是王道"
            ]
        default:
            // 當沒有對應的動作時，顯示通用狀態消息
            messages = generalStatusMessages
        }
        
        currentStatusText = messages.randomElement() ?? "\(characterName) 在發呆。"
    }
}

#Preview {
    CharacterPage()
}
