//
//  GameScene.swift
//  SpaceGameReloaded
//
//  Created by BP Bista on 3/29/17.
//  Copyright © 2017 BP Bista. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
  var starfield:SKEmitterNode!
  var player:SKSpriteNode!
  var scoreLabel:SKLabelNode!
  var score: Int = 0 {
    didSet {
      scoreLabel.text = "Score: \(score)"
    }
  }
  var gameTimer:Timer!
  var possibleAliens = ["alien","alien2","alien3"]
  
  var alienCategory:UInt32 = 0x1<<1
  var photonTorpedoCategory:UInt32 = 0x1<<0
  
  var motionManager = CMMotionManager()
  var xAcceleration:CGFloat = 0
  
  override func didMove(to view: SKView) {
      //add background stars
      starfield = SKEmitterNode(fileNamed: "Starfield")
      starfield.position = CGPoint(x: 0, y: 1472)
      starfield.advanceSimulationTime(10)
      self.addChild(starfield)
      starfield.zPosition = -1
      
      //add player
      player = SKSpriteNode(imageNamed: "shuttle")
      player.position = CGPoint(x: self.frame.midX, y:  self.frame.minY+(self.player.size.height/2+100))
      self.addChild(player)
      player.zPosition = 1
      self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
      self.physicsWorld.contactDelegate = self
      
      scoreLabel = SKLabelNode(text: "Score: 0")
      scoreLabel.position = CGPoint(x: 100, y: self.frame.maxY -  60)
      scoreLabel.fontName = "AmericanTypewriter-Bold"
      scoreLabel.fontSize = 36
      scoreLabel.fontColor = UIColor.white
      score = 0
      self.addChild(scoreLabel)
    gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
    motionManager.accelerometerUpdateInterval = 0.2
    motionManager.startAccelerometerUpdates(to:OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
      if let accelerometerData = data{
        let acceleration = accelerometerData.acceleration
        self.xAcceleration = CGFloat(acceleration.x) * 0.75 * self.xAcceleration * 0.25
        
        
      }
    }
  }
  
  func addAlien(){
    
    possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]//randomize aliens
    let alien = SKSpriteNode(imageNamed:possibleAliens[0])
    let randomAlienPosition = GKRandomDistribution(lowestValue:Int(self.frame.minX), highestValue: 414)
    //randomize position of aliens
    let position = CGFloat(randomAlienPosition.nextInt())
    alien.position = CGPoint(x: position, y: self.frame.size.height+alien.size.height)
    
    //define physics
    alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
    alien.physicsBody?.isDynamic = true
    alien.physicsBody?.categoryBitMask = alienCategory
    alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
    alien.physicsBody?.collisionBitMask = 0
    self.addChild(alien)
    
    //Some actions
    let animationDuration = 6
    var actionArray = [SKAction]()
    actionArray.append(SKAction.move(to: CGPoint(x: position,y:frame.minY-alien.size.height), duration: TimeInterval(animationDuration)))
    actionArray.append(SKAction.removeFromParent())
    alien.run(SKAction.sequence(actionArray))
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    fireTorpedo()
  }
  
  func fireTorpedo(){
    self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
    let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
    torpedoNode.position = player.position
    torpedoNode.position.y += 5
    torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width/2)
    torpedoNode.physicsBody?.isDynamic = true
    
    torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
    torpedoNode.physicsBody?.contactTestBitMask = alienCategory
    torpedoNode.physicsBody?.collisionBitMask = 0
    torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
    self.addChild(torpedoNode)
    
    let animationDuration = 6
    var actionArray = [SKAction]()
    actionArray.append(SKAction.move(to: CGPoint(x: player.position.x,y:frame.size.height+10), duration: TimeInterval(animationDuration)))
    actionArray.append(SKAction.removeFromParent())
    torpedoNode.run(SKAction.sequence(actionArray))
  }
  func didBegin(_ contact: SKPhysicsContact) {
    var firstBody:SKPhysicsBody!
    var secondBody:SKPhysicsBody!
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    }
    else{
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.contactTestBitMask & alienCategory) != 1 {
    torpedoDidCollideWithAlien(torpedo: firstBody.node as! SKSpriteNode, alien: secondBody.node as! SKSpriteNode)
    }
  }
  func torpedoDidCollideWithAlien(torpedo:SKSpriteNode,alien:SKSpriteNode) {
    let explosion = SKEmitterNode(fileNamed: "Explosion")!
    explosion.position = alien.position
    self.addChild(explosion)
    run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
    torpedo.removeFromParent()
    alien.removeFromParent()
    self.run(SKAction.wait(forDuration: 2)) { 
      explosion.removeFromParent()
    }
    score += 5
  }
  
  override func didSimulatePhysics() {
    player.position.x += xAcceleration * 50

    if player.position.x < -20 {
      player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
    }else if player.position.x > self.size.width + 20 {
      player.position = CGPoint(x: -20, y: player.position.y)
    }
  }
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
