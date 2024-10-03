//
//  Boid.swift
//  Flocking
//
//  Created by Andreas Olausson on 2024-10-01.
//

import SpriteKit

struct Vector3 {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    
    static func +(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    static func -(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    static func *(lhs: Vector3, rhs: CGFloat) -> Vector3 {
        return Vector3(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    static func /(lhs: Vector3, rhs: CGFloat) -> Vector3 {
        return Vector3(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }

    static func +=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs + rhs
    }

    static func -=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs - rhs
    }

    static func /=(lhs: inout Vector3, rhs: CGFloat) {
        lhs = lhs / rhs
    }

    func magnitude() -> CGFloat {
        return sqrt(x * x + y * y + z * z)
    }

    func normalized() -> Vector3 {
        let mag = magnitude()
        return mag > 0 ? self / mag : Vector3(x: 0, y: 0, z: 0)
    }

    func distance(to vector: Vector3) -> CGFloat {
        return (self - vector).magnitude()
    }
}

struct PositionHistory {
    var position: Vector3
    var color: SKColor
}
struct BoidsConfig {
    var numberOfBoids = 150
    var numberOfPredators = 1
    var speedFactor: CGFloat = 1.0

    var maxSpeed: CGFloat
    var avoidanceRange: CGFloat
    var alignmentRange: CGFloat
    var cohesionRange: CGFloat
    var fleeRange: CGFloat
    var edgeThreshold: CGFloat

    var avoidanceFactor: CGFloat
    var alignmentFactor: CGFloat
    var cohesionFactor: CGFloat
    var fleeFactor: CGFloat
    var edgeAvoidanceFactor: CGFloat

    var panicFlightSpeed: CGFloat
    var panicFlightRange: CGFloat
    var panicFlightWeight: CGFloat

    var predatorSpeed: CGFloat
    var predatorTurnSpeed: CGFloat
    var predatorVisualRange: CGFloat
    var predatorHuntingRange: CGFloat
    var predatorModerateSpeed: CGFloat
    var predatorAggressiveSpeed: CGFloat
    var predatorDriftFactor: CGFloat
    var predatorChaseRange: CGFloat

    var driftPercentage: CGFloat

    var showAlignmentRange: Bool
    var showAvoidanceRange: Bool
    var showCohesionRange: Bool
    var showFleeRange: Bool
    var showPredatorOuterRing: Bool
    var showPredatorInnerRing: Bool

    init(speedFactor: CGFloat = 1.0) {
        self.speedFactor = speedFactor
        
        print(speedFactor)
        print(self.speedFactor)

        // Använd speedFactor för att justera hastighetsrelaterade parametrar
        self.maxSpeed = 4.0 * speedFactor
        self.avoidanceRange = 12.0 * speedFactor
        self.alignmentRange = 28.0 * speedFactor
        self.cohesionRange = 71.0 * speedFactor
        self.fleeRange = 50.0 * speedFactor
        self.edgeThreshold = 100.0 * speedFactor

        self.avoidanceFactor = 1.0
        self.alignmentFactor = 0.44
        self.cohesionFactor = 0.08
        self.fleeFactor = 1.3
        self.edgeAvoidanceFactor = 2.0

        self.panicFlightSpeed = 4.0 * speedFactor
        self.panicFlightRange = 30.0 * speedFactor
        self.panicFlightWeight = 3.0

        self.predatorSpeed = 2.5 * speedFactor
        self.predatorTurnSpeed = 2.0 * speedFactor
        self.predatorVisualRange = 100.0 * speedFactor
        self.predatorHuntingRange = 25.0 * speedFactor
        self.predatorModerateSpeed = 1.5 * speedFactor
        self.predatorAggressiveSpeed = 3.0 * speedFactor
        self.predatorDriftFactor = 0.1
        self.predatorChaseRange = 150.0 * speedFactor

        self.driftPercentage = 0.1

        // Debugging settings
        self.showAlignmentRange = true
        self.showAvoidanceRange = true
        self.showCohesionRange = true
        self.showFleeRange = true
        self.showPredatorOuterRing = true
        self.showPredatorInnerRing = true
    }
}
class Boid {
    var position: Vector3
    var velocity: Vector3
    var positionHistory: [PositionHistory] = []

    init(position: Vector3, velocity: Vector3) {
        self.position = position
        self.velocity = velocity
    }

    // Funktion för att lägga till en ny position till historiken
    func addPositionToHistory(newPosition: Vector3, color: SKColor) {
        let newHistoryItem = PositionHistory(position: newPosition, color: color)
        
        // Lägg till den nya positionen till historiken
        positionHistory.append(newHistoryItem)
        
        // Begränsa historiken till att bara hålla de senaste 4 stegen
        if positionHistory.count > 4 {
            positionHistory.removeFirst()
        }
    }
}

class BoidFlocking {
    var boids: [Boid]
    var predators: [Boid]
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    var config: BoidsConfig

    init(boids: [Boid], predators: [Boid], screenWidth: CGFloat, screenHeight: CGFloat, config: BoidsConfig) {
        self.boids = boids
        self.predators = predators
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.config = config
    }
    func updateAllBoids() {
        for i in 0..<boids.count {
            updateBoid(boidIndex: i)
        }
    }
    func updateAllPredators() {
        for i in 0..<predators.count {
            updatePredator(predatorIndex: i)
        }
    }
    func updateBoid(boidIndex: Int) {
            var boid = boids[boidIndex]

            // Beräkna styrkrafter
            let alignment = align(boid: boid, boids: boids, alignmentRange: config.alignmentRange)
            let separation = avoid(boid: boid, boids: boids, avoidanceRange: config.avoidanceRange)
            let cohesion = attract(boid: boid, boids: boids, cohesionRange: config.cohesionRange)
            let flee = fleeFromPredator(boid: boid, predators: predators, fleeRange: config.fleeRange)

            // Dynamisk driftfaktor baserat på boidens maxhastighet
            let driftFactor = config.driftPercentage * (config.maxSpeed / 10.0)
            let randomDrift = randomSteering() * driftFactor

            // Kombinera alla styrkrafter med konfigurerade vikter
            var steering = alignment * config.alignmentFactor +
                           separation * config.avoidanceFactor +
                           cohesion * config.cohesionFactor +
                           flee * config.fleeFactor

            // Applicera kantvändningslogik precis innan uppdatering av hastighet och position
            let edgeSteering = turnWhenNearEdges(boid: boid, screenWidth: screenWidth, screenHeight: screenHeight, edgeThreshold: config.edgeThreshold, edgeAvoidanceFactor: config.edgeAvoidanceFactor)
            steering += edgeSteering

            // Uppdatera hastighet och position
            boid.velocity += steering

            // Begränsa hastigheten till maxhastigheten
            boid.velocity = boid.velocity.normalized() * config.maxSpeed
            boid.position += boid.velocity

            // Uppdatera positionhistoriken
            boid.addPositionToHistory(newPosition: boid.position, color: .orange)

            // Spara tillbaka den uppdaterade boiden i boids-arrayen
            boids[boidIndex] = boid
        }

        func updatePredator(predatorIndex: Int) {
            var predator = predators[predatorIndex]

            if let nearestBoid = findNearestBoid(to: predator, within: config.predatorVisualRange) {
                let distance = predator.position.distance(to: nearestBoid.position)

                if distance < config.predatorHuntingRange {
                    // Aggressiv jakt
                    let directionToBoid = (nearestBoid.position - predator.position).normalized()
                    predator.velocity = directionToBoid * config.predatorAggressiveSpeed
                } else if distance < config.predatorVisualRange {
                    // Börja vända sig mot boiden
                    let directionToBoid = (nearestBoid.position - predator.position).normalized()
                    predator.velocity += directionToBoid * config.predatorTurnSpeed
                    predator.velocity = predator.velocity.normalized() * config.predatorSpeed
                }
            } else {
                // Använd random drift om ingen boid är inom räckhåll
                let randomDrift = randomSteering() * config.predatorDriftFactor
                predator.velocity += randomDrift
                predator.velocity = predator.velocity.normalized() * config.predatorSpeed
            }

            // Tillämpa kantvändning
            let edgeSteering = turnWhenNearEdges(boid: predator, screenWidth: screenWidth, screenHeight: screenHeight, edgeThreshold: config.edgeThreshold, edgeAvoidanceFactor: config.edgeAvoidanceFactor)
            predator.velocity += edgeSteering

            predator.position += predator.velocity
            predators[predatorIndex] = predator
        }
    
    func panicEscape(boid: Boid, predators: [Boid], panicRange: CGFloat, chaseRange: CGFloat) -> Vector3 {
        var steering = Vector3(x: 0, y: 0, z: 0)
        var maxPanicStrength: CGFloat = 0.0

        for predator in predators {
            let distance = boid.position.distance(to: predator.position)

            if distance < panicRange {
                // Om boiden är i fara (ytterligare flyktområde)
                let avoidDirection = boid.position - predator.position
                let strengthFactor = pow((panicRange - distance) / panicRange, 2)

                if strengthFactor > maxPanicStrength {
                    maxPanicStrength = strengthFactor
                    steering = avoidDirection * strengthFactor
                }
            }

            if distance < chaseRange {
                // Om boiden är jagad, öka farten och lägg till variation
                let avoidDirection = (boid.position - predator.position).normalized()
                let randomEvasion = randomSteering() * 0.3 // Lägg till lite variation för att simulera manövrar
                steering += (avoidDirection + randomEvasion) * config.panicFlightSpeed
            }
        }

        if maxPanicStrength > 0 {
            // Använd panikhastighet för att ge en starkare impuls
            steering = steering.normalized() * (config.maxSpeed * config.panicFlightSpeed)
        }

        return steering
    }
    
    

    func findNearestBoid(to predator: Boid, within range: CGFloat) -> Boid? {
        var nearestBoid: Boid?
        var shortestDistance = range

        for boid in boids {
            let distance = predator.position.distance(to: boid.position)
            if distance < shortestDistance {
                shortestDistance = distance
                nearestBoid = boid
            }
        }

        return nearestBoid
    }

    func findNearestBoid(to predator: Boid) -> Boid? {
        var nearestBoid: Boid?
        var shortestDistance = CGFloat.greatestFiniteMagnitude

        for boid in boids {
            let distance = predator.position.distance(to: boid.position)
            if distance < shortestDistance {
                shortestDistance = distance
                nearestBoid = boid
            }
        }

        return nearestBoid
    }
    
    
    func clampVelocity(boid: inout Boid, maxSpeed: CGFloat) {
        if boid.velocity.magnitude() > maxSpeed {
            boid.velocity = boid.velocity.normalized() * maxSpeed
        }
    }
    func align(boid: Boid, boids: [Boid], alignmentRange: CGFloat) -> Vector3 {
        var steering = Vector3(x: 0, y: 0, z: 0)
        var total = 0
        
        for otherBoid in boids {
            let distance = boid.position.distance(to: otherBoid.position)
            if distance < alignmentRange && distance > 0 {
                steering += otherBoid.velocity
                total += 1
            }
        }
        
        if total > 0 {
            steering /= CGFloat(total)
            steering = steering.normalized() * boid.velocity.magnitude()
            steering -= boid.velocity
        }
        
        return steering
    }
    func avoid(boid: Boid, boids: [Boid], avoidanceRange: CGFloat) -> Vector3 {
        var steering = Vector3(x: 0, y: 0, z: 0)
        var total = 0
        
        for otherBoid in boids {
            let distance = boid.position.distance(to: otherBoid.position)
            if distance < avoidanceRange && distance > 0 {
                let difference = boid.position - otherBoid.position
                steering += difference / distance
                total += 1
            }
        }
        
        if total > 0 {
            steering /= CGFloat(total)
            steering = steering.normalized() * boid.velocity.magnitude()
        }
        
        return steering
    }
    func attract(boid: Boid, boids: [Boid], cohesionRange: CGFloat) -> Vector3 {
        var centerOfMass = Vector3(x: 0, y: 0, z: 0)
        var total = 0
        
        for otherBoid in boids {
            let distance = boid.position.distance(to: otherBoid.position)
            if distance < cohesionRange && distance > 0 {
                centerOfMass += otherBoid.position
                total += 1
            }
        }
        
        if total > 0 {
            centerOfMass /= CGFloat(total)
            let directionToCenter = centerOfMass - boid.position
            return directionToCenter.normalized() * boid.velocity.magnitude() - boid.velocity
        }
        
        return Vector3(x: 0, y: 0, z: 0)
    }
    func randomSteering() -> Vector3 {
        let randomX = CGFloat.random(in: -0.1...0.1)
        let randomY = CGFloat.random(in: -0.1...0.1)
        return Vector3(x: randomX, y: randomY, z: 0).normalized()
    }
    func turnWhenNearEdges(boid: Boid, screenWidth: CGFloat, screenHeight: CGFloat, edgeThreshold: CGFloat, edgeAvoidanceFactor: CGFloat) -> Vector3 {
        var steering = Vector3(x: 0, y: 0, z: 0)

        // Margin levels för att gradvis öka styrkraften när boiden närmar sig kanten
        let levels: [CGFloat] = [25, 20, 15, 10, 5] // Avståndsnivåer i px
        let angleAdjustments: [CGFloat] = [0.2, 0.4, 0.6, 0.8, 1.0] // Faktor för styrkraftsjustering

        // Hjälpfunktion för att beräkna styrkraft baserat på avstånd till kanten
        func calculateSteeringFactor(for distance: CGFloat, isIncreasing: Bool) -> CGFloat {
            for (index, level) in levels.enumerated() {
                if distance < level {
                    let factor = angleAdjustments[index]
                    return isIncreasing ? factor : -factor
                }
            }
            return 0
        }

        // Kolla hur nära boiden är vänster eller höger kant
        if boid.position.x < edgeThreshold {
            let distance = boid.position.x
            steering.x += calculateSteeringFactor(for: distance, isIncreasing: true) * edgeAvoidanceFactor
        } else if boid.position.x > screenWidth - edgeThreshold {
            let distance = screenWidth - boid.position.x
            steering.x += calculateSteeringFactor(for: distance, isIncreasing: false) * edgeAvoidanceFactor
        }

        // Kolla hur nära boiden är toppen eller botten
        if boid.position.y < edgeThreshold {
            let distance = boid.position.y
            steering.y += calculateSteeringFactor(for: distance, isIncreasing: true) * edgeAvoidanceFactor
        } else if boid.position.y > screenHeight - edgeThreshold {
            let distance = screenHeight - boid.position.y
            steering.y += calculateSteeringFactor(for: distance, isIncreasing: false) * edgeAvoidanceFactor
        }

        // Skalera styrningen baserat på boidens hastighet för att få en smidigare vändning
        return steering * boid.velocity.magnitude() * 0.1 // Justera multiplikatorn för att finjustera svängningen
    }
    

    func calculateSteeringStrength(distance: CGFloat, outerThreshold: CGFloat, innerThreshold: CGFloat) -> CGFloat {
        if distance > innerThreshold {
            return distance / outerThreshold // Styrkan ökar gradvis från 0 till 1
        } else {
            return 1.0 + ((innerThreshold - distance) / innerThreshold) // Ökar ytterligare utanför innerThreshold
        }
    }
    
    func fleeFromPredator(boid: Boid, predators: [Boid], fleeRange: CGFloat) -> Vector3 {
        var steering = Vector3(x: 0, y: 0, z: 0)
        var isFleeing = false

        for predator in predators {
            let distance = boid.position.distance(to: predator.position)
            if distance < fleeRange {
                // Vänd 180 grader från predatorn
                let difference = (boid.position - predator.position).normalized()
                steering += difference
                isFleeing = true
            }
        }

        if isFleeing {
            // Fyrdubbla hastigheten vid flykt
            steering = steering.normalized() * (config.maxSpeed * 4)
        }

        return steering
    }
}
