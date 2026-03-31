import AppKit

final class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onClick: (NSStatusBarButton) -> Void

    init(onClick: @escaping (NSStatusBarButton) -> Void) {
        self.onClick = onClick
        configureStatusItem()
    }

    func update(with state: PetState) {
        guard let button = statusItem.button else { return }
        button.title = state.menuBarTitle
        button.toolTip = state.tooltipText
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.title = PetState.initial.menuBarTitle
        button.action = #selector(handleClick(_:))
        button.target = self
    }

    @objc
    private func handleClick(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        onClick(button)
    }
}
