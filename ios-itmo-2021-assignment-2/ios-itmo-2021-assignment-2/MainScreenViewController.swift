import UIKit
import CellularAutomataSimulator

class MainScreenViewController: UIViewController, TiledBackgroundViewDataSource {
    var viewport: Rect { self.mainState.viewport }
    var isSimulating = false
    var snapshots = [SimpleCellularAutomatonState<BinaryCell>]()
    var automataType: String = "Game of Life"
    var rule: UInt8 = 30
    var tiledViewWidthConstraint: NSLayoutConstraint!
    var tiledViewHeightConstraint: NSLayoutConstraint!
    
    let scrollView = UIScrollView()
    var mainState: SimpleCellularAutomatonState = SimpleCellularAutomatonState<BinaryCell>()
    let tiledView: TiledBackgroundView = TiledBackgroundView(frame: .zero)
    let tileSize = 100
    
    var play: UIBarButtonItem!
    var pause: UIBarButtonItem!
    
    var selectView: UIView!
    var initialCenter = CGPoint()
    var finalCenter = CGPoint()
    var startPoint = CGPoint()
    var rectSize = CGSize()
    var finalTopLeftCorner = CGPoint()
    var previousTouch = CGPoint()
    
    var isResizingUL = false
    var isResizingUR = false
    var isResizingDL = false
    var isResizingDR = false
    var prevXOperation = "+"
    var prevYOperation = "-"
    
    var isInserting = false
    var isHighlighting = false
    
    var libraryVC: LibraryViewController!
    let longTapGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)
    
    var moveView: UIView!
    
    func setTitle(from title: String) {
        self.navigationItem.title = title
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.systemGray6
        
        self.libraryVC = LibraryViewController()
        self.setupNavAndToolBar()
        self.setupScrollView()
        self.setupTiledView()
        self.setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
}

extension MainScreenViewController {
    func getCellFromPoint(at point: Point) -> Bool {
        return self.mainState[point] == .active
    }
    
