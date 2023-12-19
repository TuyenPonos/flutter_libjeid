import Foundation
import CoreNFC
import libjeid
import Flutter

// MARK: - LibjeidCardParser

@available(iOS 13.0, *)
protocol LibjeidCardParser {
    associatedtype T: CardData
    
    func read(tag: NFCTag) throws -> T
}

// MARK: - DriverLicenseCardReader

@available(iOS 13.0, *)
class LibjeidDriverLicenseCardParser: LibjeidCardParser {
    typealias T = DriverLicenseCardData

    var pin1: String?
    var pin2: String?
    
    init(pin1: String? = nil, pin2: String? = nil) {
        self.pin1 = pin1
        self.pin2 = pin2
    }
    
    func authenticate(ap: DriverLicenseAP) throws {
        let files = try ap.readFiles()
        let pinSetting = try files.getPinSetting()
        
        if !pinSetting.isPinSet {
            pin1 = "****"
            pin2 = "****"
        }
        
        guard let pin1 = self.pin1, let pin2 = self.pin2 else {
            throw InvalidMethodArgumentsError()
        }
        
        try ap.verifyPin1(pin1)
        try ap.verifyPin2(pin2)
    }
    
    func read(tag: NFCTag) throws -> DriverLicenseCardData {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.DL else {
            throw NfcCardTypeMismatchError()
        }
        
        let ap = try reader.selectDL()
        
        try self.authenticate(ap: ap)
        
        var files = try ap.readFiles()

        let commonData = try files.getCommonData()
        let entries = try files.getEntries()
        let changedEntries = try files.getChangedEntries()
        let photo = try files.getPhoto()
        let registeredDomicile = try files.getRegisteredDomicile()
        let signature = try files.getSignature()

        let photoSrc = photo.photoData?.toBase64PngImage()
        let verifyStatus = try? files.validate()
        
        return DriverLicenseCardData(
            name: entries.name.toString(),
            kana: entries.kana,
            aliasName: entries.aliasName.toString(),
            callName: entries.callName,
            birthDate: entries.birthDate?.toISOString(),
            address: entries.address.toString(),
            issueDate: commonData.issueDate,
            refNumber: entries.refNumber,
            colorClass: entries.colorClass,
            expireDate: commonData.expireDate,
            licenseNumber: entries.licenseNumber,
            pscName: entries.pscName,
            registeredDomicile: registeredDomicile.registeredDomicile.toString(),
            photo: photoSrc,
            signatureIssuer: signature.issuer,
            signatureSubject: signature.subject,
            signatureSKI: signature.subjectKeyIdentifier?.map { String(format: "%.2hhx", $0) }.joined(separator: ":"),
            verified: verifyStatus?.isValid,
            categories: (entries.categories ?? []).map { cat in
                DriverLicenseCardData.Category(
                    tag: cat.tag,
                    name: cat.name,
                    date: cat.date.toISOString(),
                    isLicensed: cat.isLicensed
                )
            },
            nameHistoryRecords: changedEntries.newNameList.map { $0.toChangeHistory() },
            addressHistoryRecords: changedEntries.newAddressList.map { $0.toChangeHistory() },
            conditionHistoryRecords: changedEntries.newConditionList.map { $0.toChangeHistory() },
            conditionCancellationHistoryRecords: changedEntries.conditionCancellationList.map { $0.toChangeHistory() },
            registeredDomicileHistoryRecords: changedEntries.newRegisteredDomicileList.map { $0.toChangeHistory() }
        )
    }
}

// MARK: - MyNumberCardReader

@available(iOS 13.0, *)
class LibjeidMyNumberCardParser: LibjeidCardParser {
    typealias T = MyNumberCardData
    
    var pin: String
    
    init(pin: String) {
        self.pin = pin
    }
    
    func authenticate(textAp: INTextAP, visualAp: INVisualAP) throws {
        try textAp.verifyPin(pin)
        try visualAp.verifyPin(pin)
    }
    
    func read(tag: NFCTag) throws -> MyNumberCardData {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.IN else {
            throw NfcCardTypeMismatchError()
        }

        let textAp = try reader.selectINText()
        let visualAp = try reader.selectINVisual()
        
        try self.authenticate(textAp: textAp, visualAp: visualAp)
        
        let files = try textAp.readFiles()

        let myNumberData = try files.getMyNumber()
        let attributes = try files.getAttributes()
        
        let visualFiles = try visualAp.readFiles()
        let visualEntries = try visualFiles.getEntries()
        
        let expire = visualEntries.expireDate
        let photoSrc = visualEntries.photoData?.toBase64PngImage()
        let nameImageSrc = visualEntries.name?.toBase64PngImage()
        let addressImageSrc = visualEntries.address?.toBase64PngImage()
        let myNumberImageSrc = try? visualFiles.getMyNumber().myNumber?.toBase64PngImage()
        let verified = try? visualFiles.validate().isValid

        return MyNumberCardData(
            myNumber: myNumberData.myNumber,
            name: attributes.name,
            address: attributes.address,
            birthDate: attributes.birthDate,
            sex: attributes.sex,
            expireDate: expire,
            photo: photoSrc,
            nameImage: nameImageSrc,
            addressImage: addressImageSrc,
            myNumberImage: myNumberImageSrc,
            verified: verified
        )
    }
}

