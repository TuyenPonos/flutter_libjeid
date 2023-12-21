package ponos.tech.flutter_libjeid

import jp.co.osstech.libjeid.InvalidACKeyException
import jp.co.osstech.libjeid.InvalidBACKeyException
import jp.co.osstech.libjeid.InvalidPinException
import kotlin.Exception

open class FlutterLibjeidException(
        val code: String,
        override val message: String,
        val details: Map<String, String?>? = null
): Exception() {
    companion object {
        fun fromException(e: Exception): FlutterLibjeidException {
            if (e is FlutterLibjeidException) {
                return e
            }

            if (e is InvalidPinException) {
                if (e.isBlocked) {
                    return NfcCardBlockedException()
                }

                return FlutterLibjeidException(
                        code = "InvalidPin",
                        message = "Invalid PIN code, remaining time(s): ${e.counter}",
                        details = mapOf("remainingTimes" to "${e.counter}")
                )
            }

            if (e is InvalidBACKeyException) {
                return FlutterLibjeidException(
                        code = "InvalidKey",
                        message = e.message ?: "Invalid BAC key"
                )
            }

            if (e is InvalidACKeyException) {
                return FlutterLibjeidException(
                        code = "InvalidKey",
                        message = e.message ?: "Invalid AC key"
                )
            }

            return UnknownException(code = e.message, message = e.message)
        }
    }

    fun toJSON(): Map<String, Any?> {
        return mapOf(
            "code" to code,
            "message" to message,
            "details" to details
        )
    }
}

class NfcNotAvailableException: FlutterLibjeidException(
        code = "NfcNotAvailable",
        message = "NFC is not available on this device"
)

class NfcTagUnableToConnectException(
        details: Map<String, String?>? = null
): FlutterLibjeidException(
        code = "NfcTagUnableToConnect",
        message = "Cannot connect to NFC tag",
        details
)

class NfcCardBlockedException(
        details: Map<String, String?>? = null
): FlutterLibjeidException(
        code = "NfcCardBlocked",
        message = "The card is blocked",
        details
)

class NfcCardTypeMismatchException(
        details: Map<String, String?>? = null
): FlutterLibjeidException(
        code = "NfcCardTypeMismatch",
        message = "The card type does not match",
        details
)

class InvalidMethodArgumentsException(
        details: Map<String, String?>? = null
): FlutterLibjeidException(
        code = "InvalidMethodArguments",
        message = "Invalid method channel arguments",
        details
)

class UnknownException(
        details: Map<String, String?>? = null
): FlutterLibjeidException(
        code = "Unknown",
        message = "Unknown error",
        details
) {
    constructor(code: String? = null, message: String? = null): this(mapOf(
            "code" to code,
            "message" to message
    ))
}
