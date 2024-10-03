import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // Layers (nodes)
    var boidsLayer = SKNode() // Ändra till SKNode för enklare hantering
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    
    // Boids och Predators
    var boids: [Boid] = []
    var predators: [Boid] = []
    
    // Timer för att köra simuleringen
    var simulationTimer: Timer?
    
    // boidConfig
    var config = BoidsConfig()
    
    override func didMove(to view: SKView) {
        // Sätt scenens storlek till vyens storlek
        self.size = view.frame.size
        // Ställ in scenens anchorPoint så att (0, 0) är i nedre vänstra hörnet
        self.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Set up the screen width and height based on the safe area
        if let safeArea = view.window?.safeAreaInsets {
            screenWidth = view.frame.size.width - safeArea.left - safeArea.right
            screenHeight = view.frame.size.height - safeArea.top - safeArea.bottom
        } else {
            // Fallback in case safe area is not available
            screenWidth = view.frame.size.width
            screenHeight = view.frame.size.height
        }
        
        print("Scene Size: \(self.size.width), \(self.size.height)")
        print("View Frame: \(view.frame.size.width), \(view.frame.size.height)")
        
        setUpLayers()
        generateBoidsAndPredators()
        
        // Starta simuleringen
        startSimulation()
    }
    
    private func setUpLayers() {
        // Placera `boidsLayer` i origo
        boidsLayer.position = CGPoint(x: 0, y: 0)
        // Lägg till boidsLayer till scenen
        self.addChild(boidsLayer)
    }
    
    // Funktion för att generera 20 boids och 2 predatorer
    func generateBoidsAndPredators() {
        let numberOfBoids = self.config.numberOfBoids
        let numberOfPredators = self.config.numberOfPredators
        
        // Generera boider och lägg dem i boids-arrayen
        for _ in 0..<numberOfBoids {
            let boid = Boid(position: Vector3(x: CGFloat.random(in: 0...screenWidth),
                                              y: CGFloat.random(in: 0...screenHeight), z: 0),
                            velocity: Vector3(x: CGFloat.random(in: -1...1),
                                              y: CGFloat.random(in: -1...1), z: 0))
            boids.append(boid)
            let boidNode = createBoidNode(isPredator: false)
            boidNode.position = CGPoint(x: boid.position.x, y: boid.position.y)
            boidsLayer.addChild(boidNode)
        }
        
        // Generera predatorer och lägg dem i predators-arrayen
        for _ in 0..<numberOfPredators {
            let predator = Boid(position: Vector3(x: CGFloat.random(in: 0...screenWidth),
                                                  y: CGFloat.random(in: 0...screenHeight), z: 0),
                                velocity: Vector3(x: CGFloat.random(in: -1...1),
                                                  y: CGFloat.random(in: -1...1), z: 0))
            predators.append(predator)
            let predatorNode = createBoidNode(isPredator: true)
            predatorNode.position = CGPoint(x: predator.position.x, y: predator.position.y)
            boidsLayer.addChild(predatorNode)
        }
    }
    
    // Starta simuleringen med en timer
    func startSimulation() {
        simulationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(runSimulation), userInfo: nil, repeats: true)
    }
    
    // Funktion för att köra simuleringen
    @objc func runSimulation() {
        // Skapa en BoidFlocking-instans för att hantera flockbeteendet
        let config = BoidsConfig() // Standardvärden eller anpassade värden
        let boidFlocking = BoidFlocking(boids: boids, predators: predators, screenWidth: screenWidth, screenHeight: screenHeight, config: config)
        
        // Uppdatera alla boider
        boidFlocking.updateAllBoids()
        boidFlocking.updateAllPredators()
        
        // Uppdatera alla noder i scenen med de nya positionerna och rotationerna
        for (index, boid) in boids.enumerated() {
            if let boidNode = boidsLayer.children[index] as? SKShapeNode {
                boidNode.position = CGPoint(x: boid.position.x, y: boid.position.y)
                
                // Beräkna vinkeln för rotation baserat på hastigheten
                let angle = atan2(boid.velocity.y, boid.velocity.x) - CGFloat.pi / 2
                boidNode.zRotation = angle
                
                // Ta bort existerande ringar om de finns
                boidNode.childNode(withName: "alignmentCircle")?.removeFromParent()
                boidNode.childNode(withName: "avoidanceCircle")?.removeFromParent()
                boidNode.childNode(withName: "cohesionCircle")?.removeFromParent()
                
                // Lägg till nya ringar för att visa perceptionradier
                //addPerceptionRings(to: boidNode, config: config)
            }
        }
        for (index, predator) in predators.enumerated() {
            if let predatorNode = boidsLayer.children[boids.count + index] as? SKShapeNode {
                predatorNode.position = CGPoint(x: predator.position.x, y: predator.position.y)
                
                // Beräkna vinkeln för rotation baserat på hastigheten
                let angle = atan2(predator.velocity.y, predator.velocity.x) - CGFloat.pi / 2
                predatorNode.zRotation = angle
            }
        }
    }
    func addPerceptionRings(to boidNode: SKShapeNode, config: BoidsConfig) {
        // Alignment-ring
        let alignmentCircle = SKShapeNode(circleOfRadius: config.alignmentRange)
        alignmentCircle.strokeColor = .green
        alignmentCircle.lineWidth = 1
        alignmentCircle.name = "alignmentCircle"
        alignmentCircle.zPosition = -1
        alignmentCircle.alpha = 0.5 // Gör cirkeln halvtransparent
        boidNode.addChild(alignmentCircle)
        
        // Avoidance-ring
        let avoidanceCircle = SKShapeNode(circleOfRadius: config.avoidanceRange)
        avoidanceCircle.strokeColor = .red
        avoidanceCircle.lineWidth = 1
        avoidanceCircle.name = "avoidanceCircle"
        avoidanceCircle.zPosition = -2
        avoidanceCircle.alpha = 0.5
        boidNode.addChild(avoidanceCircle)
        
        // Cohesion-ring
        let cohesionCircle = SKShapeNode(circleOfRadius: config.cohesionRange)
        cohesionCircle.strokeColor = .blue
        cohesionCircle.lineWidth = 1
        cohesionCircle.name = "cohesionCircle"
        cohesionCircle.zPosition = -3
        cohesionCircle.alpha = 0.5
        boidNode.addChild(cohesionCircle)
        
        // Predator Avoidance-ring
        let predatorAvoidanceCircle = SKShapeNode(circleOfRadius: config.fleeRange)
        predatorAvoidanceCircle.strokeColor = .purple
        predatorAvoidanceCircle.lineWidth = 1
        predatorAvoidanceCircle.name = "predatorAvoidanceCircle"
        predatorAvoidanceCircle.zPosition = -4
        predatorAvoidanceCircle.alpha = 0.5
        boidNode.addChild(predatorAvoidanceCircle)
    }
    // Funktion för att skapa en boid eller predator
    /*func createBoidNode(isPredator: Bool = false) -> SKShapeNode {
     let node = SKShapeNode()
     let path = CGMutablePath()
     
     if isPredator {
     path.move(to: CGPoint(x: 0, y: 7))
     path.addLine(to: CGPoint(x: -4, y: -4))
     path.addLine(to: CGPoint(x: 4, y: -4))
     node.fillColor = .blue
     node.strokeColor = .black
     } else {
     path.move(to: CGPoint(x: 0, y: 5))
     path.addLine(to: CGPoint(x: -3, y: -3))
     path.addLine(to: CGPoint(x: 3, y: -3))
     node.fillColor = .orange
     node.strokeColor = .red
     }
     
     path.closeSubpath()
     node.path = path
     node.zRotation = 0
     
     return node
     }*/
    func createBoidNode(isPredator: Bool = false) -> SKShapeNode {
        let boidNode = SKShapeNode()
        
        // Skapa triangeln som representerar boiden eller predatorn
        let path = CGMutablePath()
        if isPredator {
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: -6, y: -6))
            path.addLine(to: CGPoint(x: 6, y: -6))
        } else {
            path.move(to: CGPoint(x: 0, y: 5))
            path.addLine(to: CGPoint(x: -3, y: -3))
            path.addLine(to: CGPoint(x: 3, y: -3))
        }
        path.closeSubpath()
        
        boidNode.path = path
        boidNode.fillColor = isPredator ? .red : .white
        boidNode.strokeColor = isPredator ? .white : .red
        boidNode.zRotation = 0
        
        // Lägg till perceptionringar för predatorer eller boider baserat på config
        if isPredator {
            if(config.showPredatorOuterRing){
                // Lägg till yttre och inre jaktperceptionsringar för predatorer
                let outerChaseRing = SKShapeNode(circleOfRadius: config.predatorVisualRange)
                outerChaseRing.strokeColor = .purple
                outerChaseRing.lineWidth = 1
                outerChaseRing.name = "outerChaseRing"
                outerChaseRing.zPosition = -1
                outerChaseRing.alpha = 0.5
                boidNode.addChild(outerChaseRing)
            }
            
            if(config.showPredatorInnerRing){
                let innerChaseRing = SKShapeNode(circleOfRadius: config.predatorHuntingRange)
                innerChaseRing.strokeColor = .magenta
                innerChaseRing.lineWidth = 1
                innerChaseRing.name = "innerChaseRing"
                innerChaseRing.zPosition = -2
                innerChaseRing.alpha = 0.5
                boidNode.addChild(innerChaseRing)
            }
            
        } else {
            // Lägg till perceptionringar för boider om de är aktiverade i config
            if config.showAvoidanceRange {
                let avoidanceRing = SKShapeNode(circleOfRadius: config.avoidanceRange)
                avoidanceRing.strokeColor = .red
                avoidanceRing.alpha = 0.3
                avoidanceRing.lineWidth = 1
                avoidanceRing.name = "avoidanceRing"
                boidNode.addChild(avoidanceRing)
            }
            
            if config.showAlignmentRange {
                let alignmentRing = SKShapeNode(circleOfRadius: config.alignmentRange)
                alignmentRing.strokeColor = .cyan
                alignmentRing.alpha = 0.3
                alignmentRing.lineWidth = 1
                alignmentRing.name = "alignmentRing"
                boidNode.addChild(alignmentRing)
            }
            
            if config.showCohesionRange {
                let cohesionRing = SKShapeNode(circleOfRadius: config.cohesionRange)
                cohesionRing.strokeColor = .green
                cohesionRing.alpha = 0.3
                cohesionRing.lineWidth = 1
                cohesionRing.name = "cohesionRing"
                boidNode.addChild(cohesionRing)
            }
            
            if config.showFleeRange {
                let fleeRing = SKShapeNode(circleOfRadius: config.fleeRange)
                fleeRing.strokeColor = .systemPink
                fleeRing.alpha = 0.3
                fleeRing.lineWidth = 1
                fleeRing.name = "fleeRing"
                boidNode.addChild(fleeRing)
            }
        }
        
        return boidNode
    }
}
