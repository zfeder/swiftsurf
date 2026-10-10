//
//  PersistentStore.swift
//  swiftsurf
//

import Foundation

/// Stores a Codable value as JSON in Application Support, migrating it once from UserDefaults.
struct PersistentStore<Value: Codable> {
    let fileURL: URL
    let legacyDefaultsKey: String?

    init(name: String, legacyDefaultsKey: String? = nil,
         directory: URL = PersistentStoreLocation.defaultDirectory) {
        fileURL = directory.appendingPathComponent(name).appendingPathExtension("json")
        self.legacyDefaultsKey = legacyDefaultsKey
    }

    func load() -> Value? {
        if let data = try? Data(contentsOf: fileURL) {
            return try? JSONDecoder().decode(Value.self, from: data)
        }
        guard let key = legacyDefaultsKey,
              let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(Value.self, from: data) else { return nil }
        save(value)
        UserDefaults.standard.removeObject(forKey: key)
        return value
    }

    func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let url = fileURL
        PersistentStoreLocation.queue.async {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }
}

enum PersistentStoreLocation {
    static let queue = DispatchQueue(label: "SwiftSurf.PersistentStore", qos: .utility)

    static var defaultDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("SwiftSurf", isDirectory: true)
    }
}
