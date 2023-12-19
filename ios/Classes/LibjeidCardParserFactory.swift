import Foundation
import libjeid
import Flutter

@available(iOS 13.0, *)
class LibjeidCardParserFactory {
    static func make(fromFlutterMethod call: FlutterMethodCall) throws -> (any LibjeidCardParser)? {
        guard let args = call.arguments as? Dictionary<String, Any?>? else {
            throw InvalidMethodArgumentsError()
        }

        switch (call.method) {
        case "scanEPCard":
            guard let cardNumber = args?["card_number"] as? String,
                  let birthDate = args?["birth_date"] as? String,
                  let expiredDate = args?["expired_date"] as? String else {
                throw InvalidMethodArgumentsError()
            }
            return LibjeidPassportCardParser(cardNumber: cardNumber, birthDate: birthDate, expiredDate: expiredDate)

        case "scanRCCard":
            guard let cardNumber = args?["card_number"] as? String else {
                throw InvalidMethodArgumentsError()
            }
            return LibjeidResidentCardParser(cardNumber: cardNumber)

        case "scanINCard":
            guard let pin = args?["pin"] as? String else {
                throw InvalidMethodArgumentsError()
            }
            return LibjeidMyNumberCardParser(pin: pin)

        case "scanDLCard":
            guard let pin1 = args?["pin_1"] as? String?,
                  let pin2 = args?["pin_2"] as? String? else {
                throw InvalidMethodArgumentsError()
            }
            return LibjeidDriverLicenseCardParser(pin1: pin1, pin2: pin2)

        default:
            return nil
        }
    }
}