// MARK: - ResidentCardParser

@available(iOS 13.0, *)
class LibjeidResidentCardParser: LibjeidCardParser {
    typealias T = ResidentCardData
    
    var cardNumber: String
    
    init(cardNumber: String) {
        self.cardNumber = cardNumber
    }
    
    func authenticate(ap: ResidenceCardAP) throws {
        let cardKey = try RCKey(cardNumber)
        try ap.startAC(cardKey)
    }
    
    func read(tag: NFCTag) throws -> ResidentCardData {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.RC else {
            throw NfcCardTypeMismatchError()
        }
        
        let ap = try reader.selectRC()
        
        try self.authenticate(ap: ap)
        
        let files = try ap.readFiles()
        
        let cardType = try files.getCardType()
        let address = try files.getAddress()
        let photo = try files.getPhoto()
        let cardEntries = try files.getCardEntries()
        
        let photoSrc = photo.photoData?.toBase64PngImage()
        let cardFrontPhotoSrc = try cardEntries.pngData().toBase64PngImage()
        var updateStatus: String?
        var individualPermission: String?
        var comprehensivePermission: String?

        // Resident card?
        if cardType.type == "1" {
            updateStatus = try files.getUpdateStatus().status
            individualPermission = try files.getIndividualPermission().permission
            comprehensivePermission = try files.getComprehensivePermission().permission
        }

        return ResidentCardData(
            cardType: cardType.type,
            photo: photoSrc,
            address: address.address,
            addressCode: address.code,
            addressUpdatedAt: address.date,
            cardFrontPhoto: cardFrontPhotoSrc,
            updateStatus: updateStatus,
            individualPermission: individualPermission,
            comprehensivePermission: comprehensivePermission
        )
    }
}

// MARK: - MyNumberCardReader

@available(iOS 13.0, *)
class LibjeidPassportCardParser: LibjeidCardParser {
    typealias T = PassportCardData
    
    var cardNumber: String
    var birthDate: String
    var expiredDate: String
    
    init(cardNumber: String, birthDate: String, expiredDate: String) {
        self.cardNumber = cardNumber
        self.birthDate = birthDate
        self.expiredDate = expiredDate
    }
    
    func authenticate(ap: PassportAP) throws {
        let epKey = try EPKey(cardNumber, birthDate, expiredDate)

        try ap.startBAC(epKey)
    }
    
    func read(tag: NFCTag) throws -> PassportCardData {
        let reader = try JeidReader(tag)
        let type = try reader.detectCardType()
        
        guard type == CardType.EP else {
            throw NfcCardTypeMismatchError()
        }

        let ap = try reader.selectEP()
        
        try self.authenticate(ap: ap)
        
        let files = try ap.readFiles()
        let commonData = try files.getCommonData()
        let dataGroup1 = try files.getDataGroup1()
        let dataGroup2 = try files.getDataGroup2()
        
        let dataGroup1Mrz = dataGroup1.mrz != nil
            ? try? EPMRZ(dataGroup1.mrz!)
            : nil
        
        let photo = dataGroup2.faceJpeg?.toBase64PngImage()
        let passiveAuthenticationResult = try? files.validate().isValid
        let activeAuthenticationResult = try? ap.activeAuthentication(files)
        
        return PassportCardData(
            fid: commonData.fid,
            sfid: commonData.shortFID,
            ldsVersion: commonData.ldsVersion,
            unicodeVersion: commonData.unicodeVersion,
            tags: commonData.tagList,
            documentCode: dataGroup1Mrz?.documentCode,
            issuingCountry: dataGroup1Mrz?.issuingCountry,
            name: dataGroup1Mrz?.name,
            surname: dataGroup1Mrz?.surname,
            givenName: dataGroup1Mrz?.givenName,
            passportNumber: dataGroup1Mrz?.passportNumber,
            passportNumberCheckDigit: dataGroup1Mrz?.passportNumberCheckDigit,
            nationality: dataGroup1Mrz?.nationality,
            birthDate: dataGroup1Mrz?.birthDate,
            birthDateCheckDigit: dataGroup1Mrz?.birthDateCheckDigit,
            sex: dataGroup1Mrz?.sex,
            expirationDate: dataGroup1Mrz?.expirationDate,
            expirationDateCheckDigit: dataGroup1Mrz?.expirationDateCheckDigit,
            optionaData: dataGroup1Mrz?.optionalData,
            optionalDataCheckDigit: dataGroup1Mrz?.optionalDataCheckDigit,
            compositeCheckDigit: dataGroup1Mrz?.compositeCheckDigit,
            photo: photo,
            passiveAuthenticationResult: passiveAuthenticationResult,
            activeAuthenticationResult: activeAuthenticationResult
        )
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
    func toChangeHistory() -> DriverLicenseCardData.ChangeHistory {
        return DriverLicenseCardData.ChangeHistory(
            date: self.date.toISOString(),
            value: self.value.toString(),
            psc: self.psc
        )
    }
}

extension Data {
    func toBase64PngImage() -> String? {
        let base64 = self.base64EncodedString()
        return "data:image/png;base64,\(base64)"
    }
}