    func setNewState(from state: SimpleCellularAutomatonState<BinaryCell>) {
        let alertViewController = UIAlertController(title: "Введите координаты", message: "Новая фигура будет вставлена по этим координатам", preferredStyle: .alert)
        
        alertViewController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Введите x"
        })
        alertViewController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Введите y"
        })
        alertViewController.addAction(UIAlertAction(title: "Ввод", style: .default, handler: { [weak alertViewController] (_) in
            let x = Int(alertViewController?.textFields![0].text ?? "0") ?? 0
            let y = Int(alertViewController?.textFields![1].text ?? "0") ?? 0
            var newState = state
            newState.translate(to: Point(x: x, y: y))
            self.mainState[newState.viewport] = newState
            self.drawState()
        }))
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func resizeTiledView(width: CGFloat, height: CGFloat) {
        self.tiledViewWidthConstraint.constant = width
        self.tiledViewHeightConstraint.constant = height
    }
    
    func setupConstraints() {
        self.tiledViewWidthConstraint = self.tiledView.widthAnchor.constraint(equalToConstant: 1300)
        self.tiledViewHeightConstraint = self.tiledView.heightAnchor.constraint(equalToConstant: 3000)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            
            self.tiledView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.tiledView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.tiledView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor),
            self.tiledView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor),
            self.tiledViewWidthConstraint,
            self.tiledViewHeightConstraint
        ])
    }
    
    func setupNavAndToolBar() {
        self.navigationItem.title = self.automataType
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self.showDropMenu(sender:)))
        
        self.play = UIBarButtonItem(image: UIImage(systemName: "play"), style: .plain, target: self, action: #selector(self.playSimulateAutomata(sender:)))
        self.pause = UIBarButtonItem(image: UIImage(systemName: "pause"), style: .plain, target: self, action: #selector(self.stopSimulateAutomata(sender:)))
        
        self.toolbarItems = [
            UIBarButtonItem(image: UIImage(systemName: "camera.viewfinder"), style: .plain, target: self, action: #selector(self.saveSnapshot(sender:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "backward.end.alt"), style: .plain, target: self, action: #selector(self.rollbackToThePreviousSnapshot(sender:))),
            play,
            UIBarButtonItem(image: UIImage(systemName: "forward.end"), style: .plain, target: self, action: #selector(self.simulateOneGeneration(sender:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(self.showLibraryViewController(sender:)))
        ]
    }
    
    func setupScrollView() {
        self.view.addSubview(scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 0.01
        self.scrollView.maximumZoomScale = 5.0
        self.scrollView.zoomScale = 0.3
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
    }
    
    func setupTiledView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.longTapGestureRecognizer.addTarget(self, action: #selector(self.selectRect(sender:)))
        self.scrollView.addSubview(tiledView)
        self.tiledView.translatesAutoresizingMaskIntoConstraints = false
        self.tiledView.tiledLayer.tileSize = CGSize(width: 100, height: 100)
        self.tiledView.addGestureRecognizer(tapGestureRecognizer)
        self.tiledView.addGestureRecognizer(self.longTapGestureRecognizer)
        self.tiledView.dataSource = self
    }
    
    @objc func saveSnapshot(sender: UIAlertAction) {
        self.snapshots.append(self.mainState)
    }
    
    @objc func rollbackToThePreviousSnapshot(sender: UIAlertAction) {
        if (self.snapshots.count == 1) {
            let alertController = UIAlertController(title: "Нет последних сохраненных состояний", message: "Вы хотите вернуться к пустому полю?", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Да", style: .destructive, handler: clearField(sender:)))
            alertController.addAction(UIAlertAction(title: "Нет", style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.mainState = self.snapshots.last ?? SimpleCellularAutomatonState<BinaryCell>()
            self.snapshots.removeLast()
            self.tiledView.setNeedsDisplay()
        }
    }
    
    @objc func simulateOneGeneration(sender: UIAlertAction) {
        if (self.automataType == "Game of Life") {
            let twoDimAut = Simple2DCellularAutomaton.gameOfLife
            self.mainState = try! twoDimAut.simulate(self.mainState, generations: 1)
            self.drawState()
        } else {
            let elementaryAutomata = Simple1DCellularAutomaton(wolframCode: self.rule)
            self.mainState = try! elementaryAutomata.simulate(self.mainState, generations: 1)
            self.drawState()
        }
    }
    
    func drawState() {
        for x in self.mainState.viewport.verrticalIndices {
            for y in self.mainState.viewport.horizontalIndices {
                let rect = CGRect(x: x * self.tileSize, y: y * self.tileSize, width: self.tileSize, height: self.tileSize)
                self.tiledView.setNeedsDisplay(rect)
            }
        }
    }
    
    @objc func playSimulateAutomata(sender: UIBarButtonItem) {
        self.isSimulating.toggle()
        var items = self.navigationController?.toolbar.items!
        items?[3] = pause
        self.navigationController?.toolbar.setItems(items, animated: true)
        
        let twoDimAut = Simple2DCellularAutomaton.gameOfLife
        let elemetaryAut = Simple1DCellularAutomaton(wolframCode: self.rule)
        self.mainState[self.mainState.viewport.bottomRight + Point(x: 1, y: 1)] = .inactive
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: self.isSimulating, block: {timer in
            if (!self.isSimulating) {
                timer.invalidate()
            }
            if (self.automataType == "Game of Life") {
                self.mainState = try! twoDimAut.simulate(self.mainState, generations: 1)
            } else {
                self.mainState = try! elemetaryAut.simulate(self.mainState, generations: 1)
                print(self.mainState)
            }
            self.drawState()
        })
    }
    
    @objc func stopSimulateAutomata(sender: UIBarButtonItem) {
        self.isSimulating.toggle()
        var items = self.navigationController?.toolbar.items!
        items?[3] = play
        self.navigationController?.toolbar.setItems(items, animated: true)
    }
    
    @objc func showDropMenu(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let options = UIAlertAction(title: "настроить текущий автомат", style: .default, handler: self.showAutomatesToPick(sender:))
        let optionsImg = UIImage(systemName: "gearshape")
        options.setValue(optionsImg, forKey: "image")
        alertController.addAction(options)

        let size = UIAlertAction(title: "изменить размеры поля", style: .default, handler: self.setBounds(sender:))
        let sizeImg = UIImage(systemName: "crop")
        size.setValue(sizeImg, forKey: "image")
        alertController.addAction(size)

        let clear = UIAlertAction(title: "очистить текущее поле", style: .destructive, handler: self.clearFieldAlert(sender:))
        let clearImg = UIImage(systemName: "xmark.octagon")
        clear.setValue(clearImg, forKey: "image")
        alertController.addAction(clear)
        
        let cancel = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAutomatesToPick(sender: UIAlertAction) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let elementaryAutomata = UIAlertAction(title: "Элементарный автомат", style: .default, handler: self.setElementaryAutomata(sender:))
        alertController.addAction(elementaryAutomata)

        let gameLife = UIAlertAction(title: "Игра жизнь", style: .default, handler: self.setGameOfLifeAutomata(sender:))
        alertController.addAction(gameLife)
        
        let cancel = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setGameOfLifeAutomata(sender: UIAlertAction) {
        self.automataType = "Game of Life"
        self.navigationItem.title = self.automataType
        self.navigationItem.leftBarButtonItem = nil
    }
    
    func setElementaryAutomata(sender: UIAlertAction) {
        self.automataType = "Elementary Automata"
        self.navigationItem.title = self.automataType
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.letEnterRule(sender:)))
    }
    
    @objc func letEnterRule(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Введите правило по коду Вольфрама", message: "Правило по умолчанию - 30", preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Введите правило"
        })
        
        alertController.addAction(UIAlertAction(title: "Ввод", style: .default, handler: { [weak alertController] (_) in
            self.rule = UInt8(alertController?.textFields![0].text ?? "0") ?? 0
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setBounds(sender: UIAlertAction) {
        let alertViewController = UIAlertController(title: "Введите новые размеры поля", message: nil, preferredStyle: .alert)
        
        alertViewController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Введите ширину"
        })
        alertViewController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Введите высоту"
        })
        alertViewController.addAction(UIAlertAction(title: "Ввод", style: .default, handler: { [weak alertViewController] (_) in
            let width = Int(alertViewController?.textFields![0].text ?? "0") ?? 0
            let height = Int(alertViewController?.textFields![1].text ?? "0") ?? 0
            self.resizeTiledView(width: CGFloat(width * self.tileSize), height: CGFloat(height * self.tileSize))
            self.tiledView.setNeedsDisplay()
        }))
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func clearFieldAlert(sender: UIAlertAction) {
        let clearAlert = UIAlertController(title: "Очистить поле?", message: "Все данные будут потеряны", preferredStyle: .alert)
        
        clearAlert.addAction(UIAlertAction(title: "Да", style: .destructive, handler: clearField(sender:)))
        clearAlert.addAction(UIAlertAction(title: "Нет", style: .default, handler: nil))
        
        self.present(clearAlert, animated: true, completion: nil)
    }
    
    func clearField(sender: UIAlertAction) {
        self.mainState = SimpleCellularAutomatonState<BinaryCell>()
        self.resizeTiledView(width: 1300, height: 3000)
        self.tiledView.setNeedsDisplay()
    }
    
    @objc func showLibraryViewController(sender: UIBarButtonItem) {
        self.libraryVC.modalPresentationStyle = .pageSheet
        self.libraryVC.dataSource = self
        self.show(self.libraryVC, sender: sender)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        if (!self.isSimulating) {
            let point = sender?.location(in: tiledView)
            let x = Int(Int(point!.x) / self.tileSize)
            let y = Int(Int(point!.y) / self.tileSize)
            let automataPoint = Point(x: x, y: y)
            mainState[automataPoint] = (mainState[automataPoint] == .active) ? .inactive : .active
            tiledView.setNeedsDisplay(CGRect(origin: CGPoint(x: Int(automataPoint.x * self.tileSize), y: Int(automataPoint.y * self.tileSize)),
                                             size: CGSize(width: self.tileSize, height: self.tileSize)))
        }
    }
    
    @objc func selectRect(sender: UILongPressGestureRecognizer) {
        self.isHighlighting = true
        if (sender.state == .began) {
            let point = sender.location(in: self.tiledView)
            let x = max(0, Int(point.x - 150))
            let y = max(0, Int(point.y - 150))
            
            self.selectView = UIView(frame: CGRect(x: x, y: y, width: 300, height: 300))
            self.selectView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            self.selectView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.15).cgColor
            self.selectView.layer.borderWidth = 5
            self.selectView.layer.cornerRadius = 20
            self.selectView.translatesAutoresizingMaskIntoConstraints = false
            
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.resizeSelectView(sender:)))
            self.selectView.addGestureRecognizer(panGestureRecognizer)
            self.tiledView.addSubview(self.selectView)
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.removeSelection(sender:)))
            
            self.toolbarItems = [
                UIBarButtonItem.flexibleSpace(),
                UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down.on.square"), style: .plain, target: self, action: #selector(self.saveToLibrary(sender:))),
                UIBarButtonItem.flexibleSpace(),
                UIBarButtonItem.flexibleSpace(),
                UIBarButtonItem(image: UIImage(systemName: "square.slash"), style: .plain, target: self, action: #selector(self.clearViewport(sender:))),
                UIBarButtonItem.flexibleSpace()
            ]
        }
        sender.isEnabled = false
    }
    
    @objc func saveToLibrary(sender: UIBarButtonItem) {
        let screenshot = self.selectView.takeScreenshot(view: self.tiledView)
        
        let origin = self.selectView.frame.origin
        let size = self.selectView.frame.size
        let xStart = Int(origin.x / 100)
        let yStart = Int(origin.y / 100)
        
        var state = self.mainState[Rect(origin: Point(x: xStart, y: yStart), size: Size(width: Int(size.width / 100), height: Int(size.height / 100)))]
        
        var nameOfImage = ""
        
        let alertController = UIAlertController(title: "Введите название", message: nil, preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Введите название"
        })
        
        alertController.addAction(UIAlertAction(title: "Ввод", style: .default, handler: { [weak alertController] (_) in
            nameOfImage = alertController?.textFields![0].text ?? "New state"
            self.libraryVC.addState(state: state, image: screenshot, name: nameOfImage)
        }))
        
        self.present(alertController, animated: true, completion: nil)
        
        setupNavAndToolBar()
        self.selectView.removeFromSuperview()
        self.longTapGestureRecognizer.isEnabled = true
    }
    
    @objc func removeSelection(sender: UIBarButtonItem) {
        self.navigationItem.title = self.automataType
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self.showDropMenu(sender:)))
        
        self.toolbarItems = [
            UIBarButtonItem(image: UIImage(systemName: "camera.viewfinder"), style: .plain, target: self, action: #selector(self.saveSnapshot(sender:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "backward.end.alt"), style: .plain, target: self, action: #selector(self.rollbackToThePreviousSnapshot(sender:))),
            play,
            UIBarButtonItem(image: UIImage(systemName: "forward.end"), style: .plain, target: self, action: #selector(self.simulateOneGeneration(sender:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(self.showLibraryViewController(sender:)))
        ]
        
        self.tiledView.gestureRecognizers?[1].isEnabled = true
        if (self.isInserting) {
            self.moveView.removeFromSuperview()
            self.isInserting = false
        } else if (self.isHighlighting) {
            self.selectView.removeFromSuperview()
            self.isHighlighting = false
        }
        self.isResizingDL = false
        self.isResizingDR = false
    }
    
    @objc func clearViewport(sender: UIBarButtonItem) {
        let origin = Point(x: Int(self.selectView.frame.origin.x / 100), y: Int(self.selectView.frame.origin.y / 100))
        let size = Size(width: Int(self.selectView.frame.size.width / 100), height: Int(self.selectView.frame.size.height / 100))
        print(origin)
        print(size)
        var emptyState = SimpleCellularAutomatonState<BinaryCell>()
        emptyState[Point(x: origin.x + size.width - 1, y: origin.y + size.height - 1)] = .inactive
        self.mainState[Rect(origin: origin, size: size)] = emptyState
        self.drawState()
        setupNavAndToolBar()
        self.selectView.removeFromSuperview()
        self.longTapGestureRecognizer.isEnabled = true
    }
    
    @objc func moveOnGesture(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self.tiledView)
        
        let translation = sender.translation(in: self.tiledView)
        if (sender.state == .began) {
            self.initialCenter = self.moveView.center
            self.startPoint = point
            self.rectSize = self.moveView.bounds.size
        }
        
        if (sender.state != .ended) {
            let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            self.finalCenter = newCenter
            self.moveView.center = newCenter
        }
        
        if (sender.state == .ended) {
            var x = lroundf(Float(self.finalCenter.x / 100)) * 100
            var y = lroundf(Float(self.finalCenter.y / 100)) * 100
            if (Int(self.moveView.bounds.size.width / 100) % 2 != 0) {
                x += 50
            }
            if (Int(self.moveView.bounds.size.height / 100) % 2 != 0) {
                y += 50
            }
            self.moveView.center = CGPoint(x: x, y: y)
            self.finalCenter = self.moveView.center
        }
    }
    
    @objc func resizeSelectView(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self.tiledView)
        
        let translation = sender.translation(in: self.tiledView)
        if (sender.state == .began) {
            self.initialCenter = self.selectView.center
            self.startPoint = point
            self.rectSize = self.selectView.bounds.size
        }
        
        if (sender.state != .ended) {
            let topLeftCorner = CGPoint(x: self.selectView.center.x - self.rectSize.width / 2, y: self.selectView.center.y - self.rectSize.height / 2)
            let topRightCorner = CGPoint(x: self.selectView.center.x + self.rectSize.width / 2, y: self.selectView.center.y - self.rectSize.height / 2)
            let bottomLeftCorner = CGPoint(x: self.selectView.center.x - self.rectSize.width / 2, y: self.selectView.center.y + self.rectSize.height / 2)
            let bottomRightCorner = CGPoint(x: self.selectView.center.x + self.rectSize.width / 2, y: self.selectView.center.y + self.rectSize.height / 2)
            
            if (self.startPoint.x <= topLeftCorner.x + 20 && self.startPoint.x >= topLeftCorner.x &&
                self.startPoint.y <= topLeftCorner.y + 20 && self.startPoint.y >= topLeftCorner.y) {
                self.isResizingUL = true
            } else if (self.startPoint.x >= topRightCorner.x - 20 && self.startPoint.x <= topRightCorner.x &&
                       self.startPoint.y <= topRightCorner.y + 20 && self.startPoint.y >= topRightCorner.y) {
                self.isResizingUR = true
            } else if (self.startPoint.x <= bottomLeftCorner.x + 20 && self.startPoint.x >= bottomLeftCorner.x &&
                       self.startPoint.y >= bottomLeftCorner.y - 20 && self.startPoint.y <= bottomLeftCorner.y) {
                self.isResizingDL = true
            } else if (self.startPoint.x >= bottomRightCorner.x - 20 && self.startPoint.x <= bottomRightCorner.x &&
                       self.startPoint.y >= bottomRightCorner.y - 20 && self.startPoint.y <= bottomRightCorner.y) {
                self.isResizingDR = true
            }
            
            let delta = CGPoint(x: self.previousTouch.x - point.x, y: self.previousTouch.y - point.y)

            if (isResizingUL) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX - delta.x,
                                               y: self.selectView.frame.minY - delta.y,
                                               width: self.selectView.frame.size.width + delta.x,
                                               height: self.selectView.frame.size.height + delta.y)
                self.rectSize = self.selectView.frame.size
                self.finalTopLeftCorner = self.selectView.frame.origin
