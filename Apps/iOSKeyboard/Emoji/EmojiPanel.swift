import UIKit
import VietKeyCore

/// VietKey's own emoji page, because a keyboard extension cannot open the system's. Every
/// group in one grid that scrolls down; the strip below jumps to a group and holds the keys
/// back to the letters and Delete. Built when the emoji key is tapped and dropped on the way
/// back to the letters, which returned about 14 MB of the 90 MB that scrolling through every
/// group cost in a Debug simulator. The rest stayed, so `EmojiBudget` decides what is drawn.
final class EmojiPanel: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    /// Narrowest a column gets: 8 across on a 402-point phone.
    private static let columnWidth: CGFloat = 48
    private static let stripKeyUnits: CGFloat = 1.25

    private let groups = EmojiCatalog.loadGroups()
    private let layout = UICollectionViewFlowLayout()
    private let grid: UICollectionView
    private let cells: UICollectionView.CellRegistration<EmojiCell, Character>
    private let tabs: [UIButton] = EmojiCatalog.tabs.map { tab in
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: tab.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15)), for: .normal)
        button.accessibilityLabel = tab.name
        return button
    }
    let lettersKey = KeyButton()
    let deleteKey = KeyButton()
    var onEmoji: (Character) -> Void = { _ in }
    var metrics = KeyMetrics.compact {
        didSet { if metrics != oldValue { setNeedsLayout() } }
    }

    init(budget: EmojiBudget) {
        cells = UICollectionView.CellRegistration { cell, _, emoji in
            cell.emoji = budget.allows(emoji) ? emoji : nil
        }
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 6, left: 0, bottom: 10, right: 0)
        grid = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        grid.backgroundColor = .clear
        grid.showsVerticalScrollIndicator = false
        // The keyboard's own glass already frames the grid; the scroll edge blur smears a row.
        grid.topEdgeEffect.isHidden = true
        grid.bottomEdgeEffect.isHidden = true
        grid.dataSource = self
        grid.delegate = self
        addSubview(grid)
        KeyLabels.apply(to: lettersKey, key: .layer(.letters), shift: .off, returnTitle: nil)
        KeyLabels.apply(to: deleteKey, key: .backspace, shift: .off, returnTitle: nil)
        [lettersKey, deleteKey].forEach(addSubview)
        for (group, tab) in tabs.enumerated() {
            tab.addAction(UIAction { [weak self] _ in self?.show(group: group) }, for: .touchUpInside)
            addSubview(tab)
        }
        mark(group: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("The panel is built in code") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let stripTop = SuggestionBar.height + metrics.rowHeight * 3
        let side = KeyboardView.sidePadding
        let width = bounds.width - side * 2
        let columns = max(1, (width / Self.columnWidth).rounded(.down))
        let cell = (width / columns).rounded(.down)
        // Exactly as wide as its columns: given slack, the flow layout spreads the full rows
        // but not the last row of a group, which then sits out of line.
        grid.frame = CGRect(x: ((bounds.width - cell * columns) / 2).rounded(.down), y: 0, width: cell * columns, height: stripTop)
        layout.itemSize = CGSize(width: cell, height: cell)

        let keyWidth = width / KeyLayout.unitsPerRow * Self.stripKeyUnits
        let strip = CGRect(x: side, y: stripTop, width: width, height: metrics.rowHeight)
        lettersKey.frame = CGRect(x: strip.minX, y: strip.minY, width: keyWidth, height: strip.height)
        deleteKey.frame = CGRect(x: strip.maxX - keyWidth, y: strip.minY, width: keyWidth, height: strip.height)
        [lettersKey, deleteKey].forEach { $0.faceInset = metrics.faceInset }
        let tabWidth = (strip.width - keyWidth * 2) / CGFloat(tabs.count)
        for (index, tab) in tabs.enumerated() {
            tab.frame = CGRect(x: lettersKey.frame.maxX + CGFloat(index) * tabWidth, y: strip.minY, width: tabWidth, height: strip.height)
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { groups.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        groups[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueConfiguredReusableCell(using: cells, for: indexPath, item: groups[indexPath.section][indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let emoji = (collectionView.cellForItem(at: indexPath) as? EmojiCell)?.emoji else { return }
        onEmoji(emoji)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let top = grid.indexPathsForVisibleItems.min() else { return }
        mark(group: top.section)
    }

    private func show(group: Int) {
        guard groups.indices.contains(group), !groups[group].isEmpty else { return }
        grid.scrollToItem(at: IndexPath(item: 0, section: group), at: .top, animated: false)
        mark(group: group)
    }

    private func mark(group: Int) {
        for (index, tab) in tabs.enumerated() {
            tab.tintColor = index == group ? .label : .tertiaryLabel
        }
    }
}
