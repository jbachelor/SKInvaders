//
//  GameScene.swift
//  SKInvaders
//
//  Created by Riccardo D'Antoni on 15/07/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {
  
    let motionManager: CMMotionManager = CMMotionManager()
    
    var contentCreated = false
    var invaderMovementDirection: InvaderMovementDirection = .Right
    var timeOfLastMove: CFTimeInterval = 0.0
    var timePerMove: CFTimeInterval = 1.0
    var tapQueue = [Int]()
    
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
    
    
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"
    
    let kBulletSize = CGSize(width: 4, height: 8)
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kShipFiredBulletName = "shipFiredBullet"

    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
  
  // Object Lifecycle Management
  
  // MARK:  Scene Setup and Content Creation
  override func didMoveToView(view: SKView) {
    logFn(file: #file, function: #function, message: view.debugDescription)
    
    if (!self.contentCreated) {
      self.createContent()
      self.contentCreated = true
        motionManager.startAccelerometerUpdates()
    }
  }
  
    
  func createContent() {
    logFn(file: #file, function: #function)
    
    physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
    
    setupInvaders()
    setupShip()
    setupHud()
    
    self.backgroundColor = SKColor.blackColor()
  }
    
    
    func makeInvaderOfType(invaderType: InvaderType) -> SKNode {
        logFn(file: #file, function: #function, message: invaderType.rawValue)
        var invaderColor: SKColor
        
        switch invaderType {
        case .A:
            invaderColor = SKColor.redColor()
        case .B:
            invaderColor = SKColor.greenColor()
        case .C:
            invaderColor = SKColor.blueColor()
        }
        
        let invader = SKSpriteNode(color: invaderColor, size: InvaderType.size)
        invader.name = InvaderType.name
        
        return invader
    }
    
    
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
    
    
    func setupShip() {
        logFn(file: #file, function: #function)
        let ship = makeShip()
        ship.position = CGPoint(x: size.width / 2.0, y: kShipSize.height / 2.0)
        addChild(ship)
    }
    
    
    func makeShip() -> SKNode {
        logFn(file: #file, function: #function)
        let ship = SKSpriteNode(color: SKColor.greenColor(), size: kShipSize)
        ship.name = kShipName
        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        ship.physicsBody!.dynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.02
        
        return ship
    }
    
    
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
        healthLabel.text = String(format: "Health:  %.1f%%", 100.0)
        healthLabel.position = CGPoint(
            x: frame.size.width/2,
            y: size.height - (80 + healthLabel.frame.size.height/2))
        
        addChild(healthLabel)
    }
    
    
    func makeBulletOfType(bulletType: BulletType) -> SKNode {
        var bullet: SKNode
        
        switch bulletType {
        case .ShipFired:
            bullet = SKSpriteNode(color: SKColor.greenColor(), size: kBulletSize)
            bullet.name = kShipFiredBulletName
        case .InvaderFired:
            bullet = SKSpriteNode(color: SKColor.magentaColor(), size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            break
        }
        
        return bullet
    }
    
  
  // Scene Update
    func moveInvadersForUpdate(currentTime: CFTimeInterval) {
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        logFn(file: #file, function: #function, message: currentTime.debugDescription)
        
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
    
    
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        if let ship = childNodeWithName(kShipName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    ship.physicsBody!.applyForce(CGVectorMake(40.0 * CGFloat(data.acceleration.x), 0))
                }
            }
        }
    }
    
    
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
    processUserTapsForUpdate(currentTime)
    processUserMotionForUpdate(currentTime)
    moveInvadersForUpdate(currentTime)
  }
    
    
    
  
  
  // MARK:  Scene Update Helpers
    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
//        logFn(file: #file, function: #function, message: "[\(currentTime)]")
        
        for tapCount in tapQueue {
            if tapCount == 1 {
                fireShipBullets()
            }
            tapQueue.removeAtIndex(0)
        }
    }
  
    
  // MARK: Invader Movement Helpers
    func determineInvaderMovementDirection() {
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        enumerateChildNodesWithName(InvaderType.name) { node, stop in
            switch self.invaderMovementDirection {
            case .Right:
                if (CGRectGetMaxX(node.frame) >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .DownThenLeft
                    stop.memory = true
                }
            case .Left:
                if (CGRectGetMinX(node.frame) <= 1.0) {
                    proposedMovementDirection = .DownThenRight
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
        }
    }
  
  // MARK:  Bullet Helpers
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
        logFn(file: #file, function: #function, message: "Firing!")
        let bulletAction = SKAction.sequence([SKAction.moveTo(destination, duration: duration), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        bullet.runAction(SKAction.group([bulletAction, soundAction]))
        addChild(bullet)
    }
    
    
    func fireShipBullets() {
        logFn(file: #file, function: #function, message: "Ship Firing!")
        
        let existingBullet = childNodeWithName(kShipFiredBulletName)
        
        if existingBullet == nil {
            if let ship = childNodeWithName(kShipName){
                let bullet = makeBulletOfType(.ShipFired)
                bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.frame.size.height - bullet.frame.size.height/2)
                
                let bulletDestination = CGPoint(x: ship.position.x, y: frame.size.height + bullet.frame.size.height/2)
                
                fireBullet(bullet, toDestination: bulletDestination, withDuration: 1.0, andSoundFileName: "ShipBullet.wav")
            }
        }
    }
    
  
  // MARK:  User Tap Helpers
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            if(touch.tapCount == 1) {
                tapQueue.append(1)
            }
        }
    }
  
  // HUD Helpers
  
  // Physics Contact Helpers
  
  // Game End Helpers
  
}






























