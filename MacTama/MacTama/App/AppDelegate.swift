import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appEnvironment: AppEnvironment?
    private var popoverController: PopoverController?
    private var statusBarController: StatusBarController?
    private var stateCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let environment = AppEnvironment(
            store: UserDefaultsPetStateStore(),
            powerMonitor: PowerMonitor(),
            sleepWakeMonitor: SleepWakeMonitor()
        )
        let popoverController = PopoverController(appEnvironment: environment)
        let statusBarController = StatusBarController { [weak popoverController] button in
            popoverController?.toggle(relativeTo: button)
        }

        self.appEnvironment = environment
        self.popoverController = popoverController
        self.statusBarController = statusBarController

        stateCancellable = environment.$petState
            .receive(on: RunLoop.main)
            .sink { [weak statusBarController] state in
                statusBarController?.update(with: state)
            }

        environment.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appEnvironment?.stop()
    }
}
