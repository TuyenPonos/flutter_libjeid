package ponos.tech.flutter_libjeid

sealed interface FlutterLibjeidEvent {
    data object Scanning : FlutterLibjeidEvent
    data object Connecting : FlutterLibjeidEvent
    data object Parsing : FlutterLibjeidEvent
    data class Success(val data: HashMap<String, Any?>) : FlutterLibjeidEvent
    data class Failed(val error: HashMap<String, Any?>?) : FlutterLibjeidEvent
    data object Cancelled : FlutterLibjeidEvent

    fun toJSON(): Map<String, Any?> {
        return when (this) {
            is Scanning -> mapOf("event" to "scanning")
            is Connecting -> mapOf("event" to "connecting")
            is Parsing -> mapOf("event" to "parsing")
            is Success -> mapOf("event" to "success", "data" to data)
            is Failed -> mapOf("event" to "failed", "data" to error)
            is Cancelled -> mapOf("event" to "cancelled")
        }
    }
}
