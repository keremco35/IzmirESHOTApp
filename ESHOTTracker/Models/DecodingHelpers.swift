import Foundation

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

extension KeyedDecodingContainer where Key == DynamicCodingKey {
    func decodeString(forKeys keys: [String]) -> String? {
        for key in keys {
            if let value = try? decode(String.self, forKey: DynamicCodingKey(stringValue: key)) {
                return value
            }
            if let value = try? decode(Int.self, forKey: DynamicCodingKey(stringValue: key)) {
                return "\(value)"
            }
        }
        return nil
    }

    func decodeDouble(forKeys keys: [String]) -> Double? {
        for key in keys {
            if let value = try? decode(Double.self, forKey: DynamicCodingKey(stringValue: key)) {
                return value
            }
            if let value = try? decode(String.self, forKey: DynamicCodingKey(stringValue: key)) {
                return Double(value.replacingOccurrences(of: ",", with: ".")) 
            }
        }
        return nil
    }
}
