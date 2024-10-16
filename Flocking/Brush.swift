//
//  Brush.swift
//  Flocking
//
//  Created by Andreas Olausson on 2024-10-03.
//
import Foundation

struct Brush {
    var strokeSize: CGFloat
    var glowSize: CGFloat
    var antiAliasing: Bool
    var opacity: CGFloat
}

class BrushManager {
    func getBrush(for iterationCount: Float) -> Brush {
        print(iterationCount)
        let normalizedIterationCount = iterationCount
        switch normalizedIterationCount {
        case 0...12000:
            return Brush(
                strokeSize: 10,
                glowSize: 25,
                antiAliasing: true,
                opacity: 0.1
            )
        case 12001...20000:
            return Brush(
                strokeSize: 6,
                glowSize: 15,
                antiAliasing: true,
                opacity: 0.1
            )
        case 20001...60000:
            return Brush(
                strokeSize: 3,
                glowSize: 8,
                antiAliasing: true,
                opacity: 0.2
            )
        default:
            return Brush(
                strokeSize: 1,
                glowSize: 1,
                antiAliasing: true,
                opacity: 0.4
            )
        }
    }
}

