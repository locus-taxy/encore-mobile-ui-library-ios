import Foundation

/// Keys read out of `ChecklistItem.additionalOptions` for controller behaviour.
enum ChecklistControllerKeys {
    static let inputType = "inputType"
}

public extension ChecklistItem {
    /// True for item formats whose input feeds `show` / `optionsSource` expressions (HLD §3.3):
    /// choices, booleans, and numeric text fields. A dynamic single choice behaves like a static one
    /// once resolved. Photo, signature, free text, rating, and date/time never enter the arguments.
    var isVisibilityController: Bool {
        switch format {
        case .singleChoice, .singleChoiceDynamic, .boolean, .multiChoice:
            return true
        case .textField:
            let inputType = additionalOptions?[ChecklistControllerKeys.inputType]?.uppercased()
            return inputType == "NUMBER" || inputType == "DECIMAL"
        default:
            return false
        }
    }

    /// Converts a controller item's renderer state into the JSON argument value that expressions
    /// compare against (HLD §3.3): the option *key* for choices (array of keys for multi-choice), the
    /// boolean for toggles, the number for numeric text fields. Unanswered / unparseable ⇒ `"null"`.
    ///
    /// Returned as a JSON string for the evaluator boundary. Mirrors Android's `controllerArgument`.
    func controllerArgument(_ value: Any?) -> String {
        switch format {
        case .boolean:
            return (value as? Bool ?? false) ? "true" : "false"
        case .singleChoice, .singleChoiceDynamic:
            let index = value as? Int ?? -1
            guard let allowed = allowedValues, index >= 0, index < allowed.count else { return "null" }
            return ChecklistJSON.encode(scalar: allowed[index].key)
        case .multiChoice:
            let indices = (value as? Set<Int>)?.sorted() ?? []
            let keys: [String] = indices.compactMap { i in
                guard let allowed = allowedValues, i >= 0, i < allowed.count else { return nil }
                return allowed[i].key
            }
            return ChecklistJSON.encode(stringArray: keys)
        case .textField:
            guard let text = value as? String, let number = Double(text) else { return "null" }
            return ChecklistJSON.encode(number: number)
        default:
            return "null"
        }
    }
}

/// Minimal JSON scalar/array encoding for the evaluator argument boundary. The kit only ever emits
/// strings, string arrays, booleans (inline above), and numbers — no need for a general encoder.
enum ChecklistJSON {
    static func encode(scalar string: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: string, options: [.fragmentsAllowed]),
              let json = String(data: data, encoding: .utf8) else { return "null" }
        return json
    }

    static func encode(stringArray array: [String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: array),
              let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }

    static func encode(number: Double) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: number, options: [.fragmentsAllowed]),
              let json = String(data: data, encoding: .utf8) else { return "null" }
        return json
    }
}
