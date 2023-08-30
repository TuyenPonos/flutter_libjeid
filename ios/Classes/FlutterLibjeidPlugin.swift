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
    
    var session: NFCTagReaderSession?
    var callback: FlutterResult?
    private var RCCardNumber: String?
    private var INCardPin: String?
    private var cardType: CardType?
    
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
                if(cardPin.isEmpty){
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
        case "stopScan":
            self.cardType = nil
            self.INCardPin = nil
            self.RCCardNumber = nil
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
            self.callback?(FlutterError(code: self.unknown, message: "Unknow error: \(error.localizedDescription)", details: error))
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
            default:
                self.callback?(FlutterError(code: self.invalidCardType, message: "CardType invalid", details: nil))
                break
            }
        }
    }
 
    func readRCCard(_ session: NFCTagReaderSession, didDetect tag: NFCTag, msgReadingHeader: String, msgErrorHeader: String) {
        do {
            if (self.RCCardNumber == nil || self.RCCardNumber!.isEmpty) {
                self.callback?(FlutterError(code: self.notInputCardNumber, message: "Please input a valid card number", details: nil))
                session.invalidate(errorMessage: "\(msgErrorHeader)在留カード等の番号が入力されていません")
                return
            }
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
            self.callback?(FlutterError(code: self.unknown, message: "Unknow error", details: nil))
            session.invalidate(errorMessage: session.alertMessage + "失敗")
        }
        
    }
    
    func readINCard(_ session: NFCTagReaderSession, didDetect tag: NFCTag, msgReadingHeader: String, msgErrorHeader: String)  {
        do{
            if (self.INCardPin == nil || self.INCardPin!.isEmpty || self.INCardPin!.count != 4) {
                self.callback?(FlutterError(code: self.notInputCardPin, message: "Please input a valid card pin", details: nil))
                session.invalidate(errorMessage: "\(msgErrorHeader)暗証番号が入力されていません")
                return
            }
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
                    dataDict["card_mynumber"] = myNumber
                }
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INTextFiles#getMyNumber()でJeidError.unsupportedOperationが返ります
                dataDict["card_mynumber"] = NSNull()
            } catch {
                print(error)
            }
            let textAttrs = try textFiles.getAttributes()
            if let name = textAttrs.name {
                dataDict["card_name"] = name
            }
            if let birthDate = textAttrs.birthDate {
                dataDict["card_birth"] = birthDate
            }
            if let sexString = textAttrs.sexString {
                dataDict["card_sex"] = sexString
            }
            if let address = textAttrs.address {
                dataDict["card_address"] = address
            }
            do {
                session.alertMessage = "券面入力補助APの真正性検証"
                let textApValidationResult = try textFiles.validate()
                dataDict["validation_result"] = textApValidationResult.isValid
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INTextFiles#validate()でJeidError.unsupportedOperationが返ります
                dataDict["validation_result"] = NSNull()
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
                dataDict["card_expire"] = expireDate
            }
            if let birthDate = visualEntries.birthDate {
                dataDict["card_birth2"] = birthDate
            }
            if let sexString = visualEntries.sexString {
                dataDict["card_sex2"] = sexString
            }
            if let nameImage = visualEntries.name {
                let src = "\(nameImage.base64EncodedString())"
                dataDict["card_name_image"] = src
            }
            if let addressImage = visualEntries.address {
                let src = "\(addressImage.base64EncodedString())"
                dataDict["card_address_image"] = src
            }
            if let photoData = visualEntries.photoData {
                let src = "\(photoData.base64EncodedString())"
                dataDict["card_photo"] = src
            }
            
            do {
                session.alertMessage = "券面APの真正性検証"
                let visualApValidationResult = try visualFiles.validate()
                dataDict["visualap_validation_result"] = visualApValidationResult.isValid
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INVisualFiles#validate()でJeidError.unsupportedOperationが返ります
                dataDict["visualap_validation_result"] = NSNull()
            }catch {
                print(error)
            }
            
            do {
                let visualMyNumber = try visualFiles.getMyNumber()
                if let myNumberImage = visualMyNumber.myNumber {
                    let src = "\(myNumberImage.base64EncodedString())"
                    dataDict["card_mynumber_image"] = src
                }
            } catch JeidError.unsupportedOperation {
                // 無償版の場合、INVisualFiles#getMyNumber()でJeidError.unsupportedOperationが返ります
                dataDict["card_mynumber_image"] = NSNull()
            }catch {
                print(error)
            }
            session.alertMessage = "読み取り完了"
            session.invalidate()
            self.callback?(dataDict)
        }catch {
            self.callback?(FlutterError(code: self.unknown, message: "Unknow error", details: nil))
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
}
