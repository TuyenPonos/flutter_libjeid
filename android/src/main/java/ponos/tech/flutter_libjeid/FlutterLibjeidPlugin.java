package ponos.tech.flutter_libjeid;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.tech.IsoDep;
import android.nfc.tech.NfcB;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;
import jp.co.osstech.libjeid.CardType;

public class FlutterLibjeidPlugin implements FlutterPlugin, MethodCallHandler, TagDiscoveredListener, ActivityAware, PluginRegistry.NewIntentListener, EventChannel.StreamHandler {
    protected final String notInputCardNumber = "not_input_card_number";
    protected final String notInputCardPin = "not_input_card_pin";
    protected final String nfcConnectError = "nfc_connect_error";
    protected final String incorrectCardNumber = "incorrect_card_number";
    protected final String incorrectCardPin = "incorrect_card_pin";
    protected final String invalidCardType = "invalid_card_type";
    protected final String unknown = "unknown";

    protected MethodChannel.Result callback;
    private MethodChannel channel;
    private EventChannel.EventSink progressSink;
    private EventChannel progressChannel;

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
    protected boolean enableNFC = false;
    private CardType cardType;
    protected String cardNumber;
    protected String cardPin;


    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_libjeid");
        channel.setMethodCallHandler(this);
        progressChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_libjeid_progress_stream");
        progressChannel.setStreamHandler(this);
        this.context = flutterPluginBinding.getApplicationContext();
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
        switch (call.method) {
            case "scanRCCard":
                String cardNumber = call.argument("card_number");
                if (cardNumber == null || cardNumber.isEmpty()) {
                    result.error(notInputCardNumber, "Please input a valid card number", null);
                    return;
                }
                this.cardType = CardType.RC;
                this.enableNFC = true;
                startScan();
                break;
            case "scanINCard":
                String cardPin = call.argument("pin");
                if (cardPin == null || cardPin.length() != 4) {
                    result.error(notInputCardPin, "Please input a valid card pin", null);
                    return;
                }
                this.cardType = CardType.IN;
                this.enableNFC = true;
                startScan();
                break;
            case "stopScan":
                stopScan();
                this.cardNumber = null;
                this.cardPin = null;
                this.cardType = null;
                this.enableNFC = false;
                break;
            default:
                this.cardType = null;
                result.notImplemented();
        }
    }

    private void startScan() {
        nfcAdapter = NfcAdapter.getDefaultAdapter(context);
        if (nfcAdapter == null) {
            this.callback.error(nfcConnectError, "NFC Adapter not found", null);
            return;
        }
        if (this.nfcMode == NFC_READER_MODE) {
            Log.d(TAG, "NFC mode: ReaderMode " + this.enableNFC);
            if (!this.enableNFC) {
                // Disable NFC reading in menu screens and viewers
                // If you don't do this, reading in normal mode (OS standard) will be enabled
                nfcAdapter.enableReaderMode(activity, null, NfcAdapter.STATE_OFF, null);
                return;
            }
            Bundle options = new Bundle();
            nfcAdapter.enableReaderMode(activity,
                    new NfcAdapter.ReaderCallback() {
                        @Override
                        public void onTagDiscovered(Tag tag) {
                            onTagDiscovered(tag);
                        }
                    },
                    NfcAdapter.FLAG_READER_NFC_B | NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK,
                    options);
        } else {
            Log.d(TAG, "NFC mode: ForegroundDispatch " + this.enableNFC);
            if (!this.enableNFC) {
                return;
            }
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
        if (nfcAdapter == null) {
            return;
        }
        if (nfcMode == NFC_READER_MODE) {
            nfcAdapter.disableReaderMode(activity);
        } else {
            nfcAdapter.disableForegroundDispatch(activity);
        }
    }

    @Override
    public void onTagDiscovered(Tag tag) {
        Log.d(TAG, getClass().getSimpleName() + ": Tag Discovered");
        if (!this.enableNFC) {
            Log.d(TAG, getClass().getSimpleName() + ": NFC disabled.");
            this.callback.error(nfcConnectError, "NFC disabled", null);
            return;
        }
        if (tag == null) {
            Log.d(TAG, getClass().getSimpleName() + ": NFC Adapter not found");
            this.callback.error(nfcConnectError, "NFC Adapter not found", null);
            return;
        }
        if (this.cardType == null) {
            this.callback.error(invalidCardType, "Card type not found", null);
            return;
        }
        switch (this.cardType) {
            case RC:
                RCReaderTask rcTask = new RCReaderTask(this, tag);
                ExecutorService rxExec = Executors.newSingleThreadExecutor();
                rxExec.submit(rcTask);
                break;
            case IN:
                INReaderTask inTask = new INReaderTask(this, tag);
                ExecutorService inExec = Executors.newSingleThreadExecutor();
                inExec.submit(inTask);
                break;
            default:
                break;
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {

    }

    @Override
    public boolean onNewIntent(@NonNull Intent intent) {
        Tag tag = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG);
        this.onTagDiscovered(tag);
        return false;
    }

    public void logProgressMessage(String message) {
        this.progressSink.success(message);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.progressSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.progressSink = null;
    }
}
