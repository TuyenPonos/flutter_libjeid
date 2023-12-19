import Foundation
import Flutter
import libjeid

class FlutterLibjeidError: Error & Codable {
    let code: String
    let message: String
    let details: Dictionary<String, String?>?

    init(code: String, message: String, details: Dictionary<String, String?>? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
    
    static func from(_ error: Error) -> FlutterLibjeidError {
        if error is FlutterLibjeidError {
            return error as! FlutterLibjeidError
        }
        
        return FlutterLibjeidError(code: error.localizedDescription, message: error.localizedDescription)
    }
    
    func toFlutterError() -> FlutterError {
        return FlutterError(code: code, message: message, details: details)
    }
}

class NfcNotAvailableError: FlutterLibjeidError {
    convenience init() {
        self.init(code: "NfcNotAvailable", message: "NFC is not available on this device")
    }
}

class NfcTagUnableToConnectError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "NfcTagUnableToConnect", message: "Cannot connect to NFC tag", details: details)
    }
}

class NfcCardBlockedError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "NfcCardBlocked", message: "The card is blocked", details: details)
    }
}

class NfcCardTypeMismatchError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "NfcCardTypeMismatch", message: "The card type does not match", details: details)
    }
}

class InvalidMethodArgumentsError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "InvalidMethodArguments", message: "Invalid method channel arguments", details: details)
    }
}

class UnknownError: FlutterLibjeidError {
    convenience init(details: Dictionary<String, String?>? = nil) {
        self.init(code: "Unknown", message: "Unknown error", details: details)
    }
    
    convenience init(code: String? = nil, message: String? = nil) {
        self.init(details: ["code": code ?? message, "message": message])
    }
}

extension JeidError {
    func toFlutterLibjeidError() -> FlutterLibjeidError {
        switch (self) {
        case .decodeFailed(let message):
            return FlutterLibjeidError(code: "DecodeFailed", message: message)
            
        case .encodeFailed(let message):
            return FlutterLibjeidError(code: "EncodeFailed", message: message)
            
        case .fileNotFound(let message):
            return FlutterLibjeidError(code: "FileNotFound", message: message)
            
        case .invalidKey(let message):
            if self.isBlocked == true {
                return NfcCardBlockedError()
            }
            return FlutterLibjeidError(code: "InvalidKey", message: message)

        case .invalidPin(let counter):
            if self.isBlocked == true {
                return NfcCardBlockedError()
            }
            return FlutterLibjeidError(code: "InvalidPin", message: "Invalid PIN code, remaining time(s): \(counter)", details: ["remainingTimes": "\(counter)"])
            
        case .securityStatusNotSatisfied:
            return FlutterLibjeidError(code: "SecurityStatusNotSatisfied", message: "SecurityStatusNotSatisfied")
            
        case .signatureVerificationFailed(let message):
            return FlutterLibjeidError(code: "SignatureVerificationFailed", message: message)
            
        case .transceiveFailed(let message):
            return FlutterLibjeidError(code: "TransceiveFailed", message: message)
            
        default:
            return UnknownError(code: "\(self.errorCode)", message: self.localizedDescription)
            
        }
    }
}
