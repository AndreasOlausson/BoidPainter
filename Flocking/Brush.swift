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
        case 0...200:
            return Brush(
                strokeSize: 25,
                glowSize: 5,
                antiAliasing: true,
                opacity: 0.05
            )
        case 201...400:
            return Brush(
                strokeSize: 10,
                glowSize: 4,
                antiAliasing: true,
                opacity: 0.1
            )
        case 401...600:
            return Brush(
                strokeSize: 5,
                glowSize: 3,
                antiAliasing: true,
                opacity: 0.2
            )
        default:
            return Brush(
                strokeSize: 1,
                glowSize: 1,
                antiAliasing: true,
                opacity: 1
            )
        }
    }
}

