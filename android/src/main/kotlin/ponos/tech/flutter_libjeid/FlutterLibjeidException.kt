package ponos.tech.flutter_libjeid

import jp.co.osstech.libjeid.InvalidACKeyException
import jp.co.osstech.libjeid.InvalidBACKeyException
import jp.co.osstech.libjeid.InvalidPinException

open class FlutterLibjeidException(val code: String, val details: HashMap<String, String?>? = null) : Exception() {
    companion object {
        fun fromException(e: Exception): FlutterLibjeidException {
            if (e is FlutterLibjeidException) {
                return e
            }

            if (e is InvalidPinException) {
                if (e.isBlocked) {
                    return NfcCardBlockedException()
                }

                return InvalidCardPinException(
                        counter = e.counter
                )
            }

            if (e is InvalidBACKeyException) {
                return InvalidCardKeyException(
                        message = e.message ?: "Invalid BAC key"
                )
            }

            if (e is InvalidACKeyException) {
                return InvalidCardKeyException(
                        message = e.message ?: "Invalid AC key"
                )
            }

            return UnknownException(code = e.message, message = e.message)
        }
    }

    fun toJSON(): HashMap<String, Any?> {
        return hashMapOf(
                "code" to code,
                "message" to message,
                "details" to details
        )
    }
}

class NfcNotAvailableException : FlutterLibjeidException(
        code = "NfcNotAvailable",
)

class NfcTagUnableToConnectException(details: HashMap<String, String?>? = null) : FlutterLibjeidException(
        code = "NfcTagUnableToConnect",
        details
)

class NfcCardBlockedException(details: HashMap<String, String?>? = null) : FlutterLibjeidException(
        code = "NfcCardBlocked",
        details
)

class NfcCardTypeMismatchException(details: HashMap<String, String?>? = null) : FlutterLibjeidException(
        code = "NfcCardTypeMismatch",
        details
)

class InvalidMethodArgumentsException(details: HashMap<String, String?>? = null) : FlutterLibjeidException(
        code = "InvalidMethodArguments",
        details
)

class InvalidCardPinException(counter: Int) : FlutterLibjeidException(
        code = "InvalidPin",
        details = hashMapOf("remainingTimes" to "$counter")
)

class InvalidCardKeyException(message: String) : FlutterLibjeidException(
        code = "InvalidKey",
        details = hashMapOf("message" to message)
)

class UnknownException(details: HashMap<String, String?>? = null) : FlutterLibjeidException(
        code = "Unknown",
        details
) {
    constructor(code: String? = null, message: String? = null) : this(hashMapOf(
            "code" to code,
            "message" to message
    ))
}
