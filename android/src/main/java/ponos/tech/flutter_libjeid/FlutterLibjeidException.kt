package ponos.tech.flutter_libjeid

import java.lang.Exception

abstract class FlutterLibjeidError(
        val code: String,
        override val message: String,
        val details: Any? = null
): Exception()

class NfcNotAvailableError: FlutterLibjeidError(
        code = "NfcNotAvailable",
        message = "NFC is not available on this device"
)

class NfcTagUnabvaloConnectError(details: Any? = null): FlutterLibjeidError(
        code = "NfcTagUnabvaloConnect",
        message = "Cannot connect to NFC tag",
        details
)

class InvalidMethodArgumentsError(details: Any? = null): FlutterLibjeidError(
        code = "InvalidMethodArguments",
        message = "Invalid method channel arguments",
        details
)

class CardTypeMismatchError: FlutterLibjeidError(
        code = "CardTypeMismatch",
        message = "The scanned card type is not match with the selected card"
)

class NfcCardBlockedError: FlutterLibjeidError(
        code = "NfcCardBlocked",
        message = "The NFC card is blocked"
)

class InvalidDriverLicensePinError(details: Any? = null): FlutterLibjeidError(
        code = "InvalidDriverLicensePin",
        message = "The PIN code(s) of the Driver License card is incorrect",
        details
)

class InvalidMyNumberPinError(details: Any? = null): FlutterLibjeidError(
        code = "InvalidMyNumberPin",
        message = "The PIN code(s) of the My Number card is incorrect",
        details
)

class InvalidResidentCardNumberError(details: Any? = null): FlutterLibjeidError(
        code = "InvalidResidentCardNumberError",
        message = "The number of the Resident card is incorrect",
        details
)

class InvalidPassportInformationError(details: Any? = null): FlutterLibjeidError(
        code = "InvalidPassportInformation",
        message = "The Passport card information provided does not match",
        details
)

class UnknownError(details: Any? = null): FlutterLibjeidError(
        code = "Unknown",
        message = "Unknown error",
        details
)



