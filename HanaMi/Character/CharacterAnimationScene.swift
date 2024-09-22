import SwiftUI
import SpriteKit

// 自定义 SpriteKit 场景类
class CharacterAnimationScene: SKScene {
    
    var character: SKSpriteNode!
    var currentActionName: String = "walk"  // 当前动作名称，用于判断是否需要移动
    
    override func didMove(to view: SKView) {
        // 设置场景的背景颜色为透明
        self.backgroundColor = .clear
        
        // 初始化角色精灵，展示默认动作的第一帧
        character = SKSpriteNode(imageNamed: "walk_00")
        character.setScale(0.5)  // 将角色缩小
        character.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(character)
        
        // 执行默认的走路动画
        performAction(named: "walk")
        
        // 开始角色在屏幕上的随机移动
        startRandomMovement()
    }
    
    // 根据传入的动作名称加载对应的动画
    func performAction(named actionName: String) {
        currentActionName = actionName  // 保存当前动作名称
        
        // 加载对应的 Sprite Atlas
        let textureAtlas = SKTextureAtlas(named: "Sprites_\(actionName)")
        var frames: [SKTexture] = []
        
        let sortedTextureNames = textureAtlas.textureNames.sorted { $0 < $1 }  // 确保按顺序加载

        // 检查是否有帧图片
        guard !sortedTextureNames.isEmpty else {
            print("Error: No frames found in atlas for action: \(actionName)")
            return
        }
        
        // 加载所有的帧
        for textureName in sortedTextureNames {
            let texture = textureAtlas.textureNamed(textureName)
            frames.append(texture)
        }
        
        guard !frames.isEmpty else {
            print("Error: No textures loaded for action: \(actionName)")
            return
        }
        
        // 创建并运行动画
        let animateAction = SKAction.animate(with: frames, timePerFrame: 0.1)
        let repeatAction = SKAction.repeatForever(animateAction)
        
        character.run(repeatAction)
        
        // 只有在走路时才会移动
        if actionName == "walk" {
            startRandomMovement()
        } else {
            character.removeAllActions()  // 停止其他动作时的移动行为
        }
    }
    
    // 角色随机移动（仅限于 "walk" 动作）
    func startRandomMovement() {
        let moveDuration: TimeInterval = 8.0  // 设置更慢的移动速度
        
        // 无限循环随机移动
        let moveAction = SKAction.run {
            guard self.currentActionName == "walk" else { return }  // 只有在走路时移动
            
            // 生成随机位置，确保在 Safe Area 内
            let randomX = CGFloat.random(in: self.size.width * 0.1...self.size.width * 0.9)
            let randomY = CGFloat.random(in: self.size.height * 0.1...self.size.height * 0.9)
            let randomPosition = CGPoint(x: randomX, y: randomY)
            
            // 判断移动方向，改变角色的面向
            if randomPosition.x < self.character.position.x {
                self.character.xScale = -abs(self.character.xScale)  // 面向左
            } else {
                self.character.xScale = abs(self.character.xScale)  // 面向右
            }
            
            // 移动到随机位置
            let moveToRandomPosition = SKAction.move(to: randomPosition, duration: moveDuration)
            self.character.run(moveToRandomPosition)
        }
        
        let delayAction = SKAction.wait(forDuration: moveDuration)
        let sequence = SKAction.sequence([moveAction, delayAction])
        let repeatForever = SKAction.repeatForever(sequence)
        
        // 开始角色随机移动
        character.run(repeatForever)
    }
}
