package ponos.tech.flutter_libjeid;

import android.graphics.Bitmap;
import android.nfc.Tag;
import android.util.Base64;

import java.io.ByteArrayOutputStream;
import java.util.HashMap;

import io.flutter.Log;
import io.flutter.plugin.common.EventChannel;
import jp.co.osstech.libjeid.CardType;
import jp.co.osstech.libjeid.InvalidACKeyException;
import jp.co.osstech.libjeid.JeidReader;
import jp.co.osstech.libjeid.RCKey;
import jp.co.osstech.libjeid.ResidenceCardAP;
import jp.co.osstech.libjeid.ValidationResult;
import jp.co.osstech.libjeid.rc.RCAddress;
import jp.co.osstech.libjeid.rc.RCCardEntries;
import jp.co.osstech.libjeid.rc.RCCardType;
import jp.co.osstech.libjeid.rc.RCComprehensivePermission;
import jp.co.osstech.libjeid.rc.RCFiles;
import jp.co.osstech.libjeid.rc.RCIndividualPermission;
import jp.co.osstech.libjeid.rc.RCPhoto;
import jp.co.osstech.libjeid.rc.RCSignature;
import jp.co.osstech.libjeid.rc.RCUpdateStatus;
import jp.co.osstech.libjeid.util.BitmapARGB;

public class RCReaderTask implements Runnable {
    private static final String TAG = FlutterLibjeidPlugin.TAG;
    private FlutterLibjeidPlugin flutterPlugin;
    private Tag nfcTag;
    private String cardNumber;
    private ProgressCallback progressCallback;

    public RCReaderTask(FlutterLibjeidPlugin plugin, Tag nfcTag, String cardNumber, ProgressCallback callback) {
        this.flutterPlugin = plugin;
        this.nfcTag = nfcTag;
        this.cardNumber = cardNumber;
        this.progressCallback = callback;
    }

    @Override
    public void run() {
        String msgReadingHeader = "読み取り中\n";
        String msgErrorHeader = "エラー\n";
        try {
            if (cardNumber == null || cardNumber.isEmpty()) {
                flutterPlugin.callback.error(flutterPlugin.notInputCardNumber, "Please input a valid card number", null);
                return;
            }
            progressCallback.onProgress("読み取り開始、カードを離さないでください");
            JeidReader reader = new JeidReader(nfcTag);
            progressCallback.onProgress(msgReadingHeader + "読み取り開始...");
            CardType type = reader.detectCardType();
            if (type != CardType.RC) {
                flutterPlugin.callback.error(flutterPlugin.invalidCardType, msgErrorHeader + "It is not a residence card/special permanent resident certificate", null);
                return;
            }
            ResidenceCardAP ap = reader.selectResidenceCardAP();
            try {
                progressCallback.onProgress(msgReadingHeader + "SM開始&認証...");
                RCKey rckey = new RCKey(cardNumber);
                ap.startAC(rckey);
                progressCallback.onProgress(msgReadingHeader + "SM開始&認証..." + "成功");
            } catch (InvalidACKeyException e) {
                flutterPlugin.callback.error(flutterPlugin.incorrectCardNumber, "Incorrect card number", null);
                return;
            }
            progressCallback.onProgress(msgReadingHeader + "共通データ要素、カード種別...");
            RCCardType cardType = ap.readCardType();
            RCFiles files = ap.readFiles();
            progressCallback.onProgress(msgReadingHeader + "共通データ要素、カード種別..." + "成功");
            HashMap<String, Object> obj = new HashMap();
            obj.put("rc_card_type", cardType.getType());
            RCCardEntries cardEntries = files.getCardEntries();
            byte[] png = cardEntries.toPng();
            String src = Base64.encodeToString(png, Base64.DEFAULT);
            obj.put("rc_front_image", src);
            RCPhoto photo = files.getPhoto();
            BitmapARGB argb = photo.getPhotoBitmapARGB();
            if (argb != null) {
                Bitmap bitmap = Bitmap.createBitmap(argb.getData(),
                        argb.getWidth(),
                        argb.getHeight(),
                        Bitmap.Config.ARGB_8888);
                ByteArrayOutputStream os = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, os);
                byte[] jpeg = os.toByteArray();
                src = Base64.encodeToString(jpeg, Base64.DEFAULT);
                obj.put("rc_photo", src);
            }
            if ("1".equals(cardType.getType())) {
                RCComprehensivePermission comprehensivePermission = files.getComprehensivePermission();
                obj.put("comprehensive_permission", comprehensivePermission.getPermission());
                RCIndividualPermission individualPermission = files.getIndividualPermission();
                obj.put("individual_permission", individualPermission.getPermission());
                RCUpdateStatus updateStatus = files.getUpdateStatus();
                obj.put("update_status", updateStatus.getStatus());
            }
            RCSignature signature = files.getSignature();
            obj.put("rc_signature", signature.toString());
            RCAddress address = files.getAddress();
            obj.put("rc_address", address.getAddress());

            // authenticity verification
            try {
                progressCallback.onProgress("真正性検証");
                ValidationResult result = files.validate();
                obj.put("rc_valid", result.isValid());
            } catch (UnsupportedOperationException e) {
                // free版の場合、真正性検証処理で
                // UnsupportedOperationException が返ります。
                obj.put("rc_valid", null);
            } catch (Exception e) {
                Log.e(TAG, "error", e);
            }
            progressCallback.onProgress(msgReadingHeader + "読み取り完了");
            flutterPlugin.callback.success(obj);
        } catch (Exception e) {
            Log.e(TAG, "error", e);
            flutterPlugin.callback.error(flutterPlugin.unknown, "Unknown error", e);
        }
    }
}
