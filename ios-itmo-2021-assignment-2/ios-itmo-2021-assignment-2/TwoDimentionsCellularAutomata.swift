import Foundation

struct TwoDimentionsCellularAutomata: CellularAutomata {
    typealias State = ElementaryCellularAutomata.State
    typealias Cell = BinaryCell
    
    let rule: (ElementaryCellularAutomata.State) -> Cell
    
    func simulate(_ state: ElementaryCellularAutomata.State, generations: UInt) throws -> ElementaryCellularAutomata.State {
        var state = state
        
        var topActive = state.viewport.center
        var leftActive = state.viewport.center
        var rightActive = state.viewport.center
        var bottomActive = state.viewport.center
        
        for _ in 0..<generations {
            
            var newState = state
            
            if (newState.viewport.origin.y == topActive.y) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.origin - Point(x: 0, y: 1))
            }
            if (newState.viewport.origin.x == leftActive.x) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.origin - Point(x: 1, y: 0))
            }
            if (newState.viewport.bottomRight.y == bottomActive.y) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.bottomRight + Point(x: 0, y: 1))
            }
            if (newState.viewport.bottomRight.x == rightActive.x) {
                newState.viewport = newState.viewport.resizing(toInclude: newState.viewport.bottomRight + Point(x: 1, y: 0))
            }
            
            print(newState.viewport)
            
            for x in state.viewport.horizontalIndexes {
                for y in state.viewport.verticalIndexes {
                    var vicinity = ElementaryCellularAutomata.State()
                    vicinity.viewport = Rect(origin: .zero, size: Size(width: 3, height: 3))
                    vicinity[.zero] = .inactive
                    vicinity[Point(x: 2, y: 2)] = .inactive
                    
                    if (state.viewport.origin.x < x && state.viewport.origin.y < y && state.viewport.bottomRight.x - 1 > x && state.viewport.bottomRight.y - 1 > y) {
                        vicinity = state[Rect(origin: Point(x: x - 1, y: y - 1), size: Size(width: 3, height: 3))]
                    } else if !state.viewport.contains(point: Point(x: x - 1, y: y)) && !state.viewport.contains(point: Point(x: x, y: y - 1)) {
                        vicinity[Rect(origin: Point(x: 1, y: 1), size: Size(width: 2, height: 2))] = state[Rect(origin: state.viewport.origin, size: Size(width: 2, height: 2))]
                    } else if !state.viewport.contains(point: Point(x: x + 1, y: y)) && !state.viewport.contains(point: Point(x: x, y: y - 1)) {
                        vicinity[Rect(origin: Point(x: 0, y: 1), size: Size(width: 2, height: 2))] = state[Rect(origin: state.viewport.topRight - Point(x: 1, y: 0), size: Size(width: 2, height: 2))]
                    } else if !state.viewport.contains(point: Point(x: x - 1, y: y)) && !state.viewport.contains(point: Point(x: x, y: y + 1)) {
                        vicinity[Rect(origin: Point(x: 1, y: 0), size: Size(width: 2, height: 2))] = state[Rect(origin: state.viewport.bottomLeft - Point(x: 0, y: 2), size: Size(width: 2, height: 2))]
                    } else if !state.viewport.contains(point: Point(x: x + 1, y: y)) && !state.viewport.contains(point: Point(x: x, y: y + 1)) {
                        vicinity[Rect(origin: Point(x: 0, y: 0), size: Size(width: 2, height: 2))] = state[Rect(origin: state.viewport.bottomRight - Point(x: 2, y: 2), size: Size(width: 2, height: 2))]
                    } else if !state.viewport.contains(point: Point(x: x - 1, y: y)) {
                        vicinity[Rect(origin: Point(x: 1, y: 0), size: Size(width: 2, height: 3))] = state[Rect(origin: Point(x: x, y: y - 1), size: Size(width: 2, height: 3))]
                    } else if !state.viewport.contains(point: Point(x: x + 1, y: y)) {
                        vicinity[Rect(origin: .zero, size: Size(width: 2, height: 3))] = state[Rect(origin: Point(x: x - 1, y: y - 1), size: Size(width: 2, height: 3))]
                    } else if !state.viewport.contains(point: Point(x: x, y: y - 1)) {
                        vicinity[Rect(origin: Point(x: 0, y: 1), size: Size(width: 3, height: 2))] = state[Rect(origin: Point(x: x - 1, y: y), size: Size(width: 3, height: 2))]
                    } else if !state.viewport.contains(point: Point(x: x, y: y + 1)) {
                        vicinity[Rect(origin: .zero, size: Size(width: 3, height: 2))] = state[Rect(origin: Point(x: x - 1, y: y - 1), size: Size(width: 3, height: 2))]
                    }
                    
                    newState[Point(x: x, y: y)] = rule(vicinity)
                    
                    if (newState[Point(x: x, y: y)] == .active) {
                        if (topActive.y > y) {
                            topActive = Point(x: x, y: y)
                        }
                        if (leftActive.x > x) {
                            leftActive = Point(x: x, y: y)
                        }
                        if (rightActive.x < x) {
                            rightActive = Point(x: x, y: y)
                        }
                        if (bottomActive.y < y) {
                            bottomActive = Point(x: x, y: y)
                        }
                    }
                }
//                print("right: \(rightActive) \nbottom: \(bottomActive)")
            }
            
            state = newState
            
//            print(newState)
        }
        
        return state
    }
    
    init(rule: @escaping (ElementaryCellularAutomata.State) -> Cell) {
        self.rule = rule
    }
}
