import UIKit
import CellularAutomataSimulator

class LibraryViewController: UIViewController {
    public weak var dataSource: TiledBackgroundViewDataSource?
    
    var stateNameDictionary: [String : SimpleCellularAutomatonState<BinaryCell>] = [:]
    var addedStateImageDictionary: [String : UIImage] = [:]
    
    private var tableView: UITableView!
    var data = [["Simple Glider", "Triangle", "Two Triangles"], []]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0)
        
        self.tableView = UITableView()
        
        self.tableView.largeContentTitle = "Library"
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(LibraryTableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.rowHeight = 140
    }
}

extension LibraryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LibraryTableViewCell
        cell.title.text = "\(data[indexPath.section][indexPath.row])"
        let image = UIImage(named: "\(data[indexPath.section][indexPath.row])")
        if (image == nil) {
            cell.imageController.image = self.addedStateImageDictionary["\(data[indexPath.section][indexPath.row])"]
        } else {
            cell.imageController.image = image
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Стандартные"
        } else {
            return "Добавленные"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        var state = SimpleCellularAutomatonState<BinaryCell>()
        if ("\(data[indexPath.section][indexPath.row])" == "Simple Glider") {
            state[Point(x: 1, y: 0)] = .active
            state[Point(x: 2, y: 1)] = .active
            state[Point(x: 0, y: 2)] = .active
            state[Point(x: 1, y: 2)] = .active
            state[Point(x: 2, y: 2)] = .active
        } else if ("\(data[indexPath.section][indexPath.row])" == "Triangle") {
            state[Point(x: 0, y: 1)] = .active
            state[Point(x: 1, y: 0)] = .active
            state[Point(x: 1, y: 1)] = .active
            state[Point(x: 2, y: 1)] = .active
        } else if ("\(data[indexPath.section][indexPath.row])" == "Two Triangles") {
            state[Point(x: 0, y: 1)] = .active
            state[Point(x: 1, y: 0)] = .active
            state[Point(x: 1, y: 1)] = .active
            state[Point(x: 2, y: 1)] = .active
            
            state[Point(x: 4, y: 1)] = .active
            state[Point(x: 5, y: 0)] = .active
            state[Point(x: 5, y: 1)] = .active
            state[Point(x: 6, y: 1)] = .active
        } else {
            state = self.stateNameDictionary["\(data[indexPath.section][indexPath.row])"] ?? SimpleCellularAutomatonState<BinaryCell>()
        }
        self.dataSource?.setTitle(from: "\(data[indexPath.section][indexPath.row])")
        navigationController?.popViewController(animated: true)
        self.dataSource?.setNewState(from: state)
    }
    
    func addState(state: SimpleCellularAutomatonState<BinaryCell>, image: UIImage, name: String) {
        if (!self.data[1].contains(name)) {
            self.stateNameDictionary[name] = state
            print(state)
            self.data[1].append(name)
            self.addedStateImageDictionary[name] = image
            self.tableView?.reloadData()
        }
    }
}

class LibraryTableViewCell: UITableViewCell {
    var title: UILabel!
    var imageController: UIImageView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.title = UILabel()
        self.title.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.title)
        
        self.imageController = UIImageView()
        self.imageController.translatesAutoresizingMaskIntoConstraints = false
        self.imageController.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageController)
        
        NSLayoutConstraint.activate([
            self.imageController.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.imageController.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20),
            self.imageController.heightAnchor.constraint(equalToConstant: 100),
            self.imageController.widthAnchor.constraint(equalToConstant: 100),
            
            self.title.centerYAnchor.constraint(equalTo: self.imageController.centerYAnchor),
            self.title.leadingAnchor.constraint(equalTo: self.imageController.trailingAnchor, constant: 50)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
