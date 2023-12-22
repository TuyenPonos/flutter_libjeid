package ponos.tech.flutter_libjeid

import android.nfc.Tag
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


class FlutterLibjeidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, FlutterLibjeidCardScannerHander {
    companion object {
        const val TAG = "FlutterLibjeidPlugin"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var streamHandler: FlutterLibjeidPluginStreamHandler
    private var cardScanner: FlutterLibjeidCardScanner? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_libjeid")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_libjeid_card_data_event")
        streamHandler = FlutterLibjeidPluginStreamHandler()
        eventChannel.setStreamHandler(streamHandler)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        cardScanner?.stopScanning()
        cardScanner = FlutterLibjeidCardScanner.getCompatibleScanner(binding.activity)
    }

    override fun onDetachedFromActivity() {
        cardScanner = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        streamHandler.onCancel(null)
        cardScanner?.stopScanning()
        cardScanner = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                result.success(cardScanner?.isAvailable() ?: false)
            }

            "stopScan" -> {
                cardScanner?.stopScanning()
            }

            "setMessage" -> {
                val message = call.argument<String>("message")

                if (message == null) {
                    result.exception(InvalidMethodArgumentsException())
                    return
                }

                cardScanner?.setMessage(message)
            }

            else -> {
                if (cardScanner == null || cardScanner?.isAvailable() == false) {
                    result.exception(NfcNotAvailableException())
                    return
                }

                // Stop the previous scanning session (if any)
                cardScanner!!.stopScanning()

                val parser = try {
                    FlutterLibjeidCardParserFactory.createParserFromFlutterMethod(call)
                } catch (e: Exception) {
                    result.exception(FlutterLibjeidException.fromException(e))
                    return
                }

                if (parser == null) {
                    result.notImplemented()
                    return
                }

                cardScanner!!.startScanning(parser, this)
            }
        }
    }

    override fun onScanStarted() {
        streamHandler.emit(FlutterLibjeidEvent.Scanning)
    }

    override fun onTagParsingStarted(tag: Tag) {
        streamHandler.emit(FlutterLibjeidEvent.Parsing)
    }

    override fun onScanError(error: Exception) {
        streamHandler.emit(FlutterLibjeidEvent.Failed(FlutterLibjeidException.fromException(error).toJSON()))
    }

    override fun onScanSuccess(data: HashMap<String, Any?>) {
        streamHandler.emit(FlutterLibjeidEvent.Success(data))
    }

    override fun onScanCancelled() {
        streamHandler.emit(FlutterLibjeidEvent.Cancelled)
    }
}

fun MethodChannel.Result.exception(exception: FlutterLibjeidException) {
    error(exception.code, exception.message, exception.details)
}
