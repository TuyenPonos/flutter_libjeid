import Foundation

protocol CardData: Codable {}

struct DriverLicenseCardData: CardData {
    let name: String
    let kana: String?
    let aliasName: String
    let callName: String?
    let birthDate: String?
    let address: String
    let issueDate: String?
    let refNumber: String?
    let colorClass: String?
    let expireDate: String?
    let licenseNumber: String?
    let pscName: String?
    let registeredDomicile: String
    let photo: String?
    let signatureIssuer: String?
    let signatureSubject: String?
    let signatureSKI: String?
    let verified: Bool?
    let categories: [Category]?
    let nameHistoryRecords: [ChangeHistory]
    let addressHistoryRecords: [ChangeHistory]
    let conditionHistoryRecords: [ChangeHistory]
    let conditionCancellationHistoryRecords: [ChangeHistory]
    let registeredDomicileHistoryRecords: [ChangeHistory]
    
    struct Category: Codable {
        let tag: Int
        let name: String
        let date: String
        let isLicensed: Bool
    }
    
    struct ChangeHistory: Codable {
        let date: String
        let value: String
        let psc: String
    }
}

struct MyNumberCardData: CardData {
    let myNumber: String?
    let name: String?
    let address: String?
    let birthDate: String?
    let sex: String?
    let expireDate: String?
    let photo: String?
    let nameImage: String?
    let addressImage: String?
    let myNumberImage: String?
    let verified: Bool?
}

struct ResidentCardData: CardData {
    let cardType: String?
    let photo: String?
    let address: String?
    let addressCode: String?
    let addressUpdatedAt: String?
    let cardFrontPhoto: String?
    let updateStatus: String?
    let individualPermission: String?
    let comprehensivePermission: String?
}

struct PassportCardData: CardData {
    let fid: String
    let sfid: UInt8
    let ldsVersion: String?
    let unicodeVersion: String?
    let tags: [UInt8]
    let documentCode: String?
    let issuingCountry: String?
    let name: String?
    let surname: String?
    let givenName: String?
    let passportNumber: String?
    let passportNumberCheckDigit: String?
    let nationality: String?
    let birthDate: String?
    let birthDateCheckDigit: String?
    let sex: String?
    let expirationDate: String?
    let expirationDateCheckDigit: String?
    let optionaData: String?
    let optionalDataCheckDigit: String?
    let compositeCheckDigit: String?
    let photo: String?
    let passiveAuthenticationResult: Bool?
    let activeAuthenticationResult: Bool?
}

enum FlutterLibjeidEvent {
    case scanning
    case connecting
    case parsing
    case success(data: CardData)
    case failed(error: FlutterLibjeidError)
    case cancelled
    
    func toJSON() -> Dictionary<String, Any?> {
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
