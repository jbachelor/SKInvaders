//
//  GameScene.swift
//  SKInvaders
//
//  Created by Riccardo D'Antoni on 15/07/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK:  Fields
    var contentCreated = false
    var invaderMovementDirection: InvaderMovementDirection = .Right
    var timeOfLastMove: CFTimeInterval = 0.0
    var timePerMove: CFTimeInterval = 1.0
    var tapQueue = [Int]()
    var contactQueue = [SKPhysicsContact]()
    var score: Int = 0
    var shipHealth: Int = 100
    var gameEnding = false
    
    // MARK: enums
    enum InvaderMovementDirection: String {
        case Right
        case Left
        case DownThenRight
        case DownThenLeft
        case None
    }
    
    enum InvaderType: String {
        case A
        case B
        case C
        
        static var size: CGSize {
            return CGSize(width: 24, height: 16)
        }
        
        static var name: String {
            return "invader"
        }
    }
    
    enum BulletType {
        case ShipFired
        case InvaderFired
    }
    
    // MARK: Constants
    let motionManager: CMMotionManager = CMMotionManager()
    
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kMinInvaderBottomHeight: Float = 32.0
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    
    let kInvaderCategory: UInt32 = 0x1 << 0
    let kShipFiredBulletCategory: UInt32 = 0x1 << 1
    let kShipCategory: UInt32 = 0x1 << 2
    let kSceneEdgeCategory: UInt32 = 0x1 << 3
    let kInvaderFiredBulletCategory: UInt32 = 0x1 << 4
    let kInvaderBulletDamage = -20
    
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"
    
    let kBulletSize = CGSize(width: 4, height: 8)
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kShipFiredBulletName = "shipFiredBullet"
    
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    
    
    
    
    // Object Lifecycle Management
    
    
    
    // MARK:  Scene Setup and Content Creation
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func didMoveToView(view: SKView) {
        logFn(file: #file, function: #function, message: view.debugDescription)
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
            motionManager.startAccelerometerUpdates()
        }
        
        physicsWorld.contactDelegate = self
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func createContent() {
        logFn(file: #file, function: #function)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        physicsBody!.categoryBitMask = kSceneEdgeCategory
        
        setupInvaders()
        setupShip()
        setupHud()
        
        self.backgroundColor = SKColor.blackColor()
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func loadInvaderTexturesOfType(invaderType: InvaderType) -> [SKTexture] {
        logFn(file: #file, function: #function, message: "[\(invaderType.rawValue)]")
        
        var prefix: String
        
        switch (invaderType) {
        case .A:
            prefix = "InvaderA"
        case .B:
            prefix = "InvaderB"
        case .C:
            prefix = "InvaderC"
        }
        
        let invaderTexture = [SKTexture(imageNamed: String(format: "%@_00.png", prefix)),
                SKTexture(imageNamed: String(format: "%@_01.png", prefix))]
        
        return invaderTexture
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func makeInvaderOfType(invaderType: InvaderType) -> SKNode {
        logFn(file: #file, function: #function, message: invaderType.rawValue)
        
        let invaderTextures = loadInvaderTexturesOfType(invaderType)
        let invader = SKSpriteNode(texture: invaderTextures[0])
        invader.name = InvaderType.name
        invader.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(invaderTextures, timePerFrame: timePerMove)))

        // invaders' bitmask setup
        invader.physicsBody = SKPhysicsBody(rectangleOfSize: invader.frame.size)
        invader.physicsBody!.dynamic = false
        invader.physicsBody!.categoryBitMask = kInvaderCategory
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        
        return invader
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func setupInvaders() {
        logFn(file: #file, function: #function)
        let baseOrigin = CGPoint(x: size.width/3, y: size.height/2)
        
        for row in 0..<kInvaderRowCount {
            var invaderType: InvaderType
            
            if row % 3 == 0 {
                invaderType = .A
            } else if row % 3 == 1 {
                invaderType = .B
            } else {
                invaderType = .C
            }
            
            let invaderPositionY = CGFloat(row) * (InvaderType.size.height * 2) + baseOrigin.y
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            
            for _ in 1..<kInvaderRowCount {
                let invader = makeInvaderOfType(invaderType)
                invader.position = invaderPosition
                
                addChild(invader)
                
                invaderPosition = CGPoint(
                    x: invaderPosition.x + InvaderType.size.width + kInvaderGridSpacing.width,
                    y: invaderPositionY)
            }
        }
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func setupShip() {
        logFn(file: #file, function: #function)
        let ship = makeShip()
        ship.position = CGPoint(x: size.width / 2.0, y: kShipSize.height / 2.0)
        addChild(ship)
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func makeShip() -> SKNode {
        logFn(file: #file, function: #function)
        let ship = SKSpriteNode(imageNamed: "Ship.png")
        ship.name = kShipName
        
        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        ship.physicsBody!.dynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.02
        ship.physicsBody!.categoryBitMask = kShipCategory
        ship.physicsBody!.contactTestBitMask = 0x0
        ship.physicsBody!.collisionBitMask = kSceneEdgeCategory
        
        return ship
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func setupHud() {
        logFn(file: #file, function: #function)
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.greenColor()
        scoreLabel.text = String(format: "Score:  %04u", 0)
        scoreLabel.position = CGPoint(
            x: frame.size.width/2,
            y: size.height - (40 + scoreLabel.frame.size.height/2))
        
        addChild(scoreLabel)
        
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        healthLabel.fontColor = SKColor.redColor()
        healthLabel.text = "Health:  \(shipHealth)%"
        healthLabel.position = CGPoint(
            x: frame.size.width/2,
            y: size.height - (80 + healthLabel.frame.size.height/2))
        
        addChild(healthLabel)
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func adjustScoreBy(points: Int) {
        let newScore = score + points
        logFn(file: #file, function: #function, message: "Score just changed from [\(score)] to [\(newScore)].")
        
        score = newScore
        
        if let score = childNodeWithName(kScoreHudName) as? SKLabelNode {
            score.text = String(format: "Score: %04u", self.score)
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func adjustShipHealthBy(healthAdjustment: Int) {
        let newShipHealth = max(shipHealth + healthAdjustment, 0)
        
        logFn(file: #file, function: #function, message: "Health just changed from [\(shipHealth)] to [\(newShipHealth)].")

        shipHealth = newShipHealth

        if shipHealth <= 0 {
            logFn(file: #file, function: #function, message: "That's it... You're dead!")
        }
        
        
        if let health = childNodeWithName(kHealthHudName) as? SKLabelNode {
            health.text = "Health: \(shipHealth)%"
        } else {
            logFn(file: #file, function: #function, message: "ERROR:  childNodeWithName(kHealthHudName) as? SKLabelNode came back nil.")
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func makeBulletOfType(bulletType: BulletType) -> SKNode {
//        logFn(file: #file, function: #function, message: "Bullet type:  \(bulletType)")
        
        var bullet: SKNode
        
        switch bulletType {
        case .ShipFired:
            bullet = SKSpriteNode(color: SKColor.greenColor(), size: kBulletSize)
            bullet.name = kShipFiredBulletName
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kShipFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kInvaderCategory
            bullet.physicsBody!.collisionBitMask = 0x0
        case .InvaderFired:
            bullet = SKSpriteNode(color: SKColor.magentaColor(), size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kInvaderFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kShipCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            break
        }
        
        return bullet
    }
    
    
    // MARK: Scene Update
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func moveInvadersForUpdate(currentTime: CFTimeInterval) {
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        determineInvaderMovementDirection()
        
        enumerateChildNodesWithName(InvaderType.name) { node, stop in
            switch self.invaderMovementDirection {
            case .Right:
                node.position = CGPointMake(node.position.x + 10, node.position.y)
            case .Left:
                node.position = CGPointMake(node.position.x - 10, node.position.y)
            case .DownThenLeft, .DownThenRight:
                node.position = CGPointMake(node.position.x, node.position.y - 10)
            case .None:
                break
            }
            
            self.timeOfLastMove = currentTime
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func adjustInvaderMovementToTimePerMove(newTimePerMove: CFTimeInterval) {
        if newTimePerMove <= 0 {
            return
        }
        
        let ratio: CGFloat = CGFloat(timePerMove/newTimePerMove)
        timePerMove = newTimePerMove
        
        enumerateChildNodesWithName(InvaderType.name) {
            node, stop in
            node.speed = node.speed * ratio
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        // TODO: Work with physics of player ship... It's too slow and laggy!
        if let ship = childNodeWithName(kShipName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if true || fabs(data.acceleration.x) > 0.2 {
                    ship.physicsBody!.applyForce(CGVectorMake(40 * CGFloat(data.acceleration.x), 0))
                }
            }
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if isGameOver() {
            endGame()
        }
        
        processContactsForUpdate(currentTime)
        processUserTapsForUpdate(currentTime)
        processUserMotionForUpdate(currentTime)
        moveInvadersForUpdate(currentTime)
        fireInvaderBulletsForUpdate(currentTime)
    }
    
    
    
    
    
    // MARK: Scene Update Helpers
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
        for tapCount in tapQueue {
            if tapCount == 1 {
                fireShipBullets()
            }
            fireShipBullets()
            tapQueue.removeAtIndex(0)
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func fireInvaderBulletsForUpdate(currentTime: CFTimeInterval) {
        
        let existingBullet = childNodeWithName(kInvaderFiredBulletName)
        if existingBullet == nil {
            var allInvaders = Array<SKNode>()
            enumerateChildNodesWithName(InvaderType.name) {
                node, stop in
                allInvaders.append(node)
            }
            
            if allInvaders.count > 0 {
                let allInvadersIndex = Int(arc4random_uniform(UInt32(allInvaders.count)))
                let invader = allInvaders[allInvadersIndex]
                let bullet = makeBulletOfType(.InvaderFired)
                
                bullet.position =  CGPoint(x: invader.position.x, y: invader.position.y - invader.frame.size.height/2 + bullet.frame.size.height/2)
                
                let bulletDestination = CGPoint(x: invader.position.x, y: -(bullet.frame.size.height/2))
        
                logFn(file: #file, function: #function, message: "Invader firing!")
                fireBullet(bullet, toDestination: bulletDestination, withDuration: 1.0, andSoundFileName: "InvaderBullet.wav")
            }
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func processContactsForUpdate(currentTime: CFTimeInterval) {
        for contact in contactQueue {
            handleContact(contact)
            
            if let index = contactQueue.indexOf(contact) {
                contactQueue.removeAtIndex(index)
            }
        }
    }
    
    
    // MARK: Invader Movement Helpers
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func determineInvaderMovementDirection() {
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        enumerateChildNodesWithName(InvaderType.name) { node, stop in
            switch self.invaderMovementDirection {
            case .Right:
                if (CGRectGetMaxX(node.frame) >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .DownThenLeft
                    self.adjustInvaderMovementToTimePerMove(self.timePerMove * 0.8)
                    stop.memory = true
                }
            case .Left:
                if (CGRectGetMinX(node.frame) <= 1.0) {
                    proposedMovementDirection = .DownThenRight
                    self.adjustInvaderMovementToTimePerMove(self.timePerMove * 0.8)
                    stop.memory = true
                }
            case .DownThenLeft:
                proposedMovementDirection = .Left
                stop.memory = true
            case .DownThenRight:
                proposedMovementDirection = .Right
                stop.memory = true
            default:
                break
            }
        }
        
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
            logFn(file: #file, function: #function, message: "Invaders changing direction:  [\(invaderMovementDirection)]")
        }
    }
    
    // MARK:  Bullet Helpers
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
//        logFn(file: #file, function: #function, message: "Firing!")
        let bulletAction = SKAction.sequence([SKAction.moveTo(destination, duration: duration), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        bullet.runAction(SKAction.group([bulletAction, soundAction]))
        addChild(bullet)
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func fireShipBullets() {
        
        let existingBullet = childNodeWithName(kShipFiredBulletName)
        
        if existingBullet == nil {
            if let ship = childNodeWithName(kShipName){
                let bullet = makeBulletOfType(.ShipFired)
                bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.frame.size.height - bullet.frame.size.height/2)
                
                let bulletDestination = CGPoint(x: ship.position.x, y: frame.size.height + bullet.frame.size.height/2)
                logFn(file: #file, function: #function, message: "Ship Firing!")
                fireBullet(bullet, toDestination: bulletDestination, withDuration: 1.0, andSoundFileName: "ShipBullet.wav")
            }
        }
    }
    
    
    // MARK:  User Tap Helpers
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if let touch = touches.first {
            if(touch.tapCount == 1) {
                tapQueue.append(1)
            } 
        } else {
            logFn(file: #file, function: #function, message: "...touches.first was nil... No fire for you.")
        }
    }
    
    
    
    // MARK:  Physics Contact Helpers
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func didBeginContact(contact: SKPhysicsContact) {
        logFn(file: #file, function: #function)
        contactQueue.append(contact)
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func handleContact(contact: SKPhysicsContact) {
        logFn(file: #file, function: #function)
        // Ensure you haven't already handled this contact and removed its nodes
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            logFn(file: #file, function: #function, message: "Already handled this contact... Bailing out!")
            return
        }
        
        let nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        if nodeNames.contains(kShipName) && nodeNames.contains(kInvaderFiredBulletName) {
            logFn(file: #file, function: #function, message: "Oh noes!! Your ship just got f#cked up!")
            runAction(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            adjustShipHealthBy(kInvaderBulletDamage)
            if shipHealth <= 0 {
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
            } else {
                if let ship = self.childNodeWithName(kShipName) {
                    ship.alpha = CGFloat(shipHealth)/100.0
                    
                    if contact.bodyA.node == ship {
                        contact.bodyB.node!.removeFromParent()
                    } else {
                        contact.bodyA.node!.removeFromParent()
                    }
                }
            }
        } else if nodeNames.contains(InvaderType.name) && nodeNames.contains(kShipFiredBulletName) {
            logFn(file: #file, function: #function, message: "w00000t!! Invader destroyed!")
            self.runAction(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            adjustScoreBy(100)
        }
    }
    
    
    
    
    // Game End Helpers
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func isGameOver() -> Bool {
        let invader = childNodeWithName(InvaderType.name)
        var invaderTooLow = false
        
        enumerateChildNodesWithName(InvaderType.name) {
            node, stop in
            
            if (Float(CGRectGetMinY(node.frame)) <= self.kMinInvaderBottomHeight) {
                invaderTooLow = true
                stop.memory = true
            }
        }
        
        let ship = childNodeWithName(kShipName)
        
        return invader == nil || invaderTooLow || ship == nil
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func endGame() {
        if !gameEnding {
            gameEnding = true
            motionManager.startAccelerometerUpdates()
            
            let gameOverScene: GameOverScene = GameOverScene(size: size)
            view?.presentScene(gameOverScene, transition: SKTransition.doorsOpenHorizontalWithDuration(1.0))
        }
    }
}






























