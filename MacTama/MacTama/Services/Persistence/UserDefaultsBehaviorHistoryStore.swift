import Foundation

final class UserDefaultsBehaviorHistoryStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> BehaviorHistory? {
        guard let data = defaults.data(forKey: Constants.behaviorHistoryStorageKey) else {
            return nil
        }

        return try? decoder.decode(BehaviorHistory.self, from: data)
    }

    func save(_ history: BehaviorHistory) {
        guard let data = try? encoder.encode(history) else { return }
        defaults.set(data, forKey: Constants.behaviorHistoryStorageKey)
    }
}
