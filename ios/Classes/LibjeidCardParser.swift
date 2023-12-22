import Foundation
import CoreNFC
import libjeid
import Flutter

// MARK: - LibjeidCardParser

@available(iOS 13.0, *)
protocol LibjeidCardParser {    
    func read(tag: NFCTag) throws -> Dictionary<String, Any?>
}

// MARK: - DriverLicenseCardReader

@available(iOS 13.0, *)
class LibjeidDriverLicenseCardParser: LibjeidCardParser {
    let pin1: String?
    let pin2: String?
    
    init(pin1: String? = nil, pin2: String? = nil) {
        self.pin1 = pin1
        self.pin2 = pin2
    }
    
    func authenticate(ap: DriverLicenseAP) throws {
        let files = try ap.readFiles()
        let pinSetting = try files.getPinSetting()
        
        var pin1 = self.pin1
        var pin2 = self.pin2
        
        if !pinSetting.isPinSet {
            pin1 = "****"
            pin2 = "****"
        }
        
        guard let pin1 = pin1, let pin2 = pin2 else {
            throw InvalidMethodArgumentsError()
        }
        
        try ap.verifyPin1(pin1)
        try ap.verifyPin2(pin2)
    }
    
    func read(tag: NFCTag) throws -> Dictionary<String, Any?> {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.DL else {
            throw NfcCardTypeMismatchError()
        }
        
        let ap = try reader.selectDL()
        
        try self.authenticate(ap: ap)
        
        var files = try ap.readFiles()

        let commonData = try? files.getCommonData()
        let entries = try? files.getEntries()
        let changedEntries = try? files.getChangedEntries()
        let photo = try? files.getPhoto()
        let registeredDomicile = try? files.getRegisteredDomicile()
        let signature = try? files.getSignature()

        let photoSrc = photo?.photoData?.toBase64PngImage()
        let verifyStatus = try? files.validate()
        
        return [
            "card_type": "driver_license",
            "name": try? entries?.name.toJSON(),
            "kana": entries?.kana,
            "alias_name": try? entries?.aliasName.toJSON(),
            "call_name": entries?.callName,
            "birth_date": entries?.birthDate?.toISOString(),
            "address": try? entries?.address.toJSON(),
            "issue_date": commonData?.issueDate,
            "ref_number": entries?.refNumber,
            "color_class": entries?.colorClass,
            "expire_date": commonData?.expireDate,
            "license_number": entries?.licenseNumber,
            "psc_name": entries?.pscName,
            "registered_domicile": try? registeredDomicile?.registeredDomicile.toJSON(),
            "photo": photoSrc,
            "signature_issuer": signature?.issuer,
            "signature_subject": signature?.subject,
            "signature_ski": signature?.subjectKeyIdentifier?.map { String(format: "%.2hhx", $0) }.joined(separator: ":"),
            "verified": verifyStatus?.isValid,
            "categories": (entries?.categories ?? []).map { cat in
                [
                    "tag": cat.tag,
                    "name": cat.name,
                    "date": cat.date.toISOString(),
                    "is_licensed": cat.isLicensed
                ]
            },
            "name_history_records": changedEntries?.newNameList.map { $0.toDictionary() },
            "address_history_records": changedEntries?.newAddressList.map { $0.toDictionary() },
            "condition_history_records": changedEntries?.newConditionList.map { $0.toDictionary() },
            "condition_cancellation_history_records": changedEntries?.conditionCancellationList.map { $0.toDictionary() },
            "registered_domicile_history_records": changedEntries?.newRegisteredDomicileList.map { $0.toDictionary() }
        ]
    }
}

// MARK: - MyNumberCardReader

@available(iOS 13.0, *)
class LibjeidMyNumberCardParser: LibjeidCardParser {
    let pin: String
    
    init(pin: String) {
        self.pin = pin
    }
    
    func authenticate(textAp: INTextAP, visualAp: INVisualAP) throws {
        try textAp.verifyPin(pin)
        try visualAp.verifyPin(pin)
    }
    
    func read(tag: NFCTag) throws -> Dictionary<String, Any?> {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.IN else {
            throw NfcCardTypeMismatchError()
        }

        let textAp = try reader.selectINText()
        let visualAp = try reader.selectINVisual()
        
        try self.authenticate(textAp: textAp, visualAp: visualAp)
        
        let files = try textAp.readFiles()

        let myNumberData = try? files.getMyNumber()
        let attributes = try? files.getAttributes()
        
        let visualFiles = try? visualAp.readFiles()
        let visualEntries = try? visualFiles?.getEntries()
        
        let expire = visualEntries?.expireDate
        let photoSrc = visualEntries?.photoData?.toBase64PngImage()
        let nameImageSrc = visualEntries?.name?.toBase64PngImage()
        let addressImageSrc = visualEntries?.address?.toBase64PngImage()
        let myNumberImageSrc = try? visualFiles?.getMyNumber().myNumber?.toBase64PngImage()
        let verified = try? visualFiles?.validate().isValid
        
        return [
            "card_type": "my_number",
            "my_number": myNumberData?.myNumber,
            "name": attributes?.name,
            "address": attributes?.address,
            "birth_date": attributes?.birthDate,
            "sex": attributes?.sex,
            "expire_date": expire,
            "photo": photoSrc,
            "nameImage": nameImageSrc,
            "addressImage": addressImageSrc,
            "myNumberImage": myNumberImageSrc,
            "verified": verified
        ]
    }
}

