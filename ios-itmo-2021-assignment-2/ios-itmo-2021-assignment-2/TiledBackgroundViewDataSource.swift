import Foundation
import CellularAutomataSimulator


protocol TiledBackgroundViewDataSource: AnyObject {
    var viewport: Rect { get }
    func getCellFromPoint(at point: Point) -> Bool
    func setNewState(from state: SimpleCellularAutomatonState<BinaryCell>)
    func setTitle(from title: String)
}
