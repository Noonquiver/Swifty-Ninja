//
//  GameScene.swift
//  Swifty Ninja
//
//  Created by Camilo Hernández Guerrero on 3/08/22.
//

import SpriteKit
import AVFoundation

enum ForceBomb {
    case never, always, random
}

class GameScene: SKScene {
    var gameScore: SKLabelNode!
    
    var lives = 3
    var score = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var activeEnemies = [SKSpriteNode]()
    
    var activeSliceForeground: SKShapeNode!
    var activeSliceBackground: SKShapeNode!
    
    var activeSlicePoints = [CGPoint]()
    
    var isSwooshSoundActive = false
    
    var bombSoundEffect: AVAudioPlayer?
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
        
        createScore()
        createLives()
        createSlices()
    }
    
    func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        addChild(gameScore)
        
        gameScore.position = CGPoint(x: 8, y: 8)
        score = 0
    }
    
    func createLives() {
        for i in 0..<3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + i * 70), y: 720)
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        activeSliceForeground = SKShapeNode()
        activeSliceForeground.zPosition = 3
        activeSliceForeground.strokeColor = UIColor.white
        activeSliceForeground.lineWidth = 5
        
        activeSliceBackground = SKShapeNode()
        activeSliceBackground.zPosition = 2
        activeSliceBackground.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBackground.lineWidth = 9
        
        addChild(activeSliceForeground)
        addChild(activeSliceBackground)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }
    }
    
    func playSwooshSound() {
        isSwooshSoundActive = true
        
        let swooshSound = SKAction.playSoundFileNamed("swoosh\(Int.random(in: 1...3)).caf", waitForCompletion: true)
        
        run(swooshSound) {
            [weak self] in
            self?.isSwooshSoundActive = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBackground.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceForeground.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        
        redrawActiveSlice()
        
        activeSliceBackground.removeAllActions()
        activeSliceForeground.removeAllActions()
        
        activeSliceBackground.alpha = 1
        activeSliceForeground.alpha = 1
    }
    
    func redrawActiveSlice() {
        if activeSlicePoints.count < 2 {
            activeSliceBackground.path = nil
            activeSliceForeground.path = nil
            
            return
        }
        
        if activeSlicePoints.count > 12 {
            activeSlicePoints.removeFirst(activeSlicePoints.count - 12)
        }
        
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1 ..< activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        
        activeSliceBackground.path = path.cgPath
        activeSliceForeground.path = path.cgPath
    }
    
    func createEnemy(forceBomb: ForceBomb = .random) {
        let enemy: SKSpriteNode
        var enemyType = Int.random(in: 0...6)
        
        if forceBomb == .never {
            enemyType = 0
        } else if forceBomb == .always {
            enemyType = 1
        }
        
        if enemyType == 0 {
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            let bomb = SKSpriteNode(imageNamed: "sliceBomb")
            bomb.name = "bomb"
            addChild(bomb)
            
            if bombSoundEffect != nil {
                bombSoundEffect?.stop()
                bombSoundEffect = nil
            }
            
            if let path = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf") {
                if let sound = try? AVAudioPlayer(contentsOf: path) {
                    bombSoundEffect = sound
                    bombSoundEffect?.play()
                }
            }
            
            if let emitter = SKEmitterNode(fileNamed: "sliceFuse") {
                emitter.position = CGPoint(x: 76, y: 64)
                enemy.addChild(emitter)
            }
        } else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }
        
        let randomXVelocity: Int
        let randomPosition = CGPoint(x: Int.random(in: 64...960), y: -128)
        
        enemy.position = randomPosition
        
        if randomPosition.x < 256 {
            randomXVelocity = Int.random(in: 8...15)
        } else if randomPosition.x < 512 {
            randomXVelocity = Int.random(in: 3...5)
        } else if randomPosition.x < 768 {
            randomXVelocity = Int.random(in: 3...5)
        } else {
            randomXVelocity = Int.random(in: 8...15)
        }
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomXVelocity * 40, dy: Int.random(in: 24...32) * 40)
        enemy.physicsBody?.angularVelocity = CGFloat.random(in: -3...3)
        enemy.physicsBody?.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        var bombCount = 0
        
        for node in activeEnemies {
            if node.name == "bombContainer" {
                bombCount += 1
                break
            }
        }
        
        if bombCount == 0 {
            bombSoundEffect?.stop()
            bombSoundEffect = nil
        }
    }
}
