import Foundation

enum FlutterLibjeidEvent {
    case scanning
    case connecting
    case parsing
    case success(data: Dictionary<String, Any?>)
    case failed(error: Dictionary<String, Any?>?)
    case cancelled
    
    func toDictionary() -> Dictionary<String, Any?> {
        switch (self) {
        case .scanning:
            return ["event": "scanning"]
            
        case .connecting:
            return ["event": "connecting"]
            
        case .parsing:
            return ["event": "parsing"]
            
        case .success(let data):
            return ["event": "success", "data": data]
            
        case .failed(let error):
            return ["event": "failed", "data": error]
            
        case .cancelled:
            return ["event": "cancelled"]
        }
    }
}