// MARK: - ResidentCardParser

@available(iOS 13.0, *)
class LibjeidResidentCardParser: LibjeidCardParser {
    let cardNumber: String
    
    init(cardNumber: String) {
        self.cardNumber = cardNumber
    }
    
    func authenticate(ap: ResidenceCardAP) throws {
        let cardKey = try RCKey(cardNumber)
        try ap.startAC(cardKey)
    }
    
    func read(tag: NFCTag) throws -> Dictionary<String, Any?> {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.RC else {
            throw NfcCardTypeMismatchError()
        }
        
        let ap = try reader.selectRC()
        
        try self.authenticate(ap: ap)
        
        let files = try ap.readFiles()
        
        let cardType = try? files.getCardType()
        let address = try? files.getAddress()
        let photo = try? files.getPhoto()
        let cardEntries = try? files.getCardEntries()
        
        let photoSrc = photo?.photoData?.toBase64PngImage()
        let cardFrontPhotoSrc = try? cardEntries?.pngData().toBase64PngImage()
        var updateStatus: String?
        var individualPermission: String?
        var comprehensivePermission: String?

        // Resident card?
        if cardType?.type == "1" {
            updateStatus = try files.getUpdateStatus().status
            individualPermission = try files.getIndividualPermission().permission
            comprehensivePermission = try files.getComprehensivePermission().permission
        }
        
        return [
            "card_type": "resident_card",
            "type": cardType?.type,
            "photo": photoSrc,
            "address": address?.address,
            "address_code": address?.code,
            "address_updated_at": address?.date,
            "card_front_photo": cardFrontPhotoSrc,
            "update_status": updateStatus,
            "individual_permission": individualPermission,
            "comprehensive_permission": comprehensivePermission
        ]
    }
}

// MARK: - MyNumberCardReader

@available(iOS 13.0, *)
class LibjeidPassportCardParser: LibjeidCardParser {
    let cardNumber: String
    let birthDate: String
    let expiredDate: String
    
    init(cardNumber: String, birthDate: String, expiredDate: String) {
        self.cardNumber = cardNumber
        self.birthDate = birthDate
        self.expiredDate = expiredDate
    }
    
    func authenticate(ap: PassportAP) throws {
        let epKey = try EPKey(cardNumber, birthDate, expiredDate)

        try ap.startBAC(epKey)
    }
    
    func read(tag: NFCTag) throws -> Dictionary<String, Any?> {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.EP else {
            throw NfcCardTypeMismatchError()
        }

        let ap = try reader.selectEP()
        
        try self.authenticate(ap: ap)
        
        let files = try ap.readFiles()
        let commonData = try? files.getCommonData()
        let dataGroup1 = try? files.getDataGroup1()
        let dataGroup2 = try? files.getDataGroup2()
        
        let dataGroup1Mrz = dataGroup1?.mrz != nil
            ? try? EPMRZ(dataGroup1!.mrz!)
            : nil
        
        let photoSrc = dataGroup2?.faceJpeg?.toBase64PngImage()
        let passiveAuthenticationResult = try? files.validate().isValid
        let activeAuthenticationResult = try? ap.activeAuthentication(files)
        
        return [
            "card_type": "passport",
            "fid": commonData?.fid,
            "sfid": commonData?.shortFID,
            "lds_version": commonData?.ldsVersion,
            "unicode_version": commonData?.unicodeVersion,
            "tags": commonData?.tagList,
            "document_code": dataGroup1Mrz?.documentCode,
            "issuing_country": dataGroup1Mrz?.issuingCountry,
            "name": dataGroup1Mrz?.name,
            "surname": dataGroup1Mrz?.surname,
            "given_name": dataGroup1Mrz?.givenName,
            "passport_number": dataGroup1Mrz?.passportNumber,
            "passport_number_check_digit": dataGroup1Mrz?.passportNumberCheckDigit,
            "nationality": dataGroup1Mrz?.nationality,
            "birth_date": dataGroup1Mrz?.birthDate,
            "birth_date_check_digit": dataGroup1Mrz?.birthDateCheckDigit,
            "sex": dataGroup1Mrz?.sex,
            "expiration_date": dataGroup1Mrz?.expirationDate,
            "expiration_date_check_digit": dataGroup1Mrz?.expirationDateCheckDigit,
            "optiona_data": dataGroup1Mrz?.optionalData,
            "optional_data_check_digit": dataGroup1Mrz?.optionalDataCheckDigit,
            "composite_check_digit": dataGroup1Mrz?.compositeCheckDigit,
            "photo": photoSrc,
            "passive_authentication_result": passiveAuthenticationResult,
            "active_authentication_result": activeAuthenticationResult
        ]
    }
}

// MARK: - Libjeid Helpers

extension DLDate {
    func toISOString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.string(from: dateValue).appending("Z")
    }
}

extension DLChangedEntry {
    func toDictionary() -> Dictionary<String, Any?> {
        return [
            "date": self.date.toISOString(),
            "value": self.value.toString(),
            "psc": self.psc
        ]
    }
}

extension Data {
    func toBase64PngImage() -> String? {
        let base64 = self.base64EncodedString()
        return "data:image/png;base64,\(base64)"
    }
}

