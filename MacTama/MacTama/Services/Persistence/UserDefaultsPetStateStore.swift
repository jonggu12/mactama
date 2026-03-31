import Foundation

final class UserDefaultsPetStateStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PetState? {
        guard let data = defaults.data(forKey: Constants.petStateStorageKey) else {
            return nil
        }

        return try? decoder.decode(PetState.self, from: data)
    }

    func save(_ state: PetState) {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: Constants.petStateStorageKey)
    }
}
