package ponos.tech.flutter_libjeid;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.tech.IsoDep;
import android.nfc.tech.NfcB;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;
import jp.co.osstech.libjeid.CardType;

public class FlutterLibjeidPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
    protected final String notInputCardNumber = "not_input_card_number";
    protected final String notInputCardPin = "not_input_card_pin";
    protected final String nfcConnectError = "nfc_connect_error";
    protected final String incorrectCardNumber = "incorrect_card_number";
    protected final String incorrectCardPin = "incorrect_card_pin";
    protected final String invalidCardType = "invalid_card_type";
    protected final String unknown = "unknown";

    protected MethodChannel.Result callback;
    private MethodChannel channel;

    public static final String TAG = "FlutterLibjeidPlugin";
    protected NfcAdapter nfcAdapter;
    protected Activity activity;
    protected Context context;

    // NFC read mode
    private final int NFC_READER_MODE = 1;
    private final int NFC_FD_MODE = 2;
    protected int nfcMode;

    // Disable NFC reading in viewer and menu screen
    // Also, while displaying the dialog with a PIN mistake
    // flag to prevent continuous reads from happening
    private CardType cardType;
    protected String cardNumber;
    protected String cardPin;
    protected String cardPin1;
    protected String cardPin2;

    AlertDialog alertDialog;
    private final Handler uiThreadHandler = new Handler(Looper.getMainLooper());

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_libjeid");
        channel.setMethodCallHandler(this);
        this.context = flutterPluginBinding.getApplicationContext();
        nfcAdapter = NfcAdapter.getDefaultAdapter(this.context);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0 or higher uses ReaderMode
            this.nfcMode = NFC_READER_MODE;
        } else {
            // Use ForegroundDispatch for Android less than 8.0
            this.nfcMode = NFC_FD_MODE;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        this.callback = result;
        if (activity == null) {
            result.error(unknown, "Cannot call method when not attached to activity", null);
            return;
        }
        if (nfcAdapter == null || !nfcAdapter.isEnabled()) {
            result.error(nfcConnectError, "NFC is unavailable", null);
            return;
        }
        HashMap<String, Object> nameHash = new HashMap();
        switch (call.method) {
            case "scanRCCard":
                String cardNumber = call.argument("card_number");
                if (cardNumber == null || cardNumber.isEmpty()) {
                    result.error(notInputCardNumber, "Please input a valid card number", null);
                    return;
                }
                this.cardType = CardType.RC;
                this.cardNumber = cardNumber;
                startScan();
                break;
            case "scanINCard":
                String cardPin = call.argument("pin");
                if (cardPin == null || cardPin.length() != 4) {
                    result.error(notInputCardPin, "Please input a valid card pin", null);
                    return;
                }
                this.cardType = CardType.IN;
                this.cardPin = cardPin;
                startScan();
                break;
            case "scanDLCard":
                String cardPin1 = call.argument("pin_1");
                if (cardPin1 == null || cardPin1.length() != 4) {
                    result.error(notInputCardPin, "Please input a valid card pin 1", null);
                    return;
                }
                String cardPin2 = call.argument("pin_2");
                if (cardPin2 == null || cardPin2.length() != 4) {
                    result.error(notInputCardPin, "Please input a valid card pin 2", null);
                    return;
                }
                this.cardType = CardType.DL;
                this.cardPin1 = cardPin1;
                this.cardPin2 = cardPin2;
                startScan();
                break;
            case "stopScan":
                stopScan();
                this.cardNumber = null;
                this.cardPin = null;
                this.cardType = null;
                break;
            default:
                this.cardType = null;
                result.notImplemented();
        }
    }

    private void startScan() {
        if (nfcAdapter == null) {
            this.callback.error(nfcConnectError, "NFC is unavailable", null);
            return;
        }
        logProgressMessage("カードに端末をかざしてください");
        if (this.nfcMode == NFC_READER_MODE) {
            Bundle options = new Bundle();
            nfcAdapter.enableReaderMode(activity,
                    FlutterLibjeidPlugin.this::onTagDiscovered,
                    NfcAdapter.FLAG_READER_NFC_B | NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK,
                    options);
        } else {
            Intent intent = new Intent(context, this.getClass());
            intent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
            PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent, 0);
            String[][] techLists = new String[][]{
                    new String[]{NfcB.class.getName()},
                    new String[]{IsoDep.class.getName()}
            };
            nfcAdapter.enableForegroundDispatch(activity, pendingIntent, null, techLists);
        }
    }

    private void stopScan() {
        if (alertDialog != null && alertDialog.isShowing()) {
            alertDialog.hide();
        }
        if (nfcAdapter == null) {
            return;
        }
        if (nfcMode == NFC_READER_MODE) {
            nfcAdapter.disableReaderMode(activity);
        } else {
            nfcAdapter.disableForegroundDispatch(activity);
        }
    }

    public void onTagDiscovered(Tag tag) {
        Log.d(TAG, getClass().getSimpleName() + ": Tag Discovered - " + tag.toString());
        if (this.cardType == null) {
            this.callback.error(invalidCardType, "Card type not found", null);
            return;
        }
        switch (this.cardType) {
            case RC:
                RCReaderTask rcTask = new RCReaderTask(FlutterLibjeidPlugin.this, tag, this.cardNumber, FlutterLibjeidPlugin.this::logProgressMessage);
                ExecutorService rxExec = Executors.newSingleThreadExecutor();
                rxExec.submit(rcTask);
                break;
            case IN:
                INReaderTask inTask = new INReaderTask(FlutterLibjeidPlugin.this, tag, this.cardPin, FlutterLibjeidPlugin.this::logProgressMessage);
                ExecutorService inExec = Executors.newSingleThreadExecutor();
                inExec.submit(inTask);
                break;
            case DL:
                DLReaderTask dlTask = new DLReaderTask(FlutterLibjeidPlugin.this, tag, this.cardPin1, this.cardPin2, FlutterLibjeidPlugin.this::logProgressMessage);
                ExecutorService dlExec = Executors.newSingleThreadExecutor();
                dlExec.submit(dlTask);
                break;
            default:
                break;
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        View view = this.activity
                .getLayoutInflater()
                .inflate(R.layout.progress_dialog, null);
        alertDialog = new AlertDialog.Builder(this.activity, AlertDialog.THEME_DEVICE_DEFAULT_LIGHT)
                .setCancelable(false)
                .setOnCancelListener(dialog -> stopScan())
                .setView(view)
                .create();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // no op
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        // no op
    }

    @Override
    public boolean onNewIntent(@NonNull Intent intent) {
        Tag tag = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG);
        this.onTagDiscovered(tag);
        return false;
    }

    public void logProgressMessage(String message) {
        Log.i(TAG, message);
        if (alertDialog != null && !alertDialog.isShowing()) {
            alertDialog.show();
            Button cancelButton = (Button) alertDialog.findViewById(R.id.cancel_button);
            cancelButton.setOnClickListener(v -> {
                FlutterLibjeidPlugin.this.callback.success(new HashMap());
            });
        }
        if (alertDialog != null && alertDialog.isShowing()) {
            TextView tv_message = alertDialog.findViewById(R.id.progress_message);
            uiThreadHandler.post(() -> tv_message.setText(message));
        }
    }
}
