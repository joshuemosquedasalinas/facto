import Foundation

enum EnvLoader {
    static func value(forKey key: String) -> String? {
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value
        }

        for url in candidateURLs() {
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let values = parse(contents)
            if let value = values[key], !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private static func candidateURLs() -> [URL] {
        let fileManager = FileManager.default
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let bundleURL = Bundle.main.bundleURL
        let applicationSupport = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("shadow", isDirectory: true)
            .appendingPathComponent(".env")

        var urls = [currentDirectory.appendingPathComponent(".env")]
        var cursor = bundleURL
        for _ in 0..<6 {
            urls.append(cursor.appendingPathComponent(".env"))
            cursor.deleteLastPathComponent()
        }

        if let applicationSupport {
            urls.append(applicationSupport)
        }

        var unique: [URL] = []
        var seen = Set<String>()
        for url in urls where seen.insert(url.path).inserted {
            unique.append(url)
        }

        return unique
    }

    private static func parse(_ contents: String) -> [String: String] {
        var result: [String: String] = [:]

        for line in contents.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"' ").union(.whitespacesAndNewlines))
            result[key] = value
        }

        return result
    }
}
