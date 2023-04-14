import Foundation

public enum Event: Hashable {
    case id(String?)
    case event(String)
    case data(Data)
    case retry(Int)

    public static func parse(data: Data) -> [Event] {
        guard let separator = "\n".data(using: .utf8) else { return [] }
        return data.split(by: separator).compactMap(parseEvent(from:))
    }

    private static func parseEvent(from data: Data) -> Event? {
        guard let colonData = ":".data(using: .utf8) else { return nil }
        guard data.first != colonData.first else { return nil }
        let field: String?
        if let colonIndex = data.firstRange(of: colonData) {
            field = String(data: data[data.startIndex..<colonIndex.lowerBound], encoding: .utf8)
            return parseField(for: field, with: data[colonIndex.upperBound...])
        } else {
            field = String(data: data, encoding: .utf8)
            return parseField(for: field, with: nil)
        }
    }

    private static func parseField(for field: String?, with value: Data?) -> Event? {
        guard let field = field?.trimmingCharacters(in: .whitespaces).lowercased() else { return nil }
        switch field {
        case "id":
            if let value,
                let id = String(data: value, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) {
                return .id(id)
            }
            return .id(nil)
        case "event":
            if let value,
                let event = String(data: value, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) {
                return .event(event)
            }
            return nil
        case "data":
            if let value {
                return .data(value)
            }
            return nil
        case "retry":
            if let value,
               let retry = String(data: value, encoding: .utf8)?.trimmingCharacters(in: .whitespaces),
               let retryTime = Int(retry) {
                return .retry(retryTime)
            }
            return nil
        default: return nil
        }
    }
}

extension Data {
    func split(by separator: Data) -> [Data] {
        var result: [Data] = []
        var separator1 = firstRange(of: separator)
        if separator1 == nil { return [self] }
        while separator1 != nil {
            let separator2 = firstRange(of: separator, in: separator1!.upperBound...)
            if let separator2 {
                result.append(self[separator1!.upperBound..<separator2.lowerBound])
            } else {
                result.append(self[separator1!.upperBound...])
            }
            separator1 = separator2
        }
        return result
    }
}
