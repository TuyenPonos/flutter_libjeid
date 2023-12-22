package ponos.tech.flutter_libjeid

import io.flutter.plugin.common.MethodCall

abstract class FlutterLibjeidCardParserFactory {
    companion object {
        fun createParserFromFlutterMethod(call: MethodCall): FlutterLibjeidCardParser? {
            when (call.method) {
                "scanPassportCard" -> {
                    val cardNumber = call.argument<String>("card_number")
                    val birthDate = call.argument<String>("birth_date")
                    val expiredDate = call.argument<String>("expired_date")

                    if (cardNumber == null || birthDate == null || expiredDate == null) {
                        throw InvalidMethodArgumentsException()
                    }

                    return LibjeidPassportCardParser(cardNumber, birthDate, expiredDate)
                }

                "scanResidentCard" -> {
                    val cardNumber = call.argument<String>("card_number")

                    if (cardNumber == null) {
                        throw InvalidMethodArgumentsException()
                    }

                    return LibjeidResidentCardParser(cardNumber)
                }

                "scanMyNumberCard" -> {
                    val pin = call.argument<String>("pin")

                    if (pin == null) {
                        throw InvalidMethodArgumentsException()
                    }

                    return LibjeidMyNumberCardParser(pin)
                }

                "scanDriverLicenseCard" -> {
                    val pin1 = call.argument<String>("pin1")
                    val pin2 = call.argument<String>("pin2")

                    if (pin1 == null || pin2 == null) {
                        throw InvalidMethodArgumentsException()
                    }

                    return LibjeidDriverLicenseCardParser(pin1, pin2)
                }
            }

            return null
        }
    }
}