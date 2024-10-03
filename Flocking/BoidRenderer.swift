//
//  BoidRenderer.swift
//  Flocking
//
//  Created by Andreas Olausson on 2024-10-02.
//
import SpriteKit

class BoidRenderer {
    func createNode(isPredator: Bool = false) -> SKShapeNode {
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
    }
}
