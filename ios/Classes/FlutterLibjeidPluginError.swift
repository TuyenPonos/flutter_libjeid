import Foundation
import Flutter
import libjeid

class FlutterLibjeidError: Error & Codable {
    let code: String
    let details: Dictionary<String, String?>?

    init(code: String, details: Dictionary<String, String?>? = nil) {
        self.code = code
        self.details = details
    }
    
    static func from(_ error: Error) -> FlutterLibjeidError {
        if let flutterLibjeidError = error as? FlutterLibjeidError {
            return flutterLibjeidError
        }
        
        if let jeidError = error as? JeidError {
            return jeidError.toFlutterLibjeidError()
        }
        
        return FlutterLibjeidError(code: error.localizedDescription)
    }
    
    func toFlutterError() -> FlutterError {
        return FlutterError(code: code, message: code, details: details)
    }
    
    func toDictionary() -> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

class NfcNotAvailableError: FlutterLibjeidError {
    convenience init() {
        self.init(code: "NfcNotAvailable")
    }
}

class NfcTagUnableToConnectError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "NfcTagUnableToConnect", details: details)
    }
}

class NfcCardBlockedError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "NfcCardBlocked", details: details)
    }
}

class NfcCardTypeMismatchError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "NfcCardTypeMismatch", details: details)
    }
}

class InvalidMethodArgumentsError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "InvalidMethodArguments", details: details)
    }
}

class InvalidCardPinError: FlutterLibjeidError {
    convenience init(counter: Int) {
        self.init(code: "InvalidPin", details: ["remainingTimes": "\(counter)"])
    }
}

class InvalidCardKeyError: FlutterLibjeidError {
    convenience init(message: String) {
        self.init(code: "InvalidKey", details: ["message": message])
    }
}

class UnknownError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "Unknown", details: details)
    }
    
    convenience init(code: String? = nil, message: String? = nil) {
        self.init(details: ["code": code ?? message, "message": message])
    }
}

// MARK: - JeidError.toFlutterLibjeidError

extension JeidError {
    func toFlutterLibjeidError() -> FlutterLibjeidError {
        switch (self) {
        case .invalidKey(let message):
            if self.isBlocked == true {
                return NfcCardBlockedError()
            }
            return InvalidCardKeyError(message: message)

        case .invalidPin(let counter):
            if self.isBlocked == true {
                return NfcCardBlockedError()
            }
            return InvalidCardPinError(counter: counter)
            
        default:
            return UnknownError(code: "\(self.errorCode)", message: self.localizedDescription)
            
        }
    }
}