//                self.initialCenter = CGPoint(x: self.selectView.center.x + translation.x, y: self.selectView.center.y + translation.y)
            } else if (isResizingUR) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX,
                                               y: self.selectView.frame.minY - delta.y,
                                               width: self.selectView.frame.size.width - delta.x,
                                               height: self.selectView.frame.size.height + delta.y)
                self.rectSize = self.selectView.frame.size
//                self.finalTopLeftCorner = self.selectView.frame.origin
//                self.initialCenter = CGPoint(x: self.selectView.center.x + translation.x, y: self.selectView.center.y + translation.y)
            } else if (isResizingDL) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX - delta.x,
                                               y: self.selectView.frame.minY,
                                               width: self.selectView.frame.size.width + delta.x,
                                               height: self.selectView.frame.size.height - delta.y)
                self.rectSize = self.selectView.frame.size
//                self.finalTopLeftCorner = self.selectView.frame.origin
//                self.initialCenter = CGPoint(x: self.selectView.center.x + translation.x, y: self.selectView.center.y + translation.y)
            } else if (isResizingDR) {
                self.selectView.frame = CGRect(x: self.selectView.frame.minX,
                                               y: self.selectView.frame.minY,
                                               width: self.selectView.frame.size.width - delta.x,
                                               height: self.selectView.frame.size.height - delta.y)
                self.rectSize = self.selectView.frame.size
//                self.finalTopLeftCorner = self.selectView.frame.origin
//                self.initialCenter = CGPoint(x: self.selectView.center.x + translation.x, y: self.selectView.center.y + translation.y)
            } else {
                let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
                self.finalCenter = newCenter
                self.selectView.center = newCenter
            }
            
            previousTouch = point
        }
        
        if (sender.state == .ended) {
            var origin = self.finalTopLeftCorner
            var size = self.rectSize
            size.width = max(100, CGFloat(lroundf(Float(size.width) / 100) * 100))
            size.height = max(100, CGFloat(lroundf(Float(size.height) / 100) * 100))
            self.selectView.frame = CGRect(origin: origin, size: size)
            
            var x = lroundf(Float(self.finalCenter.x / 100)) * 100
            var y = lroundf(Float(self.finalCenter.y / 100)) * 100
            if (Int(self.selectView.bounds.size.width / 100) % 2 != 0) {
                x += 50
//                if (isResizingUL || isResizingDL) {
//                    x -= 50
//                    self.prevXOperation = "-"
//                } else if (isResizingUR || isResizingDR) {
//                    x += 50
//                    self.prevXOperation = "+"
//                }
            }
            if (Int(self.selectView.bounds.size.height / 100) % 2 != 0) {
                y += 50
//                if (isResizingUR || isResizingUL) {
//                    y -= 50
//                    self.prevYOperation = "-"
//                } else if (isResizingDR || isResizingDL) {
//                    y += 50
//                    self.prevYOperation = "+"
//                }
            }
//            if (Int(self.finalCenter.x) % 100 != 0) {
//                x = (self.prevXOperation == "-") ? x + 50 : x - 50
//            }
//            if (Int(self.finalCenter.y) % 100 != 0) {
//                y = (self.prevYOperation == "-") ? y + 50 : y - 50
//            }
            self.selectView.center = CGPoint(x: x, y: y)
            self.finalCenter = self.selectView.center
            
            self.isResizingUL = false
            self.isResizingUR = false
            self.isResizingDL = false
            self.isResizingDR = false
        }
    }
}

