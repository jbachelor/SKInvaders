//
//  GameViewController.swift
//  SKInvaders
//
//  Created by Riccardo D'Antoni on 15/07/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  
  override func viewDidLoad() {
    logFn(file: #file, function: #function)
    super.viewDidLoad()
    
    // Configure the view.
    let skView = self.view as! SKView
    skView.showsFPS = true
    skView.showsNodeCount = true
    
    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = true
    
    // Create and configure the scene.
    let scene = GameScene(size: skView.frame.size)
    skView.presentScene(scene)
    
    // Pause the view (and thus the game) when the app is interrupted or backgrounded
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameViewController.handleApplicationWillResignActive(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameViewController.handleApplicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
  }
  
  override func shouldAutorotate() -> Bool {
    return true
  }
  
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    
    return UIInterfaceOrientationMask.Portrait
  }
  
  override func didReceiveMemoryWarning() {
    logFn(file: #file, function: #function)
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }
  
  
  func handleApplicationWillResignActive (note: NSNotification) {
    logFn(file: #file, function: #function)
    
    let skView = self.view as! SKView
    skView.paused = true
  }
  
  func handleApplicationDidBecomeActive (note: NSNotification) {
    logFn(file: #file, function: #function)
    
    let skView = self.view as! SKView
    skView.paused = false
  }
  
}
