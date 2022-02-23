public protocol CellularAutomata {
    associatedtype State: CellularAutomataState

    /// Возвращает новое состояние поля после n поколений
    /// - Parameters:
    ///   - state: Исходное состояние поля
    ///   - generations: Количество симулирвемых поколений
    /// - Returns:
    ///   - Новое состояние после симуляции
    func simulate(_ state: State, generations: UInt) throws -> State
}

public protocol CellularAutomataState {
    associatedtype Cell
    associatedtype SubState: CellularAutomataState

    /// Конструктор пустого поля
    init()

    /// Квадрат представляемой области в глобальных координатах поля
    /// Присвоение нового значение обрезая/дополняя поле до нужного размера
    var viewport: Rect { get set }

    /// Значение конкретной ячейки в точке, заданной в глобальных координатах.
    subscript(_: Point) -> Cell { get set }
    /// Значение поля в прямоугольнике, заданном в глобальных координатах.
    subscript(_: Rect) -> SubState { get set }

    /// Меняет origin у viewport
    mutating func translate(to: Point)
}

public struct Size {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        guard width >= 0 && height >= 0 else { fatalError() }
        self.width = width
        self.height = height
    }
}

public struct Point {
    public let x: Int
    public let y: Int
}

public struct Rect {
    public let origin: Point
    public let size: Size
}

public enum BinaryCell: UInt8 {
    case inactive = 0
    case active = 1
}

extension Size: Hashable, CustomStringConvertible {
    public var description: String {
        "(w: \(self.width), h \(self.height))"
    }
    
    static let zero = Self(width: 0, height: 0)
    
    var area: Int {
        self.width * self.height
    }
}

extension Point: Hashable, CustomStringConvertible {
    public var description: String {
        "(x: \(self.x), y: \(self.y)"
    }
    
    static let zero = Self(x: 0, y: 0)
    
    public static func +(left: Self, right: Self) -> Self {
        Self(x: left.x + right.x, y: left.y + right.y)
    }
    
    public static func -(left: Self, right: Self) -> Self {
        Self(x: left.x - right.x, y: left.y - right.y)
    }
    
    public static func <(left: Self, right: Self) -> Bool {
        let sub = right - left
        if (sub.x >= 0 && sub.y >= 0) {
            return true
        }
        return false
    }
    
    public static func >(left: Self, right: Self) -> Bool {
        let sub = right - left
        if (sub.x <= 0 && sub.y <= 0) {
            return true
        }
        return false
    }
}

extension Rect: Hashable, CustomStringConvertible {
    public var description: String {
        "{ \(self.origin) \(self.size) }"
    }
    
    static let zero = Self(origin: .zero, size: .zero)
    
    var area: Int {
        self.size.area
    }
    
    var indices: [Point] {
        self.horizontalIndexes.flatMap { x in self.verticalIndexes.map { y in Point(x: x, y: y) } }
    }
    
    func contains(point: Point) -> Bool {
        self.horizontalIndexes.contains(point.x) && self.verticalIndexes.contains(point.y)
    }
    
    var horizontalIndexes: Range<Int> {
        self.origin.x ..< self.origin.x + self.size.width
    }
    
    var verticalIndexes: Range<Int> {
        self.origin.y ..< self.origin.y + self.size.height
    }
    
    var bottomLeft: Point {
        Point(x: self.origin.x, y: self.origin.y + self.size.height)
    }
    
    var bottomRight: Point {
        Point(x: self.origin.x + self.size.width, y: self.origin.y + self.size.height)
    }
    
    var topRight: Point {
        Point(x: self.origin.x + self.size.width, y: self.origin.y)
    }
    
    var center: Point {
        Point(x: self.size.width / 2, y: self.size.height / 2)
    }
    
    func resizing(toInclude point: Point) -> Rect {
        let newOrigin = Point(x: min(self.origin.x, point.x), y: min(self.origin.y, point.y))
        let newSize = Size(
            width: max(self.origin.x + self.size.width, point.x + 1) - newOrigin.x,
            height: max(self.origin.y + self.size.height, point.y + 1) - newOrigin.y
        )
        return Rect(origin: newOrigin, size: newSize)
    }
}
