//
//  GameScene.swift
//  project29
//
//  Created by Sabrina Fletcher on 6/25/18.
//  Copyright © 2018 Sabrina Fletcher. All rights reserved.
//

import SpriteKit
import GameplayKit

enum CollisionTypes: UInt32 {
    case banana = 1
    case building = 2
    case player = 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var viewController: GameViewController!
    
    var buildings = [BuildingNode]()
    
    var player1: SKSpriteNode!
    var player2: SKSpriteNode!
    var banana: SKSpriteNode!
    
    var currentPlayer = 1
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hue: 0.669, saturation: 0.99, brightness: 0.67, alpha: 1)
        physicsWorld.contactDelegate = self
        createBuildings()
        createPlayers()
     
    }
    
    func deg2rad(degrees: Int) -> Double {
        return Double(degrees) * Double.pi / 180.0
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if let firstNode = firstBody.node {
            if let secondNode = secondBody.node {
                if firstNode.name == "banana" && secondNode.name == "building" {
                    bananaHit(building: secondNode as! BuildingNode, atPoint: contact.contactPoint)
                }
                
                if firstNode.name == "banana" && secondNode.name == "player1"{
                    destroy(player: player1)
                    self.viewController.player2Score += 1
                    //self.viewController.ScoreLbl.text = "Score: \(Int())"
                }
                
                if firstNode.name == "banana" && secondNode.name == "player2"{
                    destroy(player: player2)
                    self.viewController.player1Score += 1
                }
            }
        }
    }
    
    func createBuildings(){
        var currentX: CGFloat = -15
        
        while currentX < 1024 {
            let size = CGSize(width: RandomInt(min: 2, max: 4) * 40, height: RandomInt(min: 300, max: 600))
            currentX += size.width + 2
            
            let building  = BuildingNode(color: UIColor.red, size: size)
            building.position = CGPoint(x: currentX - (size.width / 2), y: size.height / 2)
            building.setup()
            addChild(building)
            buildings.append(building)
        }
    }
    
    func createPlayers(){
        player1 = SKSpriteNode(imageNamed: "player")
        player1.name = "player1"
        player1.physicsBody = SKPhysicsBody(circleOfRadius: player1.size.width / 2)
        player1.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player1.physicsBody?.contactTestBitMask = CollisionTypes.banana.rawValue
        player1.physicsBody?.isDynamic = false
        
        let player1Building = buildings[1]
        player1.position = CGPoint(x: player1Building.position.x, y: player1Building.position.y + ((player1Building.size.height + player1.size.height) / 2))
        addChild(player1)
        
        player2 = SKSpriteNode(imageNamed: "player")
        player2.name = "player2"
        player2.physicsBody = SKPhysicsBody(circleOfRadius: player2.size.width / 2)
        player2.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player2.physicsBody?.contactTestBitMask = CollisionTypes.banana.rawValue
        player2.physicsBody?.isDynamic = false
        
        let player2Building = buildings[buildings.count - 2]
        player2.position = CGPoint(x: player2Building.position.x, y: player2Building.position.y + ((player2Building.size.height + player2.size.height) / 2))
        addChild(player2)
    }
    
    
    func destroy(player: SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "hitPlayer")!
        explosion.position = player.position
        addChild(explosion)
        
        player.removeFromParent()
        banana?.removeFromParent()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2){
            [unowned self] in
            //transitions between the old scene once a player is destroyed to a new scene

            let newGame = GameScene(size: self.size)
            newGame.viewController = self.viewController
            self.viewController.currentGame = newGame
            newGame.viewController.player1Score = self.viewController.player1Score
            newGame.viewController.player2Score = self.viewController.player2Score
            
            self.changePlayer()
            newGame.currentPlayer = self.currentPlayer
            let transition = SKTransition.doorway(withDuration: 1.5)
            self.view?.presentScene(newGame, transition: transition)
        }

    }
    
    func changePlayer() {
        //changes the player's turn
        if currentPlayer == 1{
            currentPlayer = 2
        } else{
            currentPlayer = 1
        }
        viewController.activatePlayer(number: currentPlayer)
    }
    
    func bananaHit(building: BuildingNode, atPoint contactPoint: CGPoint) {
        let buildingLocation = convert(contactPoint, to: building)
        building.hitAt(point: buildingLocation)
        
        let explosion = SKEmitterNode(fileNamed: "hitBuilding")!
        explosion.position = contactPoint
        addChild(explosion)
        
        banana.name = ""
        banana?.removeFromParent()
        banana = nil
        
        changePlayer()
    }
    
  
    func launch(angle: Int, velocity: Int){
        //1
        let speed = Double(velocity) / 10.0
        
        //2
        let radians = deg2rad(degrees: angle)
        
        //3
        if banana != nil {
            banana.removeFromParent()
            banana = nil
        }
        
        banana = SKSpriteNode(imageNamed: "banana")
        banana.name = "banana"
        banana.physicsBody = SKPhysicsBody(circleOfRadius: banana.size.width / 2)
        banana.physicsBody?.categoryBitMask = CollisionTypes.banana.rawValue
        banana.physicsBody?.collisionBitMask = CollisionTypes.building.rawValue | CollisionTypes.player.rawValue
        banana.physicsBody?.contactTestBitMask = CollisionTypes.building.rawValue | CollisionTypes.player.rawValue
        banana.physicsBody?.usesPreciseCollisionDetection = true
        addChild(banana)
        
        if currentPlayer == 1 {
            //4
            banana.position = CGPoint(x: player1.position.x - 30, y: player1.position.y + 40)
            banana.physicsBody?.angularVelocity = -20
            
            //5
            let raiseArm = SKAction.setTexture(SKTexture(imageNamed: "player1Throw"))
            let lowerArm = SKAction.setTexture(SKTexture(imageNamed: "player"))
            let pause = SKAction.wait(forDuration: 0.15)
            let sequence = SKAction.sequence([raiseArm, pause, lowerArm])
            player1.run(sequence)
            
            //6
            let impulse = CGVector(dx: cos(radians) * speed, dy: sin(radians) * speed)
            banana.physicsBody?.applyImpulse(impulse)
        } else {
            //7
            banana.position = CGPoint(x: player2.position.x + 30, y: player2.position.y + 40)
            banana.physicsBody?.angularVelocity = 20
            
            let raiseArm = SKAction.setTexture(SKTexture(imageNamed: "player2Throw"))
            let lowerArm = SKAction.setTexture(SKTexture(imageNamed: "player"))
            
            let pause = SKAction.wait(forDuration: 0.15)
            let sequence = SKAction.sequence([raiseArm, pause, lowerArm])
            player2.run(sequence)
            
            let impulse = CGVector(dx: cos(radians) * -speed, dy: sin(radians) * speed)
            banana.physicsBody?.applyImpulse(impulse)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if banana != nil {
            if banana.position.y < -1000{
                banana.removeFromParent()
                banana = nil
                
                changePlayer()
            }
        }
        //updates the score
        self.viewController.player1ScoreLbl.text = "Player 1: \(self.viewController.player1Score)"
        self.viewController.player2ScoreLbl.text = "Player 2: \(self.viewController.player2Score)"
        
        //checks if one of the players has scored 3 times already, and if so, an alert controller is launched saying who won and asking if you want to play again
        if self.viewController.player1Score == 3 && self.viewController.player2Score < 3 {
            let ac = UIAlertController(title: "Player 1 Wins", message: "Would you like to play again?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Yes", style: .default) {
                [unowned self] _ in
                self.currentPlayer = 1
                //resets scores back to 0 for the new game
                self.viewController.player1Score = 0
                self.viewController.player2Score = 0
            })
            ac.addAction(UIAlertAction(title: "No", style: .cancel))
            self.viewController.present(ac, animated: true, completion: nil)
        } else if self.viewController.player2Score == 3 && self.viewController.player1Score < 3 {
            let ac = UIAlertController(title: "Player 2 Wins", message: "Would you like to play again?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Yes", style: .default) {
                [unowned self] _ in
                self.currentPlayer = 1
                //resets scores back to 0 for the new game
                self.viewController.player1Score = 0
                self.viewController.player2Score = 0
                
            })
            ac.addAction(UIAlertAction(title: "No", style: .cancel){
                [unowned ac] _ in
                ac.dismiss(animated: true, completion: nil)
            })
            self.viewController.present(ac, animated: true, completion: nil)
        }
    }
}
