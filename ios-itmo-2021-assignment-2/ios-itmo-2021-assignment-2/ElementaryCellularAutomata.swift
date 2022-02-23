import Foundation

struct ElementaryCellularAutomata: CellularAutomata {
    let rule: UInt8
    
    public func simulate(_ state: State, generations: UInt) throws -> State {
        var state = state
        
        for _ in 0..<generations {
            guard let y = state.viewport.verticalIndexes.last, state.viewport.area != 0 else { return state }
            
            state.viewport = state.viewport
                .resizing(toInclude: state.viewport.bottomLeft + Point(x: -1, y: 0))
                .resizing(toInclude: state.viewport.bottomRight)
            
            for x in state.viewport.horizontalIndexes {
                let l = state[Point(x: x - 1, y: y)].rawValue
                let m = state[Point(x: x, y: y)].rawValue
                let r = state[Point(x: x + 1, y: y)].rawValue
                state[Point(x: x, y: y + 1)] = BinaryCell(rawValue: self.rule >> (l << 2 | m << 1 | r << 0) & 1)!
            }
        }
        
        return state
    }
    
    public init(rule: UInt8) {
        self.rule = rule
    }
}

extension ElementaryCellularAutomata {
    struct State: CellularAutomataState, CustomStringConvertible {
        typealias Cell = BinaryCell
        typealias SubState = Self
        
        var array: [Cell]
        private var _viewport: Rect
        var viewport: Rect {
            get {
                self._viewport
            }
            set {
                self.array = Self.resize(self.array, from: self.viewport, to: newValue)
                self._viewport = newValue
            }
        }
        
        init() {
            self._viewport = .zero
            self.array = []
        }
        
        static let zero = {
            Self()
            
        }
        
        var description: String {
            self.viewport.verticalIndexes.map { y in
                self.viewport.horizontalIndexes.map { self[Point(x: $0, y: y)] == .inactive ? "▢" : "█" }.joined()
            }.joined(separator: "\n")
        }
        
        public subscript(_ point: Point) -> BinaryCell {
            get {
                guard let index = Self.arrayIndex(at: point, in: self.viewport) else { return .inactive }
                return self.array[index]
            }
            set {
                let newViewport = self.viewport.resizing(toInclude: point)
                self.array = Self.resize(self.array, from: self.viewport, to: newViewport)
                self._viewport = newViewport
                
                guard let index = Self.arrayIndex(at: point, in: self.viewport) else { fatalError("Dev's problem") }
                
                return self.array[index] = newValue
            }
        }
        
        public subscript(_ rect: Rect) -> ElementaryCellularAutomata.State {
            get {
                guard let startIndex = Self.arrayIndex(at: rect.origin, in: self.viewport) else { return ElementaryCellularAutomata.State() }
                var tmp: [BinaryCell] = []
                for j in 0..<rect.size.height {
                    for i in startIndex + j * (self.viewport.size.width)..<(startIndex + rect.size.width) + j * (self.viewport.size.width) {
                        tmp.append(self.array[i])
                    }
                }
                var newState = ElementaryCellularAutomata.State()
                newState.viewport = rect
                newState.array = tmp
                return newState
            }
            set {
                for j in 0..<newValue.viewport.size.height {
                    for i in 0..<newValue.viewport.size.width {
                        let currentPoint = rect.origin + Point(x: i, y: j)
                        guard let rootStateIndex = Self.arrayIndex(at: currentPoint, in: self.viewport) else { fatalError("Wrong index") }
                        let newArrayIndex = i + j * newValue.viewport.size.width
                        self.array[rootStateIndex] = newValue.array[newArrayIndex]
                    }
                }
            }
        }
        
        public mutating func translate(to newOrigin: Point) {
            self._viewport = Rect(origin: newOrigin, size: self._viewport.size)
        }
        
        private static func arrayIndex(at point: Point, in viewport: Rect) -> Int? {
            guard viewport.contains(point: point) else { return nil }
            let localPoint = point - viewport.origin
            return localPoint.x + localPoint.y * viewport.size.width
        }
        
        private static func resize(_ oldArray: [Cell], from oldViewport: Rect, to newViewport: Rect) -> [Cell] {
            var newArray = Array<Cell> (repeating: .inactive, count: newViewport.area)
            
            for point in oldViewport.indices {
                guard let oldArrayIndex = Self.arrayIndex(at: point, in: oldViewport) else { continue }
                guard let newArrayIndex = Self.arrayIndex(at: point, in: newViewport) else { continue }
                newArray[newArrayIndex] = oldArray[oldArrayIndex]
            }
            
            return newArray
        }
    }
}
