import SwiftUI
import SpriteKit

class CharacterAnimationScene: SKScene {
    
    var character: SKSpriteNode!
    var currentActionName: String = "idle"
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        
        character = SKSpriteNode(imageNamed: "Idle_00")
        character.setScale(0.5)
        character.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(character)
        
        performAction(named: "idle")
        
        startRandomMovement()
    }
    
    func performAction(named actionName: String) {
        currentActionName = actionName
        
        character.removeAction(forKey: "movement")
        
        let textureAtlas = SKTextureAtlas(named: "Sprites_\(actionName)")
        var frames: [SKTexture] = []
        
        let sortedTextureNames = textureAtlas.textureNames.sorted { $0 < $1 }

        guard !sortedTextureNames.isEmpty else {
            print("Error: No frames found in atlas for action: \(actionName)")
            return
        }
        
        for textureName in sortedTextureNames {
            let texture = textureAtlas.textureNamed(textureName)
            frames.append(texture)
        }
        
        guard !frames.isEmpty else {
            print("Error: No textures loaded for action: \(actionName)")
            return
        }
        
        let animateAction = SKAction.animate(with: frames, timePerFrame: 0.1)
        let repeatAction = SKAction.repeatForever(animateAction)
        
        character.removeAction(forKey: "animation")
        character.run(repeatAction, withKey: "animation")
        
        if actionName == "walk" {
            startRandomMovement()
        }
    }
    
    func startRandomMovement() {
        let moveDuration: TimeInterval = 8.0
        
        let moveAction = SKAction.run {
            guard self.currentActionName == "walk" else { return }
            
            let randomX = CGFloat.random(in: self.size.width * 0.1...self.size.width * 0.9)
            let randomY = CGFloat.random(in: self.size.height * 0.1...self.size.height * 0.9)
            let randomPosition = CGPoint(x: randomX, y: randomY)
            
            if randomPosition.x < self.character.position.x {
                self.character.xScale = -abs(self.character.xScale)
            } else {
                self.character.xScale = abs(self.character.xScale)
            }
            
            let moveToRandomPosition = SKAction.move(to: randomPosition, duration: moveDuration)
            self.character.run(moveToRandomPosition, withKey: "movement")
        }
        
        let delayAction = SKAction.wait(forDuration: moveDuration)
        let sequence = SKAction.sequence([moveAction, delayAction])
        let repeatForever = SKAction.repeatForever(sequence)
        
        character.run(repeatForever, withKey: "movement")  
    }
}