extension MainScreenViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        tiledView
    }
}

class TiledBackgroundView: UIView {
    let sideLength: CGFloat = 30
    public weak var dataSource: TiledBackgroundViewDataSource?
    
    override class var layerClass: AnyClass { CATiledLayer.self }
    
    var tiledLayer: CATiledLayer { layer as! CATiledLayer }
    
    override var contentScaleFactor: CGFloat {
        didSet { super.contentScaleFactor = 1 }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { fatalError("skldjflsdjf") }
        context.setFillColor(UIColor.systemGray6.cgColor)
        context.fill(rect)
        
        if (dataSource?.getCellFromPoint(at: Point(x: Int(rect.minX / 100), y: Int(rect.minY / 100))) ?? false) {
            context.setFillColor(UIColor.systemGray.cgColor)
        } else {
            context.setFillColor(UIColor.systemGray5.cgColor)
        }
        context.fillEllipse(in: rect.inset(by: UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)))
    }
}

extension BinaryCell: CellProtocol, CustomStringConvertible {
    public static let `default` = Self.inactive

    public var display: Character {
        self == .active ? "█" : " "
    }

    public var description: String {
        String(self.display)
    }
}

extension UIView {

    func takeScreenshot(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, self.window?.screen.scale ?? 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: -self.frame.minX, y: -self.frame.minY)
        let origin = Point(x: Int(self.frame.minX / 100), y: Int(self.frame.minY / 100))
        let size = Size(width: Int(self.frame.width / 100), height: Int(self.frame.height / 100))
        drawSubstate(origin: origin, size: size, view: view)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        context.translateBy(x: self.frame.minX, y: self.frame.minY)
        UIGraphicsEndImageContext()

        return image ?? UIImage()
    }
    
    func drawSubstate(origin: Point, size: Size, view: UIView) {
        for x in origin.x..<(origin.x + size.width) {
            for y in origin.y..<(origin.y + size.height) {
//                print("\(x) : \(y)")
                view.draw(CGRect(x: x * 100, y: y * 100, width: 100, height: 100))
            }
        }
    }
}
