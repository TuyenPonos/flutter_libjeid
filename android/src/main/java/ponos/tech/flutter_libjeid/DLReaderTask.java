package ponos.tech.flutter_libjeid;

import android.nfc.Tag;

import io.flutter.Log;
import jp.co.osstech.libjeid.CardType;
import jp.co.osstech.libjeid.DriverLicenseAP;
import jp.co.osstech.libjeid.InvalidPinException;
import jp.co.osstech.libjeid.JeidReader;
import jp.co.osstech.libjeid.dl.DLPinSetting;
import jp.co.osstech.libjeid.dl.DriverLicenseCommonData;
import jp.co.osstech.libjeid.dl.DriverLicenseEntries;
import jp.co.osstech.libjeid.dl.DriverLicenseExternalCharactors;
import jp.co.osstech.libjeid.dl.DriverLicenseFiles;

public class DLReaderTask implements Runnable {
    private static final String TAG = FlutterLibjeidPlugin.TAG;
    private FlutterLibjeidPlugin flutterPlugin;
    private Tag nfcTag;
    private String cardPin1;
    private String cardPin2;
    private ProgressCallback progressCallback;
    private static final String DPIN = "****";

    public DLReaderTask(FlutterLibjeidPlugin plugin, Tag nfcTag, String cardPin1, String cardPin2, ProgressCallback callback) {
        this.flutterPlugin = plugin;
        this.nfcTag = nfcTag;
        this.cardPin1 = cardPin1;
        this.cardPin2 = cardPin2;
        this.progressCallback = callback;
    }

    @Override
    public void run() {
        String msgReadingHeader = "読み取り中\n";
        String msgErrorHeader = "エラー\n";
        try {
            if (cardPin1 == null || cardPin1.length() != 4 || cardPin2 == null || cardPin2.length() != 4) {
                flutterPlugin.callback.error(flutterPlugin.notInputCardPin, "Please input a valid card pins", null);
                return;
            }
            progressCallback.onProgress("読み取り開始、カードを離さないでください");
            JeidReader reader = new JeidReader(this.nfcTag);
            progressCallback.onProgress(msgReadingHeader + "運転免許証の読み取り開始");
            CardType type = reader.detectCardType();
            if (type != CardType.DL) {
                flutterPlugin.callback.error(flutterPlugin.invalidCardType, msgErrorHeader + "It is not driver license card", null);
                return;
            }
            // To read common data elements without entering a PIN, use
            // DriverLicenseAP#getCommonData() can be used.
            // If you execute DriverLicenseAP#readFiles() without entering PIN1,
            // Read only common data elements and personal identification number (PIN) settings.
            DriverLicenseAP ap = reader.selectDriverLicenseAP();
            progressCallback.onProgress(msgReadingHeader + "共通データ要素");
            DriverLicenseFiles freeFiles = ap.readFiles();
            DriverLicenseCommonData commonData = freeFiles.getCommonData();
            DLPinSetting pinSetting = freeFiles.getPinSetting();
            progressCallback.onProgress(msgReadingHeader + "暗証番号(PIN)設定");
            if (!pinSetting.isPinSet()) {
                progressCallback.onProgress("暗証番号(PIN)設定がfalseのため、デフォルトPINの「****」を暗証番号として使用します");
                this.cardPin1 = DPIN;
            }
            try {
                ap.verifyPin1(cardPin1);
            } catch (InvalidPinException e) {
                flutterPlugin.callback.error(flutterPlugin.incorrectCardPin, msgErrorHeader + "Invalid PIN number 1", e);
                return;
            }
            if (!pinSetting.isPinSet()) {
                this.cardPin2 = DPIN;
            }
            try {
                ap.verifyPin2(cardPin2);
            } catch (InvalidPinException e) {
                flutterPlugin.callback.error(flutterPlugin.incorrectCardPin, msgErrorHeader + "Invalid PIN number 2", e);
                return;
            }
            // After entering the PIN, execute DriverLicenseAP#readFiles(),
            // Read all files that can be read with the entered PIN.
            // If only PIN1 is entered, files that require PIN2 entry (such as permanent address) will not be read.
            DriverLicenseFiles files = ap.readFiles();
            // Get ticket information
            DriverLicenseEntries entries = files.getEntries();
            DriverLicenseExternalCharactors extChars = files.getExternalCharactors();

        } catch (Exception e) {
            Log.e(TAG, "error", e);
            flutterPlugin.callback.error(flutterPlugin.unknown, "Unknown error: " + e, e);
        }
    }
}
