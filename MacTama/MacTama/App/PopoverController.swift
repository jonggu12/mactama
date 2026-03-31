import AppKit
import SwiftUI

final class PopoverController {
    private let popover = NSPopover()

    init(appEnvironment: AppEnvironment) {
        popover.contentSize = Constants.popoverSize
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView().environmentObject(appEnvironment)
        )
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
        }
    }
}
