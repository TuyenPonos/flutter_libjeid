package ponos.tech.flutter_libjeid;

import android.graphics.Bitmap;
import android.nfc.Tag;
import android.util.Base64;

import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.util.HashMap;

import io.flutter.Log;
import jp.co.osstech.libjeid.CardType;
import jp.co.osstech.libjeid.INTextAP;
import jp.co.osstech.libjeid.INVisualAP;
import jp.co.osstech.libjeid.InvalidPinException;
import jp.co.osstech.libjeid.JeidReader;
import jp.co.osstech.libjeid.ValidationResult;
import jp.co.osstech.libjeid.in.INTextAttributes;
import jp.co.osstech.libjeid.in.INTextFiles;
import jp.co.osstech.libjeid.in.INTextMyNumber;
import jp.co.osstech.libjeid.in.INVisualEntries;
import jp.co.osstech.libjeid.in.INVisualFiles;
import jp.co.osstech.libjeid.in.INVisualMyNumber;
import jp.co.osstech.libjeid.util.BitmapARGB;

public class INReaderTask implements Runnable {
    private static final String TAG = FlutterLibjeidPlugin.TAG;
    private FlutterLibjeidPlugin flutterPlugin;
    private Tag nfcTag;
    private String cardPin;
    private ProgressCallback progressCallback;

    public INReaderTask(FlutterLibjeidPlugin plugin, Tag nfcTag, String cardPin, ProgressCallback callback) {
        this.flutterPlugin = plugin;
        this.nfcTag = nfcTag;
        this.cardPin = cardPin;
        this.progressCallback = callback;
    }

    @Override
    public void run() {
        String msgReadingHeader = "読み取り中\n";
        String msgErrorHeader = "エラー\n";
        try {
            progressCallback.onProgress("読み取り開始、カードを離さないでください");
            JeidReader reader = new JeidReader(nfcTag);
            progressCallback.onProgress(msgReadingHeader + "読み取り開始...");
            CardType type = reader.detectCardType();
            if (type != CardType.IN) {
                flutterPlugin.callback.error(flutterPlugin.invalidCardType, msgErrorHeader + "It is not my number card", null);
                return;
            }
            progressCallback.onProgress(msgReadingHeader + "暗証番号による認証...");
            INTextAP textAp = reader.selectINTextAP();
            try {
                textAp.verifyPin(cardPin);
                progressCallback.onProgress("暗証番号による認証..." + "成功");
            } catch (InvalidPinException e) {
                flutterPlugin.callback.error(flutterPlugin.incorrectCardPin, "Incorrect card pin", e);
                return;
            }
            progressCallback.onProgress(msgReadingHeader + "券面入力補助AP内の情報...");
            INTextFiles textFiles = textAp.readFiles();
            progressCallback.onProgress("券面入力補助AP内の情報..." + "成功");
            HashMap<String, Object> obj = new HashMap();
            try {
                INTextMyNumber textMyNumber = textFiles.getMyNumber();
                obj.put("in_mynumber", textMyNumber.getMyNumber());
            } catch (FileNotFoundException | UnsupportedOperationException ue) {
                // 無償版では個人番号を取得出来ません。
                obj.put("in_mynumber", null);
            } catch (Exception e) {
                Log.e(TAG, "error", e);
            }
            INTextAttributes textAttrs = textFiles.getAttributes();
            obj.put("in_name", textAttrs.getName());
            obj.put("in_birth", textAttrs.getBirth());
            obj.put("in_sex", textAttrs.getSexString());
            obj.put("in_address", textAttrs.getAddr());

            try {
                progressCallback.onProgress("券面入力補助APの真正性検証");
                ValidationResult validationResult = textFiles.validate();
                obj.put("in_validation", validationResult.isValid());
            } catch (UnsupportedOperationException ue) {
                // 無償版では真正性検証をサポートしていません。
                obj.put("in_validation", null);
            } catch (Exception e) {
                Log.e(TAG, "error", e);
            }
            progressCallback.onProgress(msgReadingHeader + "暗証番号による認証...");
            INVisualAP visualAp = reader.selectINVisualAP();
            visualAp.verifyPin(cardPin);
            progressCallback.onProgress(msgReadingHeader + "券面AP内の情報...");
            INVisualFiles visualFiles = visualAp.readFiles();
            progressCallback.onProgress(msgReadingHeader + "券面AP内の情報..." + "成功");
            INVisualEntries visualEntries = visualFiles.getEntries();
            String expire = visualEntries.getExpire();
            obj.put("in_expire", expire);
            obj.put("in_birth2", visualEntries.getBirth());
            obj.put("in_sex2", visualEntries.getSexString());
            obj.put("in_name_image",
                    Base64.encodeToString(visualEntries.getName(), Base64.NO_WRAP));
            obj.put("in_address_image", Base64.encodeToString(visualEntries.getAddr(), Base64.NO_WRAP));
            BitmapARGB argb = visualEntries.getPhotoBitmapARGB();
            Bitmap bitmap = Bitmap.createBitmap(argb.getData(),
                    argb.getWidth(),
                    argb.getHeight(),
                    Bitmap.Config.ARGB_8888);
            ByteArrayOutputStream os = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, os);
            byte[] jpeg = os.toByteArray();
            String src = Base64.encodeToString(jpeg, Base64.NO_WRAP);
            obj.put("in_photo", src);
            try {
                progressCallback.onProgress("券面APの真正性検証");
                ValidationResult validationResult = visualFiles.validate();
                obj.put("in_visualap_validation", validationResult.isValid());
            } catch (UnsupportedOperationException ue) {
                // 無償版では真正性検証をサポートしていません。
                obj.put("in_visualap_validation", null);
            }catch (Exception e) {
                Log.e(TAG, "error", e);
            }

            try {
                INVisualMyNumber visualMyNumber = visualFiles.getMyNumber();
                obj.put("in_mynumber_image", Base64.encodeToString(visualMyNumber.getMyNumber(), Base64.NO_WRAP));
            } catch (FileNotFoundException | UnsupportedOperationException ue) {
                // 無償版では個人番号(画像)を取得できません。
                obj.put("in_mynumber_image", null);
            }catch (Exception e){
                Log.e(TAG, "error", e);
            }

            progressCallback.onProgress("読み取り完了");
            flutterPlugin.callback.success(obj);
        } catch (Exception e) {
            Log.e(TAG, "error", e);
            flutterPlugin.callback.error(flutterPlugin.unknown, "Unknown error: " + e, e);
        }
    }
}
