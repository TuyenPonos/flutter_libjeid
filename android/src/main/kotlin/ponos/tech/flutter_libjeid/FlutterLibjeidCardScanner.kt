package ponos.tech.flutter_libjeid

import android.app.Activity
import android.app.AlertDialog
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.NfcAdapter.ReaderCallback
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.nfc.tech.NfcB
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Button
import android.widget.TextView
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.PluginRegistry

interface FlutterLibjeidCardScannerHander {
    fun onScanStarted()

    fun onTagParsingStarted(tag: Tag)

    fun onScanError(error: Exception)

    fun onScanSuccess(data: HashMap<String, Any?>)

    fun onScanCancelled()
}

abstract class FlutterLibjeidCardScanner(protected val activity: Activity) : ReaderCallback, PluginRegistry.NewIntentListener {
    companion object {
        fun getCompatibleScanner(activity: Activity): FlutterLibjeidCardScanner {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                return FlutterLibjeidCardScannerReader(activity)
            }

            return FlutterLibjeidCardScannerForegroundDispatch(activity)
        }
    }

    protected val nfcAdapter: NfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    private var parser: FlutterLibjeidCardParser? = null
    private var handler: FlutterLibjeidCardScannerHander? = null
    private val uiThreadHandler = Handler(Looper.getMainLooper())
    private fun createDialog(): AlertDialog {
        val builder = AlertDialog.Builder(activity, R.style.Dialog_No_Border)
        val view = activity.layoutInflater.inflate(R.layout.progress_dialog, null)
        builder.setView(view)
        builder.setOnCancelListener{ stopScanning() }
        builder.setCancelable(false)
        val dialog = builder.create()
        val cancelButton = view.findViewById<Button>(R.id.cancel_button)
        cancelButton.setOnClickListener {
            dialog.cancel()
        }
        return dialog;
    }

    private var nfcScannerDialog: AlertDialog? = null

    fun isAvailable(): Boolean = nfcAdapter.isEnabled

    protected abstract fun startNfcScanningSession()

    protected abstract fun stopNfcScanningSession()

    fun startScanning(parser: FlutterLibjeidCardParser, handler: FlutterLibjeidCardScannerHander) {
        if (nfcScannerDialog?.isShowing == true) {
            nfcScannerDialog?.dismiss()
        }
        nfcScannerDialog = createDialog()
        nfcScannerDialog!!.show()

        this.parser = parser
        this.handler = handler
        this.handler?.onScanStarted()

        startNfcScanningSession()
    }

    fun setMessage(message: String) {
        if (nfcScannerDialog?.isShowing != true) return

        val messageView = nfcScannerDialog!!.findViewById<TextView>(R.id.progress_message)
        uiThreadHandler.post { messageView.text = message }
    }

    fun stopScanning(errorMessage: String? = null) {
        if (errorMessage != null) {
            setMessage(errorMessage)
        } else if (nfcScannerDialog?.isShowing == true) {
            nfcScannerDialog!!.dismiss()
            nfcScannerDialog = null
        }

        stopNfcScanningSession()

        this.parser = null
        this.handler?.onScanCancelled()
        this.handler = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
        onTagDiscovered(tag)
        return false
    }

    override fun onTagDiscovered(tag: Tag?) {
        if (tag == null) {
            handler?.onScanError(NfcTagUnableToConnectException())
            return
        }

        if (parser == null) {
            handler?.onScanError(UnknownException("Parser is null"))
            return
        }

        this.handler?.onTagParsingStarted(tag)

        try {
            val result = parser!!.read(tag)
            handler?.onScanSuccess(result)
        } catch (e: Exception) {
            handler?.onScanError(e)
        }
    }
}

@RequiresApi(Build.VERSION_CODES.O)
class FlutterLibjeidCardScannerReader(activity: Activity) : FlutterLibjeidCardScanner(activity) {
    override fun startNfcScanningSession() {
        val options = Bundle()
        nfcAdapter.enableReaderMode(activity, this, NfcAdapter.FLAG_READER_NFC_B or NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK, options)
    }

    override fun stopNfcScanningSession() {
        nfcAdapter.disableReaderMode(activity)
    }
}

class FlutterLibjeidCardScannerForegroundDispatch(activity: Activity) : FlutterLibjeidCardScanner(activity) {
    override fun startNfcScanningSession() {
        val intent = Intent(activity, this.javaClass)
        intent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(activity, 0, intent, 0)
        val techLists = arrayOf(arrayOf(NfcB::class.java.name), arrayOf(IsoDep::class.java.name))

        nfcAdapter.enableForegroundDispatch(activity, pendingIntent, null, techLists)
    }

    override fun stopNfcScanningSession() {
        nfcAdapter.disableForegroundDispatch(activity)
    }
}
