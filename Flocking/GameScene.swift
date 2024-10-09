import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // Layers (nodes)
    var boidsLayer = SKSpriteNode() // Ändra till SKNode för enklare hantering
    var backgroundLayer = SKSpriteNode()
    var imageLayer = SKSpriteNode()
    var artBackLayer = SKSpriteNode()
    var artLayer = SKSpriteNode()
    var settingsLayer = SKSpriteNode()
       

    var canvasTexture: SKTexture?
    var canvasSprite: SKSpriteNode?
    var canvasContext: CGContext?
    var canvasImageView: UIImageView?

    func setupCanvasImageView() {
        let canvasSize = CGSize(width: screenWidth, height: screenHeight)
        canvasImageView = UIImageView(frame: CGRect(origin: .zero, size: canvasSize))
        canvasImageView?.backgroundColor = .clear

        if let view = self.view, let canvas = canvasImageView {
            view.addSubview(canvas)
        }
    }
    
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    
    // Boids och Predators
    var boids: [Boid] = []
    var predators: [Boid] = []
    
    // Timer för att köra simuleringen
    var simulationTimer: Timer?
    var isPlaying: Bool = false // Default = don't fly
    
    // boidConfig
    var config = BoidsConfig()
    
    
    //Image stuff
    var iterationCount = 0
    var collectedCurves: [ArtCurves] = []
    let brushManager = BrushManager()

    
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
        
        setUpLayers()
        initializeCanvas()
        setupCanvasImageView()
        initializeCanvasImageView()
        generateBoidsAndPredators()
        
        // Starta simuleringen
        //startSimulation()
    }
    
    private func setUpLayers() {
        
        boidsLayer.size = CGSize(width: screenWidth, height: screenHeight)
        backgroundLayer.size = CGSize(width: screenWidth, height: screenHeight)
        imageLayer.size = CGSize(width: screenWidth, height: screenHeight)
        artBackLayer.size = CGSize(width: screenWidth, height: screenHeight)
        artLayer.size = CGSize(width: screenWidth, height: screenHeight)
        settingsLayer.size = CGSize(width: screenWidth, height: screenHeight)
        
        
        // Placera `boidsLayer` i origo
        boidsLayer.position = CGPoint(x: 0, y: 0)
        backgroundLayer.position = CGPoint(x: 0, y: 0)
        imageLayer.position = CGPoint(x: 0, y: 0)
        artBackLayer.position = CGPoint(x: 0, y: 0)
        //artLayer.position = CGPoint(x: (screenWidth / 2), y: (screenHeight / 2))
        artLayer.position = CGPoint(x: 0, y: 0)

        
        settingsLayer.position = CGPoint(x: 0, y: 0)
        
        // z-index
        backgroundLayer.zPosition = 0
        imageLayer.zPosition = 1
        artBackLayer.zPosition = 2
        artLayer.zPosition = 3
        boidsLayer.zPosition = 4
        settingsLayer.zPosition = 5
        
        // Lägg till boidsLayer till scenen
        self.addChild(backgroundLayer)
        self.addChild(imageLayer)
        self.addChild(artBackLayer)
        self.addChild(artLayer)
        self.addChild(boidsLayer)
        self.addChild(settingsLayer)
    }
    func initializeCanvas() {
        let canvasSize = CGSize(width: screenWidth, height: screenHeight)
        
        // Skapa en ny context och fyll den med en tom bakgrund
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(CGRect(origin: .zero, size: canvasSize))
        }
        
        // Skapa en initial tom bild från canvasen
        if let initialImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasTexture = SKTexture(image: initialImage)
        }
        
        UIGraphicsEndImageContext()
        
        // Lägg till canvasSprite på scenen
        let sprite = SKSpriteNode(texture: canvasTexture)
        sprite.position = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        sprite.size = canvasSize
        sprite.zPosition = 1
        artLayer.addChild(sprite)
        canvasSprite = sprite
    }
    
    public func toggleBoidMovement() {
        if isPlaying {
            stopSimulation()
        } else {
            startSimulation()
        }
        isPlaying.toggle() // Växla mellan play/pause
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
    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
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
                
                var positionColor: UIColor? = .clear
                positionColor = getPixelColor(at: boid.position.toCGPoint())

                if let color = positionColor, let components = color.getRGBAComponents() {
                    boid.coloredPositionHistory.append(ColoredPoint(position: CGPoint(x: boid.position.x, y: boid.position.y), red: components.red, green: components.green, blue: components.blue))
                }
                
                // Begränsa storleken på historiken till de senaste 10 punkterna
                if boid.coloredPositionHistory.count > 5 {
                    boid.coloredPositionHistory.removeFirst()
                }
                
                //drawNaturalCurve(for: boid, color: positionColor ?? .clear)
                //collectCurves(for: boid)
                //drawAndDisplayCollectedCurves()
                if(config.doPaint) {
                    drawNaturalCurveOnCanvas(for: boid, color: positionColor ?? .clear)
                }
                
                
                
                
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
    
    
    
    
    
    func addImage(_ image: UIImage) {
        // Hämta skärmens storlek
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        
        // Bildens ursprungliga storlek
        let imageSize = image.size
        
        // Beräkna skalfaktorn för att täcka hela skärmen
        let widthScale = screenWidth / imageSize.width
        let heightScale = screenHeight / imageSize.height
        let scale = max(widthScale, heightScale) // Välj den större skalan för att täcka hela skärmen
        
        // Beräkna den nya storleken baserat på skalan
        let newWidth = imageSize.width * scale
        let newHeight = imageSize.height * scale
        
        // Skapa en SKSpriteNode med den nya storleken
        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: newWidth, height: newHeight)
        
        // Centrera bilden på skärmen
        sprite.position = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        
        // Sätt anchorPoint för att centrera bilden korrekt
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Lägg till spriteNode till scenen
        imageLayer.addChild(sprite)
        
        // Lägg till cache här
        let cacheKey = "myImage"
        ImageCache.shared.storeImage(image, forKey: cacheKey)
        
    }
    
    
    
    
    
    
    //Image handling
    func getPixelColor(at position: CGPoint) -> UIColor? {
        // Hämta bilden från cachen
        guard let cachedImage = ImageCache.shared.image(forKey: "myImage") else { return nil }
        
        // Bildens storlek
        let imageSize = cachedImage.size
        let imageWidth = imageSize.width
        let imageHeight = imageSize.height
        
        // Justera positionen för att matcha bildens koordinatsystem (om det behövs)
        let adjustedYPosition = imageHeight - position.y
        
        // Beräkna positionen i bildens koordinatsystem
        let adjustedPosition = CGPoint(x: position.x, y: adjustedYPosition)
        
        // Använd pixelColor-funktionen för att hämta färgen
        return pixelColor(atPoint: adjustedPosition, inImage: cachedImage)
    }
    func pixelColor(atPoint point: CGPoint, inImage image: UIImage) -> UIColor? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        
        
        // Kontrollera att punkten är inom bilden
        guard point.x >= 0 && point.x < CGFloat(width), point.y >= 0 && point.y < CGFloat(height) else { return nil }
        
        // Räkna ut indexet i pixeldata
        let offset = 4 * ((width * Int(point.y)) + Int(point.x))
        let data = cgImage.dataProvider!.data
        let dataPtr: UnsafePointer<UInt8> = CFDataGetBytePtr(data)
        
        // Hämta RGBA-värden
        let red = CGFloat(dataPtr[offset]) / 255.0
        let green = CGFloat(dataPtr[offset + 1]) / 255.0
        let blue = CGFloat(dataPtr[offset + 2]) / 255.0
        alpha = CGFloat(dataPtr[offset + 3]) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    func drawNaturalCurve(for boid: Boid, color: UIColor = .clear) {
        // Öka iterationCount för varje ny kurva
        iterationCount += 1
        let history = boid.coloredPositionHistory
        
        // Kolla att vi har minst 4 punkter
        guard history.count >= 4 else { return }
        
        let path = UIBezierPath()
        
        // Starta från den tredje senaste punkten (en bit bak i historiken)
        path.move(to: history[history.count - 3].position)
        
        // Lägg till en Bezier-kurva med kontrollpunkter och slutpunkt
        let controlPoint1 = history[history.count - 2]
        let controlPoint2 = history[history.count - 1]
        let endPoint = boid.position // Boidens nuvarande position
        
        path.addCurve(to: endPoint.toCGPoint(), controlPoint1: controlPoint1.position, controlPoint2: controlPoint2.position)
        
        // Skapa en SKShapeNode för kurvan
        let curve = SKShapeNode(path: path.cgPath)
        
        // Sätt kurvans färg till samma som bakgrunden
        curve.strokeColor = color.withAlphaComponent(0.5)
        curve.lineWidth = 5
        curve.glowWidth = 2
        curve.isAntialiased = true
        
        // Lägg till kurvan till artNode
        //artLayer.addChild(curve)
    }
    func collectCurves(for boid: Boid) {
        // Kontrollera att det finns minst 4 punkter i historiken
        guard boid.coloredPositionHistory.count >= 4 else { return }
        
        // Hämta de 4 sista punkterna från historiken
        let lastFourPoints = boid.coloredPositionHistory.suffix(4)
        
        // Skapa en UIBezierPath
        let path = UIBezierPath()
        
        // Starta kurvan vid den första punkten
        if let firstPoint = lastFourPoints.first {
            path.move(to: firstPoint.position)
        }
        
        // Använd de återstående punkterna för att skapa en Bézier-kurva
        if lastFourPoints.count >= 4 {
            let points = Array(lastFourPoints)
            
            // Skapa Bézier-kurvan med fyra punkter
            path.addCurve(
                to: points[3].position,
                controlPoint1: points[1].position,
                controlPoint2: points[2].position
            )
        }
        
        // Flippa kurvan vertikalt för att matcha SpriteKit's koordinatsystem
        let imageSize = self.size
        let flippedPath = flipVertical(for: path, imageSize: imageSize)
        
        // Hämta färgen från den senaste punkten
        if let lastColoredPoint = lastFourPoints.last {
            let red = CGFloat(lastColoredPoint.red)
            let green = CGFloat(lastColoredPoint.green)
            let blue = CGFloat(lastColoredPoint.blue)
            let color = UIColor(red: red, green: green, blue: blue, alpha: 0.5)
            
            // Skapa en ArtCurves-instans med den flippade kurvan och färgen
            let brush = BrushManager().getBrush(for: Float(iterationCount))
            
            let curve = ArtCurves(path: flippedPath, color: color, brush: brush)
            collectedCurves.append(curve)
        }
    }

    func flipVertical(for path: UIBezierPath, imageSize: CGSize) -> UIBezierPath {
        let flippedPath = UIBezierPath()

        // Iterera genom alla element i originalvägen
        path.cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            var points = [CGPoint](repeating: .zero, count: 3)

            switch element.type {
            case .moveToPoint:
                points[0] = element.points[0]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaten
                flippedPath.move(to: points[0])
                
            case .addLineToPoint:
                points[0] = element.points[0]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaten
                flippedPath.addLine(to: points[0])
                
            case .addQuadCurveToPoint:
                points[0] = element.points[0]
                points[1] = element.points[1]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaterna
                points[1].y = imageSize.height - points[1].y
                flippedPath.addQuadCurve(to: points[0], controlPoint: points[1])
                
            case .addCurveToPoint:
                points[0] = element.points[0]
                points[1] = element.points[1]
                points[2] = element.points[2]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaterna
                points[1].y = imageSize.height - points[1].y
                points[2].y = imageSize.height - points[2].y
                flippedPath.addCurve(to: points[0], controlPoint1: points[1], controlPoint2: points[2])
                
            case .closeSubpath:
                flippedPath.close()
                
            @unknown default:
                break
            }
        }

        return flippedPath
    }
    
    func drawAndDisplayCollectedCurves2() {
        // Skapa en textur från samlade kurvor
        let texture = mergeCurvesIntoTexture(curves: collectedCurves)
        
        // Skapa en nod med texturen
        let combinedNode = SKSpriteNode(texture: texture)
        
        // Lägg till den på scenen, exempelvis i artBackNode
        artBackLayer.addChild(combinedNode)
        
        // Rensa gamla noder om nödvändigt
        artLayer.removeAllChildren()
        
        // Töm arrayen med samlade kurvor
        collectedCurves.removeAll()
    }
    func drawAndDisplayCollectedCurves() {
        // Instead of merging into a texture, use SKShapeNode for each curve
        for curve in collectedCurves {
            let curveNode = SKShapeNode(path: curve.path.cgPath)
            curveNode.strokeColor = curve.color
            curveNode.lineWidth = curve.brush.strokeSize
            curveNode.alpha = curve.brush.opacity
            curveNode.isAntialiased = curve.brush.antiAliasing
            artBackLayer.addChild(curveNode)
        }
        
        // Clear the collected curves to avoid rendering them again
        collectedCurves.removeAll()
        
        // Optionally, you can control the number of nodes to avoid excessive drawing
        while artBackLayer.children.count > 100 {
            artBackLayer.children[0].removeFromParent() // Remove the oldest nodes if necessary
        }
    }

    func mergeCurvesIntoTexture(curves: [ArtCurves]) -> SKTexture {
        let size = CGSize(width: artBackLayer.frame.width, height: artBackLayer.frame.height) // Anpassa storleken efter ditt behov
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0) // Anti-aliasing och högre upplösning
        
        for curve in curves {
            let brush = curve.brush
            
            // Applicera penselns egenskaper på kurvan
            curve.path.lineWidth = brush.strokeSize // Sätt linjebredd direkt på path
            
            // Ställ in färg och opacitet för stroke
            let strokeColor = curve.color.withAlphaComponent(brush.opacity)
            strokeColor.setStroke()
            
            // Rita kurvan
            curve.path.stroke()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image!)
    }
    func drawNaturalCurveOnCanvas_old(for boid: Boid, color: UIColor = .clear) {
        guard let canvasImageView = canvasImageView else {
            return
        }

        // Get the brush based on iteration count
        let brush = brushManager.getBrush(for: Float(iterationCount))
        iterationCount += 1

        // Get the current image of the canvas
        let size = canvasImageView.frame.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }

        // Draw the existing image onto the context
        canvasImageView.image?.draw(in: CGRect(origin: .zero, size: size))

        // Get the boid's position history
        let history = boid.coloredPositionHistory
        guard history.count >= 4 else {
            UIGraphicsEndImageContext()
            return
        }

        // Draw the new curve
        let path = UIBezierPath()
        path.move(to: history[history.count - 3].position)
        let controlPoint1 = history[history.count - 2]
        let controlPoint2 = history[history.count - 1]
        let endPoint = boid.position

        path.addCurve(to: endPoint.toCGPoint(), controlPoint1: controlPoint1.position, controlPoint2: controlPoint2.position)

        // Apply anti-aliasing if required
        context.setAllowsAntialiasing(brush.antiAliasing)
        context.setShouldAntialias(brush.antiAliasing)

        // Draw the glow effect if glowSize > 0
        if brush.glowSize > 0 {
            for i in 1...Int(brush.glowSize) {
                let glowColor = color.withAlphaComponent(brush.opacity / CGFloat(i + 1))
                glowColor.setStroke()
                path.lineWidth = brush.strokeSize + CGFloat(i)
                path.stroke()
            }
        }

        // Draw the main path with the specified brush properties
        color.withAlphaComponent(brush.opacity).setStroke()
        path.lineWidth = brush.strokeSize
        path.stroke()

        // Get the new image and assign it to the canvas image view
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = newImage
        }

        // End the image context
        UIGraphicsEndImageContext()
    }
    func drawNaturalCurveOnCanvas(for boid: Boid, color: UIColor = .clear) {
        
        guard let canvasImageView = canvasImageView else {
            print("Canvas image view is nil")
            return
        }

        // Get the current canvas image
        guard let currentImage = canvasImageView.image else {
            print("Current canvas image is nil, should not happen after initialization")
            return
        }
        // Get the brush based on iteration count
            let brush = brushManager.getBrush(for: Float(iterationCount))
        iterationCount += 1
        

        // Set up the drawing context
        let size = canvasImageView.frame.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        // Draw the existing image onto the context
        currentImage.draw(in: CGRect(origin: .zero, size: size))

        // Get the boid's position history
        let history = boid.coloredPositionHistory
        guard history.count >= 4 else {
            print("Insufficient position history for drawing. History count: \(history.count)")
            UIGraphicsEndImageContext()
            return
        }
        //ny
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }
        
        // Create a new path for the curve
        let path = UIBezierPath()
        let startPoint = CGPoint(x: history[history.count - 3].position.x, y: size.height - history[history.count - 3].position.y)
        path.move(to: startPoint)

        let controlPoint1 = CGPoint(x: history[history.count - 2].position.x, y: size.height - history[history.count - 2].position.y)
        let controlPoint2 = CGPoint(x: history[history.count - 1].position.x, y: size.height - history[history.count - 1].position.y)
        let endPoint = CGPoint(x: boid.position.x, y: size.height - boid.position.y)

        path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        
        //ny
        // Apply anti-aliasing if required
        context.setAllowsAntialiasing(brush.antiAliasing)
        context.setShouldAntialias(brush.antiAliasing)
        
        // Draw the glow effect if glowSize > 0
        if brush.glowSize > 0 {
            for i in 1...Int(brush.glowSize) {
                let glowColor = color.withAlphaComponent(brush.opacity / CGFloat(i + 1))
                glowColor.setStroke()
                path.lineWidth = brush.strokeSize + CGFloat(i)
                path.stroke()
            }
        }
        
        

        // Set path properties and draw the stroke
        color.withAlphaComponent(brush.opacity).setStroke()
        path.lineWidth = brush.strokeSize
        path.stroke()

        // Get the updated image and set it back to the canvas
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = newImage
        } else {
            print("Failed to get new image from current context")
        }

        // End the image context
        UIGraphicsEndImageContext()
    }
    func initializeCanvasImageView() {
        guard let canvasImageView = canvasImageView else {
            return
        }

        let size = canvasImageView.frame.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.clear.setFill()  // Set the initial image to be transparent
        UIRectFill(CGRect(origin: .zero, size: size))  // Fill the context with the clear color

        if let initialImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = initialImage
        } else {
            print("Failed to create initial canvas image")
        }

        UIGraphicsEndImageContext()
    }
}
