package ponos.tech.flutter_libjeid

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler


class FlutterLibjeidPluginStreamHandler : StreamHandler {
    private val mainHandler: Handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    fun emit(event: FlutterLibjeidEvent) {
        val runnable = Runnable { eventSink?.success(event.toJSON()) }
        mainHandler.post(runnable)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}