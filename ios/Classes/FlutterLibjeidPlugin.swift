import Flutter
import UIKit
import libjeid
import CoreNFC

@available(iOS 13.0, *)
public class FlutterLibjeidPlugin: NSObject, FlutterPlugin, NFCTagReaderSessionDelegate {
    
    let notInputCardNumber = "not_input_card_number"
    let notInputCardPin = "not_input_card_pin"
    let nfcConnectError = "nfc_connect_error"
    let incorrectCardNumber = "incorrect_card_number"
    let incorrectCardPin = "incorrect_card_pin"
    let invalidCardType = "invalid_card_type"
    let unknown = "unknown"
    let badArguments = "bad_arguments"
    let DPIN = "****"
    
    var session: NFCTagReaderSession?
    var callback: FlutterResult?
    private var RCCardNumber: String?
    private var INCardPin: String?
    private var cardType: CardType?
    private var DLCardPin1: String?
    private var DLCardPin2: String?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_libjeid", binaryMessenger: registrar.messenger())
        let instance = FlutterLibjeidPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.callback = result
        switch call.method {
        case "scanRCCard":
            self.cardType = CardType.RC
            if let args = call.arguments as? Dictionary<String, Any> , let cardNumber = args["card_number"] as? String {
                if(cardNumber.isEmpty){
                    result(FlutterError(code: notInputCardNumber, message: "Please input a valid card number", details: nil))
                    return
                }
                if(!NFCReaderSession.readingAvailable){
                    result(FlutterError(code: nfcConnectError, message: "NFC Session is unavailable", details: nil))
                    return
                }
                self.RCCardNumber = cardNumber
                if let _ = self.session {
                    result(FlutterError(code: nfcConnectError, message: "Please wait and try again", details: nil))
                } else {
                    self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.global())
                    self.session?.alertMessage = "カードに端末をかざしてください"
                    self.session?.begin()
                }
            }
            else {
                result(FlutterError(code: badArguments, message: "Bad arguments. Please check again", details: nil))
            }
            break
        case "scanINCard":
            self.cardType = CardType.IN
            if let args = call.arguments as? Dictionary<String, Any> , let cardPin = args["pin"] as? String {
                if(cardPin.isEmpty || cardPin.count != 4){
                    result(FlutterError(code: notInputCardPin, message: "Please input a valid card pin", details: nil))
                    return
                }
                if(!NFCReaderSession.readingAvailable){
                    result(FlutterError(code: nfcConnectError, message: "NFC Session is unavailable", details: nil))
                    return
                }
                self.INCardPin = cardPin
                if let _ = self.session {
                    result(FlutterError(code: nfcConnectError, message: "Please wait and try again", details: nil))
                } else {
                    self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.global())
                    self.session?.alertMessage = "カードに端末をかざしてください"
                    self.session?.begin()
                }
            }
            else {
                result(FlutterError(code: badArguments, message: "Bad arguments. Please check again", details: nil))
            }
            break
        case "scanDLCard":
            self.cardType = CardType.DL
            if let args = call.arguments as? Dictionary<String, Any> , let cardPin1 = args["pin_1"] as? String,let cardPin2 = args["pin_2"] as? String {
                if(cardPin1.isEmpty || cardPin1.count != 4){
                    result(FlutterError(code: notInputCardPin, message: "Please input a valid card pin 1", details: nil))
                    return
                }
                if(cardPin2.isEmpty || cardPin2.count != 4){
                    result(FlutterError(code: notInputCardPin, message: "Please input a valid card pin 2", details: nil))
                    return
                }
                if(!NFCReaderSession.readingAvailable){
                    result(FlutterError(code: nfcConnectError, message: "NFC Session is unavailable", details: nil))
                    return
                }
                self.DLCardPin1 = cardPin1
                self.DLCardPin2 = cardPin2
                if let _ = self.session {
                    result(FlutterError(code: nfcConnectError, message: "Please wait and try again", details: nil))
                } else {
                    self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.global())
                    self.session?.alertMessage = "カードに端末をかざしてください"
                    self.session?.begin()
                }
            }
            else {
                result(FlutterError(code: badArguments, message: "Bad arguments. Please check again", details: nil))
            }
            break
        case "stopScan":
            self.cardType = nil
            self.INCardPin = nil
            self.RCCardNumber = nil
            self.DLCardPin1 = nil
            self.DLCardPin2 = nil
            if((self.session?.isReady) != nil){
                self.session?.invalidate()
            }
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("tagReaderSessionDidBecomeActive: \(Thread.current)")
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError {
            if nfcError.code != .readerSessionInvalidationErrorUserCanceled {
                print("tagReaderSession error: " + nfcError.localizedDescription)
                self.callback?(FlutterError(code: nfcConnectError, message: "Session error: " + nfcError.localizedDescription, details: nil))
                if nfcError.code == .readerSessionInvalidationErrorSessionTerminatedUnexpectedly {
                    self.callback?(FlutterError(code: nfcConnectError, message: "Please wait and try again", details: nil))
                }
            }
        } else {
            print("tagReaderSession error: " + error.localizedDescription)
            self.callback?(FlutterError(code: self.unknown, message: "Unknown error: \(error.localizedDescription)", details: error))
        }
        self.session = nil
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        let msgReadingHeader = "読み取り中\n"
        let msgErrorHeader = "エラー\n"
        print("reader session thread: \(Thread.current)")
        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
            print("connect thread: \(Thread.current)")
            if error != nil {
                print(error!)
                self.callback?(FlutterError(code: self.nfcConnectError, message: "Connect error", details: nil))
                session.invalidate(errorMessage: "接続エラー")
                return
            }
            switch self.cardType {
            case .RC:
                self.readRCCard(session, didDetect: tag, msgReadingHeader: msgReadingHeader, msgErrorHeader: msgErrorHeader)
                break
            case .IN:
                self.readINCard(session, didDetect: tag, msgReadingHeader: msgReadingHeader, msgErrorHeader: msgErrorHeader)
                break
            case .DL:
                self.readDLCard(session, didDetect: tag, msgReadingHeader: msgReadingHeader, msgErrorHeader: msgErrorHeader)
            default:
                self.callback?(FlutterError(code: self.invalidCardType, message: "CardType invalid", details: nil))
                break
            }
        }
    }
    
    func readRCCard(_ session: NFCTagReaderSession, didDetect tag: NFCTag, msgReadingHeader: String, msgErrorHeader: String) {
        do {
            session.alertMessage = "読み取り開始、カードを離さないでください"
            let reader = try JeidReader(tag)
            session.alertMessage = "読み取り開始..."
            // detect card type
            let type = try reader.detectCardType()
            if (type != CardType.RC) {
                self.callback?(FlutterError(code: self.invalidCardType, message:"\(msgErrorHeader)It is not a residence card/special permanent resident certificate", details: nil))
                session.invalidate(errorMessage: "\(msgErrorHeader)在留カード/特別永住者証明書ではありません")
                return
            }
            print("thread: \(Thread.current)")
            let ap = try reader.selectRC()
            // verify card number
            do {
                session.alertMessage = "\(msgReadingHeader)SM開始&認証..."
                let rcKey = try RCKey(self.RCCardNumber!)
                try ap.startAC(rcKey)
                session.alertMessage += "成功"
            } catch let jeidError as JeidError {
                switch jeidError {
                case .invalidKey:
                    session.invalidate(errorMessage: "\(msgErrorHeader)認証失敗")
                    self.callback?(FlutterError(code: self.incorrectCardNumber, message: "Incorrect card number", details: jeidError))
                    return
                default:
                    throw jeidError
                }
            }
            // read common data
            session.alertMessage = "\(msgReadingHeader)共通データ要素、カード種別..."
            let files = try ap.readFiles()
            session.alertMessage += "成功"
            var dataDict = Dictionary<String, Any>()
            let commonData = try files.getCommonData()
            dataDict["rc_common"] = commonData.description
            let cardType = try files.getCardType()
            dataDict["rc_card_type_description"] = cardType.description
            if let type = cardType.type {
                dataDict["rc_card_type"] = type
            }
            let cardEntries = try files.getCardEntries()
            let entriesImage = try cardEntries.pngData()
            let src = "\(entriesImage.base64EncodedString())"
            dataDict["rc_front_image"] = src
            let photo = try files.getPhoto()
            if let photoImage = photo.photoData {
                let src = "\(photoImage.base64EncodedString())"
                dataDict["rc_photo"] = src
            }
            // if is residence card
            if cardType.type == "1" {
                let comprehensivePermission = try files.getComprehensivePermission()
                dataDict["comprehensive_permission"] = comprehensivePermission.description
                let individualPermission = try files.getIndividualPermission()
                dataDict["individual_permission"] = individualPermission.description
                let updateStatus = try files.getUpdateStatus()
                dataDict["update_status"] = updateStatus.description
            }
            let signature = try files.getSignature()
            dataDict["rc_signature"] = signature.description
            let address = try files.getAddress()
            dataDict["rc_address"] = address.description
            // authenticity verification
            do {
                session.alertMessage = "真正性検証"
                let result = try files.validate()
                dataDict["rc_valid"] = result.isValid
            } catch JeidError.unsupportedOperation {
                dataDict["rc_valid"] = NSNull()
            } catch {
                print(error)
            }
            session.alertMessage = "読み取り完了"
            session.invalidate()
            self.callback?(dataDict)
        }
        catch {
            self.callback?(FlutterError(code: self.unknown, message: "Unknown error: \(error.localizedDescription)", details: error))
            session.invalidate(errorMessage: session.alertMessage + "失敗")
        }
        
    }
    
    func readINCard(_ session: NFCTagReaderSession, didDetect tag: NFCTag, msgReadingHeader: String, msgErrorHeader: String)  {
        do{
            session.alertMessage = "読み取り開始、カードを離さないでください"
            let reader = try JeidReader(tag)
            session.alertMessage = "読み取り開始..."
            let cardType = try reader.detectCardType()
            if (cardType != CardType.IN) {
                self.callback?(FlutterError(code: self.invalidCardType, message:"\(msgErrorHeader)It is not my number card", details: nil))
                session.invalidate(errorMessage: "\(msgErrorHeader)マイナンバーカードではありません")
                return
            }
            print("thread: \(Thread.current)")
            session.alertMessage = "\(msgReadingHeader)暗証番号による認証..."
            let textAp = try reader.selectINText()
            do {
                try textAp.verifyPin(self.INCardPin!)
            } catch let jeidError as JeidError {
                switch jeidError {
                case .invalidKey:
                    session.invalidate(errorMessage: "\(msgErrorHeader)認証失敗")
                    self.callback?(FlutterError(code: self.incorrectCardPin, message: "Incorrect card pin", details: jeidError))
                    return
                default:
                    throw jeidError
                }
            }
            session.alertMessage = "\(msgReadingHeader)券面入力補助AP内の情報..."
            let textFiles = try textAp.readFiles()
            session.alertMessage += "成功"
            var dataDict = Dictionary<String, Any>()
            do {
                let textMyNumber = try textFiles.getMyNumber()
                if let myNumber = textMyNumber.myNumber {
                    dataDict["in_mynumber"] = myNumber
                }
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INTextFiles#getMyNumber()でJeidError.unsupportedOperationが返ります
                dataDict["in_mynumber"] = NSNull()
            } catch {
                print(error)
            }
            let textAttrs = try textFiles.getAttributes()
            if let name = textAttrs.name {
                dataDict["in_name"] = name
            }
            if let birthDate = textAttrs.birthDate {
                dataDict["in_birth"] = birthDate
            }
            if let sexString = textAttrs.sexString {
                dataDict["in_sex"] = sexString
            }
            if let address = textAttrs.address {
                dataDict["in_address"] = address
            }
            do {
                session.alertMessage = "券面入力補助APの真正性検証"
                let textApValidationResult = try textFiles.validate()
                dataDict["in_validation"] = textApValidationResult.isValid
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INTextFiles#validate()でJeidError.unsupportedOperationが返ります
                dataDict["in_validation"] = NSNull()
            } catch {
                print(error)
            }
            session.alertMessage = "\(msgReadingHeader)暗証番号による認証..."
            let visualAp = try reader.selectINVisual()
            try visualAp.verifyPin(self.INCardPin!)
            session.alertMessage += "成功"
            session.alertMessage = "\(msgReadingHeader)券面AP内の情報..."
            let visualFiles = try visualAp.readFiles()
            session.alertMessage += "成功"
            let visualEntries = try visualFiles.getEntries()
            if let expireDate = visualEntries.expireDate {
                dataDict["in_expire"] = expireDate
            }
            if let birthDate = visualEntries.birthDate {
                dataDict["in_birth2"] = birthDate
            }
            if let sexString = visualEntries.sexString {
                dataDict["in_sex2"] = sexString
            }
            if let nameImage = visualEntries.name {
                let src = "\(nameImage.base64EncodedString())"
                dataDict["in_name_image"] = src
            }
            if let addressImage = visualEntries.address {
                let src = "\(addressImage.base64EncodedString())"
                dataDict["in_address_image"] = src
            }
            if let photoData = visualEntries.photoData {
                let src = "\(photoData.base64EncodedString())"
                dataDict["in_photo"] = src
            }
            
            do {
                session.alertMessage = "券面APの真正性検証"
                let visualApValidationResult = try visualFiles.validate()
                dataDict["in_visualap_validation"] = visualApValidationResult.isValid
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INVisualFiles#validate()でJeidError.unsupportedOperationが返ります
                dataDict["in_visualap_validation"] = NSNull()
            }catch {
                print(error)
            }
            
            do {
                let visualMyNumber = try visualFiles.getMyNumber()
                if let myNumberImage = visualMyNumber.myNumber {
                    let src = "\(myNumberImage.base64EncodedString())"
                    dataDict["in_mynumber_image"] = src
                }
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INVisualFiles#getMyNumber()でJeidError.unsupportedOperationが返ります
                dataDict["in_mynumber_image"] = NSNull()
            }catch {
                print(error)
            }
            session.alertMessage = "読み取り完了"
            session.invalidate()
            self.callback?(dataDict)
        }catch {
            self.callback?(FlutterError(code: self.unknown, message: "Unknown error: \(error.localizedDescription)", details: error))
            session.invalidate(errorMessage: session.alertMessage + "失敗")
        }
    }
    
    func readDLCard(_ session: NFCTagReaderSession, didDetect tag: NFCTag, msgReadingHeader: String, msgErrorHeader: String) {
        do{
            let reader = try JeidReader(tag)
            session.alertMessage = "\(msgReadingHeader)運転免許証の読み取り開始"
            let cardType = try reader.detectCardType()
            if (cardType != CardType.DL) {
                self.callback?(FlutterError(code: self.invalidCardType, message: "Not a driver's license", details: nil) )
                session.invalidate(errorMessage: "\(msgErrorHeader)運転免許証ではありません")
                return
            }
            print("thread: \(Thread.current)")
            let ap = try reader.selectDL()
            // To read common data elements without entering a PIN, use
            // DriverLicenseAP.readCommonData() can be used
            // If you execute DriverLicenseAP.readFiles() without entering PIN1,
            // Read only common data elements and personal identification number (PIN) settings.
            session.alertMessage = "\(msgReadingHeader)暗証番号(PIN)設定"
            let freeFiles = try ap.readFiles()
            let pinSetting = try freeFiles.getPinSetting()
            session.alertMessage += "成功"
            do {
                if !pinSetting.isPinSet {
                    session.alertMessage = "暗証番号(PIN)設定がfalseのため、デフォルトPINの「****」を暗証番号として使用します"
                    self.DLCardPin1 = self.DPIN
                }
                session.alertMessage = "\(msgReadingHeader)暗証番号1による認証..."
                try ap.verifyPin1(self.DLCardPin1!)
                session.alertMessage += "成功"
            } catch let jeidError as JeidError {
                switch jeidError {
                case .invalidPin:
                    self.callback?(FlutterError(code: self.incorrectCardPin, message: "Invalid PIN number 1", details: jeidError))
                    session.invalidate(errorMessage: "\(msgErrorHeader)認証失敗(暗証番号1)")
                    return
                default:
                    throw jeidError
                }
            }
            do {
                if !pinSetting.isPinSet {
                    session.alertMessage = "暗証番号(PIN)設定がfalseのため、デフォルトPINの「****」を暗証番号として使用します"
                    self.DLCardPin2 = self.DPIN
                }
                session.alertMessage = "\(msgReadingHeader)暗証番号2による認証..."
                try ap.verifyPin2(self.DLCardPin2!)
                session.alertMessage += "成功"
            } catch let jeidError as JeidError {
                switch jeidError {
                case .invalidPin:
                    session.invalidate(errorMessage: "\(msgErrorHeader)認証失敗(暗証番号2)")
                    self.callback?(FlutterError(code: self.incorrectCardPin, message: "Invalid PIN number 2", details: jeidError))
                    return
                default:
                    throw jeidError
                }
            }
            session.alertMessage = "\(msgReadingHeader)ファイルの読み出し..."
            // After entering the PIN, run DriverLicenseAP.readFiles()
            // Read all files that can be read with the entered PIN.
            // If only PIN1 is entered, files that require PIN2 entry (such as permanent address) will not be read.
            let files = try ap.readFiles()
            let entries = try files.getEntries()
            var dataDict = Dictionary<String, Any>()
            dataDict["dl_name"] = try self.dlStringToDictArray(entries.name)
            if let kana = entries.kana {
                dataDict["dl_kana"] = kana
            }
            if let birthDate = entries.birthDate {
                dataDict["dl_birth"] = birthDate.stringValue
            }
            dataDict["dl_address"] = try self.dlStringToDictArray(entries.address)
            if let issueDate = entries.issueDate {
                dataDict["dl_issue"] = issueDate.stringValue
            }
            if let refNumber = entries.refNumber {
                dataDict["dl_ref_number"] = refNumber
            }
            if let colorClass = entries.colorClass {
                dataDict["dl_color_class"] = colorClass
            }
            if let expireDate = entries.expireDate {
                dataDict["dl_expire"] = expireDate.stringValue
                let now = Date()
                let date = expireDate.dateValue.addingTimeInterval(60 * 60 * 24)
                dataDict["dl_is_expired"] = Bool(now >= date)
            }
            if let licenseNumber = entries.licenseNumber {
                dataDict["dl_number"] = licenseNumber
            }
            if let pscName = entries.pscName {
                dataDict["dl_sc"]
                = pscName.replacingCharacters(in: pscName.range(of: "公安委員会")!, with: "")
            }
            
            var i: Int = 1
            if let conditions = entries.conditions {
                for condition in conditions {
                    dataDict[String(format: "dl_condition%d", i)] = condition
                    i += 1
                }
            }
            if let categories = entries.categories {
                var categoriesDict: [Dictionary<String, Any>] = []
                for category in categories {
                    var obj = Dictionary<String, Any>()
                    obj["tag"] = category.tag
                    obj["name"] = category.name
                    obj["date"] = category.date.stringValue
                    obj["licensed"] = category.isLicensed
                    categoriesDict.append(obj)
                }
                dataDict["dl_categories"] = categoriesDict
            }
            let changedEntries = try files.getChangedEntries()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            formatter.dateFormat = "yyyyMMdd"
            var changes: [Dictionary<String, Any>] = []
            if (changedEntries.isChanged) {
                for newName in changedEntries.newNameList {
                    var dict = Dictionary<String, Any>()
                    dict["label"] = "新氏名"
                    dict["date"] = newName.date.stringValue
                    dict["ad"] = formatter.string(from: newName.date.dateValue)
                    dict["value"] = try self.dlStringToDictArray(newName.value)
                    dict["psc"] = newName.psc
                    changes.append(dict)
                }
                for newAddress in changedEntries.newAddressList {
                    var dict = Dictionary<String, Any>()
                    dict["label"] = "新住所"
                    dict["date"] = newAddress.date.stringValue
                    dict["ad"] = formatter.string(from: newAddress.date.dateValue)
                    dict["value"] = try self.dlStringToDictArray(newAddress.value)
                    dict["psc"] = newAddress.psc
                    changes.append(dict)
                }
                for newCond in changedEntries.newConditionList {
                    var dict = Dictionary<String, Any>()
                    dict["label"] = "新条件"
                    dict["date"] = newCond.date.stringValue
                    dict["ad"] = formatter.string(from: newCond.date.dateValue)
                    dict["value"] = try self.dlStringToDictArray(newCond.value)
                    dict["psc"] = newCond.psc
                    changes.append(dict)
                }
                for condCancel in changedEntries.conditionCancellationList {
                    var dict = Dictionary<String, Any>()
                    dict["label"] = "条件解除"
                    dict["date"] = condCancel.date.stringValue
                    dict["ad"] = formatter.string(from: condCancel.date.dateValue)
                    dict["value"] = try self.dlStringToDictArray(condCancel.value)
                    dict["psc"] = condCancel.psc
                    changes.append(dict)
                }
            }
            do {
                let registeredDomicile = try files.getRegisteredDomicile()
                dataDict["dl_registered_domicile"] = try self.dlStringToDictArray(registeredDomicile.registeredDomicile)
                
                let photo = try files.getPhoto()
                if let photoData = photo.photoData {
                    let src = "\(photoData.base64EncodedString())"
                    dataDict["dl_photo"] = src
                }
                
                let changedRegDomicile = try files.getChangedRegisteredDomicile()
                var newRegDomiciles: [Dictionary<String, Any>] = []
                if (changedRegDomicile.isChanged) {
                    for newRegDomicile in changedRegDomicile.newRegisteredDomicileList {
                        var dict = Dictionary<String, Any>()
                        dict["label"] = "新本籍"
                        dict["date"] = newRegDomicile.date.stringValue
                        dict["ad"] = formatter.string(from: newRegDomicile.date.dateValue)
                        dict["value"] = try self.dlStringToDictArray(newRegDomicile.value)
                        dict["psc"] = newRegDomicile.psc
                        newRegDomiciles.append(dict)
                    }
                }
                changes += newRegDomiciles
                
                let signature = try files.getSignature()
                session.alertMessage = "\(msgReadingHeader)電子署名"
                if let signatureIssuer = signature.issuer {
                    dataDict["dl_signature_issuer"] = signatureIssuer
                }
                if let signatureSubject = signature.subject {
                    dataDict["dl_signature_subject"] = signatureSubject
                }
                if let signatureSKI = signature.subjectKeyIdentifier {
                    let signatureSkiStr = signatureSKI.map { String(format: "%.2hhx", $0) }.joined(separator: ":")
                    dataDict["dl_signature_ski"] = signatureSkiStr
                }
                
                session.alertMessage = "\(msgReadingHeader)真正性検証"
                do {
                    let result = try files.validate()
                    dataDict["dl_verified"] = result.isValid
                } catch JeidError.unsupportedOperation {
                    //無償版の場合、DLFiles#validate()でJeidError.unsupportedOperationが返ります
                   dataDict["dl_verified"] = NSNull()
                } catch {
                    print("\(error)")
                }
            } catch (JeidError.fileNotFound(message: _)) {
                // PIN2を入力していない場合、filesオブジェクトは
                // JeidError.fileNotFound(message: String)をスローします
            }
            
            dataDict["dl_changes"] = changes
            session.alertMessage = "読み取り完了"
            session.invalidate()
            self.callback?(dataDict)
        }
        catch {
            self.callback?(FlutterError(code: self.unknown, message: "Unknown error: \(error.localizedDescription)", details: error))
            session.invalidate(errorMessage: session.alertMessage + "失敗")
        }
    }
    
    func handleInvalidPinError(_ jeidError: JeidError) {
        let title: String
        let message: String
        guard case .invalidPin(let counter) = jeidError else {
            print("unexpected error: \(jeidError)")
            return
        }
        if (jeidError.isBlocked!) {
            title = "暗証番号がブロックされています"
            message = "市区町村窓口でブロック解除の申請を行ってください。"
        } else {
            title = "暗証番号が間違っています"
            message = "暗証番号を正しく入力してください。\n"
            + "残り\(counter)回間違えるとブロックされます。"
        }
        print(title)
        print(message)
        // TO-DO: Handle title and message
    }
    
    func handleInvalidKeyError(_ jeidError: JeidError) {
        let title = "番号が間違っています"
        let message = "正しい在留カード番号または特別永住者証明書番号を入力してください"
        print(title)
        print(message)
        // TO-DO: Handle title and message
    }
    
    func dlStringToDictArray(_ dlString: DLString) throws -> [Dictionary<String, Any>] {
        guard let jsonData = try dlString.toJSON().data(using: .utf8),
              let jsonObj = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let dictArray = jsonObj as? [Dictionary<String, Any>] else {
            throw JeidError.decodeFailed(message: "failed to decode JSON String: \(try dlString.toJSON())")
        }
        return dictArray
    }
    
}
