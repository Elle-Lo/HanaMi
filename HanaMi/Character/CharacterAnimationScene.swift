import SwiftUI
import SpriteKit

class CharacterAnimationScene: SKScene {
    
    var character: SKSpriteNode!
    var currentActionName: String = "idle"
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        
        character = SKSpriteNode(imageNamed: "Idle_00")
        character.setScale(0.5)  // 将角色缩小
        character.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(character)
        
        // 执行默认的走路动画
        performAction(named: "idle")
        
        // 开始角色在屏幕上的随机移动
        startRandomMovement()
    }
    
    // 根据传入的动作名称加载对应的动画
    func performAction(named actionName: String) {
        currentActionName = actionName  // 保存当前动作名称
        
        // 停止所有与移动相关的行为，但保留动画
        character.removeAction(forKey: "movement")  // 停止移动相关的行为
        
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
        
        // 停止之前的动画并运行动画
        character.removeAction(forKey: "animation")
        character.run(repeatAction, withKey: "animation")
        
        // 只有在走路时才会移动
        if actionName == "walk" {
            startRandomMovement()  // 开始走路时的随机移动
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
            self.character.run(moveToRandomPosition, withKey: "movement")  // 使用 key 标识该移动行为
        }
        
        let delayAction = SKAction.wait(forDuration: moveDuration)
        let sequence = SKAction.sequence([moveAction, delayAction])
        let repeatForever = SKAction.repeatForever(sequence)
        
        // 开始角色随机移动
        character.run(repeatForever, withKey: "movement")  // 使用 key 标识该移动行为
    }
}
