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
    
    
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"

    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
  
  // Object Lifecycle Management
  
  // Scene Setup and Content Creation
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
                    logFn(file: #file, function: #function, message: "Acceleration: \(data.acceleration.x)")
                }
            }
        }
    }
    
    
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
    processUserMotionForUpdate(currentTime)
    moveInvadersForUpdate(currentTime)
  }
    
    
    
  
  
  // Scene Update Helpers
  
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
  
  // Bullet Helpers
  
  // User Tap Helpers
  
  // HUD Helpers
  
  // Physics Contact Helpers
  
  // Game End Helpers
  
}






























