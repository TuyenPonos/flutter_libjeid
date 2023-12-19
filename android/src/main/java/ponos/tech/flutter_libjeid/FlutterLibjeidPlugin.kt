package ponos.tech.flutter_libjeid

import android.app.Activity
import android.app.AlertDialog
import android.app.PendingIntent
import android.content.Context
import android.content.DialogInterface
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.nfc.tech.NfcB
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.Button
import android.widget.TextView
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import jp.co.osstech.libjeid.CardType
import ponos.tech.flutter_libjeid.FlutterLibjeidCardScanner.Companion.isAvailable
import java.util.concurrent.Executors

class FlutterLibjeidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, NewIntentListener {
    protected val notInputCardNumber = "not_input_card_number"
    protected val notInputCardPin = "not_input_card_pin"
    protected val nfcConnectError = "nfc_connect_error"
    val incorrectCardNumber = "incorrect_card_number"
    val incorrectCardPin = "incorrect_card_pin"
    val invalidCardType = "invalid_card_type"
    val unknown = "unknown"
    var callback: MethodChannel.Result? = null
    private var channel: MethodChannel? = null
    protected var nfcAdapter: NfcAdapter? = null
    protected var activity: Activity? = null
    protected var context: Context? = null

    // NFC read mode
    private val NFC_READER_MODE = 1
    private val NFC_FD_MODE = 2
    protected var nfcMode = 0

    // Disable NFC reading in viewer and menu screen
    // Also, while displaying the dialog with a PIN mistake
    // flag to prevent continuous reads from happening
    private var cardType: CardType? = null
    protected var cardNumber: String? = null
    protected var cardPin: String? = null
    protected var cardPin1: String? = null
    protected var cardPin2: String? = null
    var alertDialog: AlertDialog? = null
    private val uiThreadHandler = Handler(Looper.getMainLooper())
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_libjeid")
        channel!!.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        nfcAdapter = NfcAdapter.getDefaultAdapter(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0 or higher uses ReaderMode
            nfcMode = NFC_READER_MODE
        } else {
            // Use ForegroundDispatch for Android less than 8.0
            nfcMode = NFC_FD_MODE
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        callback = result
        if (activity == null) {
            result.error(unknown, "Cannot call method when not attached to activity", null)
            return
        }
        if (isAvailable(context!!)) if (nfcAdapter == null || !nfcAdapter!!.isEnabled) {
            result.error(nfcConnectError, "NFC is unavailable", null)
            return
        }
        val nameHash: HashMap<String?, Any?> = HashMap<Any?, Any?>()
        when (call.method) {
            "scanRCCard" -> {
                val cardNumber = call.argument<String>("card_number")
                if (cardNumber == null || cardNumber.isEmpty()) {
                    result.error(notInputCardNumber, "Please input a valid card number", null)
                    return
                }
                cardType = CardType.RC
                this.cardNumber = cardNumber
                startScan()
            }

            "scanINCard" -> {
                val cardPin = call.argument<String>("pin")
                if (cardPin == null || cardPin.length != 4) {
                    result.error(notInputCardPin, "Please input a valid card pin", null)
                    return
                }
                cardType = CardType.IN
                this.cardPin = cardPin
                startScan()
            }

            "scanDLCard" -> {
                val cardPin1 = call.argument<String>("pin_1")
                if (cardPin1 == null || cardPin1.length != 4) {
                    result.error(notInputCardPin, "Please input a valid card pin 1", null)
                    return
                }
                val cardPin2 = call.argument<String>("pin_2")
                if (cardPin2 == null || cardPin2.length != 4) {
                    result.error(notInputCardPin, "Please input a valid card pin 2", null)
                    return
                }
                cardType = CardType.DL
                this.cardPin1 = cardPin1
                this.cardPin2 = cardPin2
                startScan()
            }

            "stopScan" -> {
                stopScan()
                cardNumber = null
                cardPin = null
                cardType = null
            }

            else -> {
                cardType = null
                result.notImplemented()
            }
        }
    }

    private fun startScan() {
        if (nfcAdapter == null) {
            callback!!.error(nfcConnectError, "NFC is unavailable", null)
            return
        }
        logProgressMessage("カードに端末をかざしてください")
        if (nfcMode == NFC_READER_MODE) {
            val options = Bundle()
            nfcAdapter!!.enableReaderMode(activity, { tag: Tag? -> onTagDiscovered(tag) },
                    NfcAdapter.FLAG_READER_NFC_B or NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK,
                    options)
        } else {
            val intent = Intent(context, this.javaClass)
            intent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, 0)
            val techLists = arrayOf(arrayOf(NfcB::class.java.name), arrayOf(IsoDep::class.java.name))
            nfcAdapter!!.enableForegroundDispatch(activity, pendingIntent, null, techLists)
        }
    }

    private fun stopScan() {
        if (alertDialog != null && alertDialog!!.isShowing) {
            alertDialog!!.hide()
        }
        if (nfcAdapter == null) {
            return
        }
        if (nfcMode == NFC_READER_MODE) {
            nfcAdapter!!.disableReaderMode(activity)
        } else {
            nfcAdapter!!.disableForegroundDispatch(activity)
        }
    }

    fun onTagDiscovered(tag: Tag?) {
        Log.d(TAG, javaClass.simpleName + ": Tag Discovered - " + tag.toString())
        if (cardType == null) {
            callback!!.error(invalidCardType, "Card type not found", null)
            return
        }
        when (cardType) {
            CardType.RC -> {
                val rcTask = RCReaderTask(this@FlutterLibjeidPlugin, tag, cardNumber) { message: String? -> logProgressMessage(message) }
                val rxExec = Executors.newSingleThreadExecutor()
                rxExec.submit(rcTask)
            }

            CardType.IN -> {
                val inTask = INReaderTask(this@FlutterLibjeidPlugin, tag, cardPin) { message: String? -> logProgressMessage(message) }
                val inExec = Executors.newSingleThreadExecutor()
                inExec.submit(inTask)
            }

            CardType.DL -> {
                val dlTask = DLReaderTask(this@FlutterLibjeidPlugin, tag, cardPin1, cardPin2) { message: String? -> logProgressMessage(message) }
                val dlExec = Executors.newSingleThreadExecutor()
                dlExec.submit(dlTask)
            }

            else -> {}
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        val view = activity!!
                .layoutInflater
                .inflate(R.layout.progress_dialog, null)
        alertDialog = AlertDialog.Builder(activity, AlertDialog.THEME_DEVICE_DEFAULT_LIGHT)
                .setCancelable(false)
                .setOnCancelListener { dialog: DialogInterface? -> stopScan() }
                .setView(view)
                .create()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // no op
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        // no op
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
        onTagDiscovered(tag)
        return false
    }

    fun logProgressMessage(message: String?) {
        Log.i(TAG, message!!)
        if (alertDialog != null && !alertDialog!!.isShowing) {
            alertDialog!!.show()
            val cancelButton = alertDialog!!.findViewById<View>(R.id.cancel_button) as Button
            cancelButton.setOnClickListener { v: View? -> callback!!.success(HashMap<Any?, Any?>()) }
        }
        if (alertDialog != null && alertDialog!!.isShowing) {
            val tv_message = alertDialog!!.findViewById<TextView>(R.id.progress_message)
            uiThreadHandler.post { tv_message.text = message }
        }
    }

    companion object {
        const val TAG = "FlutterLibjeidPlugin"
    }
}
