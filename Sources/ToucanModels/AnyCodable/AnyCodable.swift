public struct AnyCodable: Codable {

    public var value: Any?

    public init<T>(_ value: T?) {
        self.value = value
    }

    public func value<T>(as: T.Type) -> T? {
        value as? T
    }
}

public extension AnyCodable {

    func boolValue() -> Bool? {
        value(as: Bool.self)
    }

    func intValue() -> Int? {
        value(as: Int.self)
    }

    func doubleValue() -> Double? {
        value(as: Double.self)
    }

    func stringValue() -> String? {
        value(as: String.self)
    }

    func arrayValue<T>(as type: T.Type) -> [T] {
        value(as: [T].self) ?? []
    }

    func dictValue() -> [String: AnyCodable] {
        value(as: [String: AnyCodable].self) ?? [:]
    }
}

extension AnyCodable: _AnyEncodable, _AnyDecodable {}

extension AnyCodable: Equatable {

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (nil, nil):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return lhs == rhs
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension AnyCodable: CustomStringConvertible {

    public var description: String {
        switch value {
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyCodable: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyCodable(\(value.debugDescription))"
        default:
            return "AnyCodable(\(description))"
        }
    }
}

extension AnyCodable: ExpressibleByNilLiteral {}
extension AnyCodable: ExpressibleByBooleanLiteral {}
extension AnyCodable: ExpressibleByIntegerLiteral {}
extension AnyCodable: ExpressibleByFloatLiteral {}
extension AnyCodable: ExpressibleByStringLiteral {}
extension AnyCodable: ExpressibleByStringInterpolation {}
extension AnyCodable: ExpressibleByArrayLiteral {}

extension AnyCodable: ExpressibleByDictionaryLiteral {

    // TODO: double check this + anyencodable support
    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        var dict: [String: AnyCodable] = [:]
        for (key, value) in elements {
            let converted: AnyCodable
            if let childDict = value as? [AnyHashable: Any] {
                var newDict: [String: AnyCodable] = [:]
                for (childKey, childValue) in childDict {
                    newDict[String(describing: childKey)] = AnyCodable(
                        childValue
                    )
                }
                converted = AnyCodable(newDict)
            }
            else if let arrayValue = value as? [Any] {
                let newArray = arrayValue.map { element -> AnyCodable in
                    if let dictElement = element as? [AnyHashable: Any] {
                        var newDict: [String: AnyCodable] = [:]
                        for (childKey, childValue) in dictElement {
                            newDict[String(describing: childKey)] = AnyCodable(
                                childValue
                            )
                        }
                        return AnyCodable(newDict)
                    }
                    return AnyCodable(element)
                }
                converted = AnyCodable(newArray)
            }
            else {
                converted = AnyCodable(value)
            }
            dict[String(describing: key)] = converted
        }
        self.init(dict)
    }
}

extension AnyCodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Int8:
            hasher.combine(value)
        case let value as Int16:
            hasher.combine(value)
        case let value as Int32:
            hasher.combine(value)
        case let value as Int64:
            hasher.combine(value)
        case let value as UInt:
            hasher.combine(value)
        case let value as UInt8:
            hasher.combine(value)
        case let value as UInt16:
            hasher.combine(value)
        case let value as UInt32:
            hasher.combine(value)
        case let value as UInt64:
            hasher.combine(value)
        case let value as Float:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [String: AnyCodable]:
            hasher.combine(value)
        case let value as [AnyCodable]:
            hasher.combine(value)
        default:
            break
        }
    }
}
