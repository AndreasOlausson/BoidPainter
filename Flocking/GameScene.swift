import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: - Properties
    // Layers (nodes)
    var boidsLayer = SKSpriteNode()
    private var backgroundLayer = SKSpriteNode()
    var imageLayer = SKSpriteNode()
    private var artBackLayer = SKSpriteNode()
    private var artLayer = SKSpriteNode()
    private var settingsLayer = SKSpriteNode()
    
    var canvasImageView: UIImageView?
    
    private var screenWidth: CGFloat = 0
    private var screenHeight: CGFloat = 0
    
    // Boids och Predators
    var boids: [Boid] = []
    var predators: [Boid] = []
    
    // Timer för att köra simuleringen
    private var simulationTimer: Timer?
    var isPlaying: Bool = false
    
    // BoidConfig
    private var config = BoidsConfig()
    
    // Image handling
    private var iterationCount = 0
    private var collectedCurves: [ArtCurves] = []
    private let brushManager = BrushManager()
    
    
    // MARK: - Lifecycle
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
        setupCanvasImageView()
        initializeCanvasImageView()
        generateBoidsAndPredators()
    }
    //
    public func generateBoidsAndPredators() {
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
            boidNode.zPosition=100
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
            predatorNode.zPosition = 100
            boidsLayer.addChild(predatorNode)
        }
    }
    
    public func toggleBoidMovement() {
        if isPlaying {
            stopSimulation()
        } else {
            startSimulation()
        }
        isPlaying.toggle() // Växla mellan play/pause
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
    private func setupCanvasImageView() {
        let canvasSize = CGSize(width: screenWidth, height: screenHeight)
        canvasImageView = UIImageView(frame: CGRect(origin: .zero, size: canvasSize))
        canvasImageView?.backgroundColor = .clear
        canvasImageView?.contentMode = .scaleAspectFill // Viktigt för att följa bildens skalning

        if let view = self.view, let canvas = canvasImageView {
            view.addSubview(canvas)
            canvas.center = CGPoint(x: screenWidth / 2, y: screenHeight / 2) // Centrerar kanvasen
            view.sendSubviewToBack(canvas)
        }
    }
    private func setupCanvasImageView2() {
        let canvasSize = CGSize(width: screenWidth, height: screenHeight)
        canvasImageView = UIImageView(frame: CGRect(origin: .zero, size: canvasSize))
        canvasImageView?.backgroundColor = .clear
        canvasImageView?.contentMode = .scaleAspectFit // Viktigt för att hålla proportioner

        if let view = self.view, let canvas = canvasImageView {
            view.addSubview(canvas)
        }
    }
    // Starta simuleringen med en timer
    private func startSimulation() {
        simulationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(runSimulation), userInfo: nil, repeats: true)
    }
    private func stopSimulation() {
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
                
                let defaultColor: UIColor = .clear
                let positionColor = getPixelColor(at: boid.position.toCGPoint()) ?? defaultColor

                if let components = positionColor.getRGBAComponents() {
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
                    drawNaturalCurveOnCanvas(for: boid, color: positionColor)
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
    

  
    private func createBoidNode(isPredator: Bool = false) -> SKShapeNode {
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
        
        // Beräkna skalfaktorn för att fylla hela skärmen
        let widthScale = screenWidth / imageSize.width
        let heightScale = screenHeight / imageSize.height
        let scale = max(widthScale, heightScale) // Välj den större skalan för att fylla hela skärmen
        
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
    func addImage_1(_ image: UIImage) {
        // Hämta skärmens storlek
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        
        // Bildens ursprungliga storlek
        let imageSize = image.size
        
        // Beräkna skalfaktorn för att täcka hela skärmen utan förvrängning
        let widthScale = screenWidth / imageSize.width
        let heightScale = screenHeight / imageSize.height
        let scale = min(widthScale, heightScale) // Välj den mindre skalan för att undvika att någon del klipps bort
        
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
    func addImage_old(_ image: UIImage) {
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
    private func getPixelColor(at position: CGPoint) -> UIColor? {
        // Hämta bilden från cachen
        guard let cachedImage = ImageCache.shared.image(forKey: "myImage") else { return nil }
        
        // Bildens storlek
        let imageSize = cachedImage.size
        let imageWidth = imageSize.width
        let imageHeight = imageSize.height
        
        // Justera positionen för att matcha bildens koordinatsystem
        let adjustedXPosition = position.x / screenWidth * imageWidth
        let adjustedYPosition = imageHeight - (position.y / screenHeight * imageHeight)
        
        let adjustedPosition = CGPoint(x: adjustedXPosition, y: adjustedYPosition)
        
        // Använd pixelColor-funktionen för att hämta färgen
        return pixelColor(atPoint: adjustedPosition, inImage: cachedImage)
    }
    private func pixelColor(atPoint point: CGPoint, inImage image: UIImage) -> UIColor? {
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
    private func flipVertical(for path: UIBezierPath, imageSize: CGSize) -> UIBezierPath {
        let flippedPath = UIBezierPath()

        // Debug: Print initial path details
        print("Original path: \(path)")

        // Iterera genom alla element i originalvägen
        path.cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            var points = [CGPoint](repeating: .zero, count: 3)

            switch element.type {
            case .moveToPoint:
                points[0] = element.points[0]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaten
                flippedPath.move(to: points[0])
                
                // Debug: Print the inverted moveToPoint
                print("Inverted moveToPoint: \(points[0])")
                
            case .addLineToPoint:
                points[0] = element.points[0]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaten
                flippedPath.addLine(to: points[0])
                
                // Debug: Print the inverted addLineToPoint
                print("Inverted addLineToPoint: \(points[0])")
                
            case .addQuadCurveToPoint:
                points[0] = element.points[0]
                points[1] = element.points[1]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaterna
                points[1].y = imageSize.height - points[1].y
                flippedPath.addQuadCurve(to: points[0], controlPoint: points[1])
                
                // Debug: Print the inverted addQuadCurveToPoint
                print("Inverted addQuadCurveToPoint: \(points[0]), controlPoint: \(points[1])")
                
            case .addCurveToPoint:
                points[0] = element.points[0]
                points[1] = element.points[1]
                points[2] = element.points[2]
                points[0].y = imageSize.height - points[0].y // Invertera y-koordinaterna
                points[1].y = imageSize.height - points[1].y
                points[2].y = imageSize.height - points[2].y
                flippedPath.addCurve(to: points[0], controlPoint1: points[1], controlPoint2: points[2])
                
                // Debug: Print the inverted addCurveToPoint
                print("Inverted addCurveToPoint: \(points[0]), controlPoint1: \(points[1]), controlPoint2: \(points[2])")
                
            case .closeSubpath:
                flippedPath.close()
                
            @unknown default:
                break
            }
        }

        // Debug: Print flipped path before applying transformation
        print("Flipped path before transformation: \(flippedPath)")

        // Omvandla hela banan enligt ditt behov (steg 4)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -imageSize.height)
        flippedPath.apply(transform)

        // Debug: Print the flipped and transformed path
        print("Flipped and transformed path: \(flippedPath)")

        return flippedPath
    }
    private func flipVertical_old(for path: UIBezierPath, imageSize: CGSize) -> UIBezierPath {
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
    
    private func drawAndDisplayCollectedCurves() {
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
    private func drawNaturalCurveOnCanvasxx(for boid: Boid, color: UIColor = .clear) {
        
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
        guard history.count >= 32 else {
            print("Insufficient position history for drawing. History count: \(history.count)")
            UIGraphicsEndImageContext()
            return
        }

        // Create a new path for the curve
        let path = UIBezierPath()
        let startPoint = CGPoint(x: history[0].position.x, y: size.height - history[0].position.y)
        path.move(to: startPoint)

        for i in stride(from: 1, to: 32, by: 3) {
            let controlPoint1 = CGPoint(x: history[i].position.x, y: size.height - history[i].position.y)
            let controlPoint2 = CGPoint(x: history[i + 1].position.x, y: size.height - history[i + 1].position.y)
            let endPoint = CGPoint(x: history[i + 2].position.x, y: size.height - history[i + 2].position.y)

            path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }

        // Apply anti-aliasing if required
        if let context = UIGraphicsGetCurrentContext() {
            context.setAllowsAntialiasing(brush.antiAliasing)
            context.setShouldAntialias(brush.antiAliasing)
        }

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
    private func drawNaturalCurveOnCanvasx(for boid: Boid, color: UIColor = .clear) {
        guard let canvasImageView = canvasImageView else {
            print("Canvas image view is nil")
            return
        }

        // Spara befintlig bild
        guard let currentImage = canvasImageView.image else {
            print("Current canvas image is nil")
            return
        }

        // Använd en gemensam bildkontext för alla boids
        UIGraphicsBeginImageContextWithOptions(canvasImageView.frame.size, false, 0.0)
        currentImage.draw(in: CGRect(origin: .zero, size: canvasImageView.frame.size))

        // Boidens historik
        let history = boid.coloredPositionHistory
        guard history.count >= 32 else {
            UIGraphicsEndImageContext()
            return
        }

        // Skapa en ny kurva
        let path = UIBezierPath()
        let startPoint = CGPoint(x: history[history.count - 3].position.x, y: canvasImageView.frame.size.height - history[history.count - 3].position.y)
        path.move(to: startPoint)

        let controlPoint1 = CGPoint(x: history[history.count - 2].position.x, y: canvasImageView.frame.size.height - history[history.count - 2].position.y)
        let controlPoint2 = CGPoint(x: history[history.count - 1].position.x, y: canvasImageView.frame.size.height - history[history.count - 1].position.y)
        let endPoint = CGPoint(x: boid.position.x, y: canvasImageView.frame.size.height - boid.position.y)

        path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)

        // Räkna ut glow och linjens bredd
        let brush = brushManager.getBrush(for: Float(iterationCount))
        iterationCount += 1

        // Optimera glow-effekten genom att minska antalet repetitioner
        if brush.glowSize > 0 {
            for i in 1...Int(brush.glowSize) {
                let glowColor = color.withAlphaComponent(brush.opacity / CGFloat(i + 1))
                glowColor.setStroke()
                path.lineWidth = brush.strokeSize + CGFloat(i)
                path.stroke()
            }
        }

        // Applicera stroke
        color.withAlphaComponent(brush.opacity).setStroke()
        path.lineWidth = brush.strokeSize
        path.stroke()

        // Uppdatera bilden på canvas
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = newImage
        }

        UIGraphicsEndImageContext()
    }
    private func drawNaturalCurveOnCanvas(for boid: Boid, color: UIColor = .clear) {
        guard let canvasImageView = canvasImageView else {
            print("Canvas image view is nil")
            return
        }

        // Get the current canvas image
        guard let currentImage = canvasImageView.image else {
            print("Current canvas image is nil, should not happen after initialization")
            return
        }
        
        // Hämta canvasens storlek
        let size = canvasImageView.frame.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        // Rita den existerande bilden på context
        currentImage.draw(in: CGRect(origin: .zero, size: size))

        // Hämta boidens position history
        let history = boid.coloredPositionHistory
        guard history.count >= 4 else {
            print("Insufficient position history for drawing. History count: \(history.count)")
            UIGraphicsEndImageContext()
            return
        }

        // Hämta ritningscontext
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }

        // Hämta borsten baserat på iterationCount
        let brush = brushManager.getBrush(for: Float(iterationCount))
        iterationCount += 1

        // Skapa en ny väg för kurvan
        let path = UIBezierPath()
        let startPoint = CGPoint(x: history[history.count - 3].position.x, y: size.height - history[history.count - 3].position.y)
        path.move(to: startPoint)

        let controlPoint1 = CGPoint(x: history[history.count - 2].position.x, y: size.height - history[history.count - 2].position.y)
        let controlPoint2 = CGPoint(x: history[history.count - 1].position.x, y: size.height - history[history.count - 1].position.y)
        let endPoint = CGPoint(x: boid.position.x, y: size.height - boid.position.y)

        path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)

        // Ställ in anti-aliasing om det behövs
        context.setAllowsAntialiasing(brush.antiAliasing)
        context.setShouldAntialias(brush.antiAliasing)

        // Rita glow-effekten om den är aktiv
        if brush.glowSize > 0 {
            for i in 1...Int(brush.glowSize) {
                let glowColor = color.withAlphaComponent(brush.opacity / CGFloat(i + 1))
                glowColor.setStroke()
                path.lineWidth = brush.strokeSize + CGFloat(i)
                path.stroke()
            }
        }

        // Rita själva kurvan med rätt strokeSize och opacity från brush
        color.withAlphaComponent(brush.opacity).setStroke()
        path.lineWidth = brush.strokeSize
        path.stroke()

        // Sätt den uppdaterade bilden tillbaka på canvasen
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = newImage
        }

        // Avsluta context
        UIGraphicsEndImageContext()
    }
    private func drawNaturalCurveOnCanvas_working(for boid: Boid, color: UIColor = .clear) {
        guard let canvasImageView = canvasImageView else {
            print("Canvas image view is nil")
            return
        }

        // Get the current canvas image
        guard let currentImage = canvasImageView.image else {
            print("Current canvas image is nil, should not happen after initialization")
            return
        }
        
        // Hämta canvasens storlek
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

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }

        // Skapa en ny väg för kurvan
        let path = UIBezierPath()
        let startPoint = CGPoint(x: history[history.count - 3].position.x, y: size.height - history[history.count - 3].position.y)
        path.move(to: startPoint)

        let controlPoint1 = CGPoint(x: history[history.count - 2].position.x, y: size.height - history[history.count - 2].position.y)
        let controlPoint2 = CGPoint(x: history[history.count - 1].position.x, y: size.height - history[history.count - 1].position.y)
        let endPoint = CGPoint(x: boid.position.x, y: size.height - boid.position.y)

        path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)

        // Sätt path-egenskaper och rita
        color.withAlphaComponent(1.0).setStroke()
        path.lineWidth = 2.0
        path.stroke()

        // Sätt den uppdaterade bilden tillbaka på canvasen
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = newImage
        }

        UIGraphicsEndImageContext()
    }
    private func drawNaturalCurveOnCanvas2(for boid: Boid, color: UIColor = .clear) {
        
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
    private func initializeCanvasImageView() {
        guard let canvasImageView = canvasImageView else {
            return
        }

        // Set the content mode to match how the image is scaled (Aspect Fill)
        canvasImageView.contentMode = .scaleAspectFill
        canvasImageView.clipsToBounds = true

        // Align canvas to screen center
        canvasImageView.center = CGPoint(x: screenWidth / 2, y: screenHeight / 2)

        // Set the size to match the screen's aspect ratio
        let canvasSize = CGSize(width: screenWidth, height: screenHeight)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)
        
        // Set the initial image to be transparent
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: canvasSize))

        if let initialImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = initialImage
        } else {
            print("Failed to create initial canvas image")
        }

        UIGraphicsEndImageContext()
    }
    private func initializeCanvasImageView_halvbra() {
        guard let canvasImageView = canvasImageView else {
            return
        }
        
        // Sätt korrekt content mode för att behålla proportioner
        canvasImageView.contentMode = .scaleAspectFit
        canvasImageView.center = CGPoint(x: screenWidth / 2, y: screenHeight / 2)

        let size = canvasImageView.frame.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.clear.setFill()  // Gör bakgrunden transparent
        UIRectFill(CGRect(origin: .zero, size: size))  // Fyll context med den transparenta färgen

        if let initialImage = UIGraphicsGetImageFromCurrentImageContext() {
            canvasImageView.image = initialImage
        } else {
            print("Failed to create initial canvas image")
        }

        UIGraphicsEndImageContext()
    }
    private func initializeCanvasImageView_old() {
        guard let canvasImageView = canvasImageView else {
            return
        }
        
        // Set the content mode to scaleAspectFit to maintain the aspect ratio
        canvasImageView.contentMode = .scaleAspectFit
        canvasImageView.center = CGPoint(x: screenWidth / 2, y: screenHeight / 2)

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
