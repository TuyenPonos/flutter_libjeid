package ponos.tech.flutter_libjeid;

import android.graphics.Bitmap;
import android.nfc.Tag;
import android.util.Base64;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.TimeZone;

import io.flutter.Log;
import jp.co.osstech.libjeid.CardType;
import jp.co.osstech.libjeid.DriverLicenseAP;
import jp.co.osstech.libjeid.InvalidPinException;
import jp.co.osstech.libjeid.JeidReader;
import jp.co.osstech.libjeid.ValidationResult;
import jp.co.osstech.libjeid.dl.DLDate;
import jp.co.osstech.libjeid.dl.DLPinSetting;
import jp.co.osstech.libjeid.dl.DLString;
import jp.co.osstech.libjeid.dl.DriverLicenseCategory;
import jp.co.osstech.libjeid.dl.DriverLicenseChangedEntries;
import jp.co.osstech.libjeid.dl.DriverLicenseChangedEntry;
import jp.co.osstech.libjeid.dl.DriverLicenseEntries;
import jp.co.osstech.libjeid.dl.DriverLicenseFiles;
import jp.co.osstech.libjeid.dl.DriverLicensePhoto;
import jp.co.osstech.libjeid.dl.DriverLicenseRegisteredDomicile;
import jp.co.osstech.libjeid.dl.DriverLicenseSignature;
import jp.co.osstech.libjeid.util.BitmapARGB;
import jp.co.osstech.libjeid.util.Hex;

public class DLReaderTask implements Runnable {
    private static final String TAG = FlutterLibjeidPlugin.TAG;
    private FlutterLibjeidPlugin flutterPlugin;
    private Tag nfcTag;
    private String cardPin1;
    private String cardPin2;
    private ProgressCallback progressCallback;
    private static final String D_PIN = "****";

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
            progressCallback.onProgress(msgReadingHeader + "暗証番号(PIN)設定");
            DriverLicenseFiles freeFiles = ap.readFiles();
            DLPinSetting pinSetting = freeFiles.getPinSetting();
            progressCallback.onProgress(msgReadingHeader + "暗証番号(PIN)設定" + "成功");
            if (!pinSetting.isPinSet()) {
                progressCallback.onProgress("暗証番号(PIN)設定がfalseのため、デフォルトPINの「****」を暗証番号として使用します");
                this.cardPin1 = D_PIN;
            }
            try {
                progressCallback.onProgress(msgReadingHeader + "暗証番号1による認証...");
                ap.verifyPin1(cardPin1);
                progressCallback.onProgress(msgReadingHeader + "暗証番号1による認証..." + "成功");
            } catch (InvalidPinException e) {
                flutterPlugin.callback.error(flutterPlugin.incorrectCardPin, msgErrorHeader + "Invalid PIN number 1", e);
                return;
            }
            if (!pinSetting.isPinSet()) {
                progressCallback.onProgress("暗証番号(PIN)設定がfalseのため、デフォルトPINの「****」を暗証番号として使用します");
                this.cardPin2 = D_PIN;
            }
            try {
                progressCallback.onProgress(msgReadingHeader + "暗証番号2による認証...");
                ap.verifyPin2(cardPin2);
                progressCallback.onProgress(msgReadingHeader + "暗証番号2による認証..." + "成功");
            } catch (InvalidPinException e) {
                flutterPlugin.callback.error(flutterPlugin.incorrectCardPin, msgErrorHeader + "Invalid PIN number 2", e);
                return;
            }
            // After entering the PIN, execute DriverLicenseAP#readFiles(),
            // Read all files that can be read with the entered PIN.
            // If only PIN1 is entered, files that require PIN2 entry (such as permanent address) will not be read.
            progressCallback.onProgress(msgReadingHeader + "ファイルの読み出し...");
            DriverLicenseFiles files = ap.readFiles();
            // Get ticket information
            DriverLicenseEntries entries = files.getEntries();
            HashMap<String, Object> obj = new HashMap();
            obj.put("dl_name", dlStringToArray(entries.getName()));
            obj.put("dl_kana", entries.getKana());
            DLDate birthDate = entries.getBirthDate();
            if (birthDate != null) {
                obj.put("dl_birth", birthDate.toString());
            }
            obj.put("dl_address", dlStringToArray(entries.getAddr()));
            DLDate issueDate = entries.getIssueDate();
            if (issueDate != null) {
                obj.put("dl_issue", issueDate.toString());
            }
            obj.put("dl_ref_number", entries.getRefNumber());
            obj.put("dl_color_class", entries.getColorClass());
            DLDate expireDate = entries.getExpireDate();
            if (expireDate != null) {
                obj.put("dl_expire", expireDate.toString());
                Calendar expireCal = Calendar.getInstance(TimeZone.getTimeZone("Asia/Tokyo"));
                // If the expiration date is up to the 1st, it will expire on the 2nd day.
                expireCal.setTime(expireDate.toDate());
                expireCal.add(Calendar.DAY_OF_MONTH, 1);
                Date now = new Date();
                boolean isExpired = now.compareTo(expireCal.getTime()) >= 0;
                obj.put("dl_is_expired", isExpired);
            }
            obj.put("dl_number", entries.getLicenseNumber());
            String pscName = entries.getPscName();
            if (pscName != null) {
                obj.put("dl_sc", pscName.replace("公安委員会", ""));
            }
            int i = 1;
            for (String condition : entries.getConditions()) {
                obj.put(String.format(Locale.US, "dl_condition%d", i++), condition);
            }
            ArrayList<HashMap<String, Object>> categories = new ArrayList<>();
            for (DriverLicenseCategory category : entries.getCategories()) {
                HashMap<String, Object> entryObj = new HashMap();
                entryObj.put("tag", category.getTag());
                entryObj.put("name", category.getName());
                entryObj.put("date", category.getDate().toString());
                entryObj.put("licensed", category.isLicensed());
                categories.add(entryObj);
            }
            obj.put("dl_categories", categories);
            // Obtain changes in information (excluding domicile)
            DriverLicenseChangedEntries changedEntries = files.getChangedEntries();
            ArrayList<HashMap<String, Object>> changes = new ArrayList<>();
            SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd", Locale.US);
            sdf.setTimeZone(TimeZone.getTimeZone("Asia/Tokyo"));
            if (changedEntries.isChanged()) {
                for (DriverLicenseChangedEntry entry : changedEntries.getNewAddrList()) {
                    HashMap<String, Object> entryObj = new HashMap();
                    entryObj.put("label", "新住所");
                    entryObj.put("date", entry.getDate().toString());
                    entryObj.put("ad", sdf.format(entry.getDate().toDate()));
                    entryObj.put("value", dlStringToArray(entry.getValue()));
                    entryObj.put("psc", entry.getPsc());
                    changes.add(entryObj);
                }
                for (DriverLicenseChangedEntry entry : changedEntries.getNewNameList()) {
                    HashMap<String, Object> entryObj = new HashMap();
                    entryObj.put("label", "新氏名");
                    entryObj.put("date", entry.getDate().toString());
                    entryObj.put("ad", sdf.format(entry.getDate().toDate()));
                    entryObj.put("value", entry.getValue().toJSON());
                    entryObj.put("psc", entry.getPsc());
                    changes.add(entryObj);
                }
                for (DriverLicenseChangedEntry entry : changedEntries.getNewConditionList()) {
                    HashMap<String, Object> entryObj = new HashMap();
                    entryObj.put("label", "新条件");
                    entryObj.put("date", entry.getDate().toString());
                    entryObj.put("ad", sdf.format(entry.getDate().toDate()));
                    entryObj.put("value", dlStringToArray(entry.getValue()));
                    entryObj.put("psc", entry.getPsc());
                    changes.add(entryObj);
                }
                for (DriverLicenseChangedEntry entry : changedEntries.getConditionCancellationList()) {
                    HashMap<String, Object> entryObj = new HashMap();
                    entryObj.put("label", "条件解除");
                    entryObj.put("date", entry.getDate().toString());
                    entryObj.put("ad", sdf.format(entry.getDate().toDate()));
                    entryObj.put("value", dlStringToArray(entry.getValue()));
                    entryObj.put("psc", entry.getPsc());
                    changes.add(entryObj);
                }
            }
            try {
                //Obtain legal domicile
                DriverLicenseRegisteredDomicile registeredDomicile = files.getRegisteredDomicile();
                DLString value = registeredDomicile.getRegisteredDomicile();
                if (value != null) {
                    obj.put("dl_registered_domicile", dlStringToArray(value));
                }
                // get photo
                progressCallback.onProgress("写真のデコード中...");
                DriverLicensePhoto photo = files.getPhoto();
                BitmapARGB argb = photo.getPhotoBitmapARGB();
                Bitmap bitmap = Bitmap.createBitmap(argb.getData(),
                        argb.getWidth(),
                        argb.getHeight(),
                        Bitmap.Config.ARGB_8888);
                ByteArrayOutputStream os = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, os);
                byte[] jpeg = os.toByteArray();
                String src = Base64.encodeToString(jpeg, Base64.NO_WRAP);
                obj.put("dl_photo", src);
                // Obtain information changes (permanent domicile)
                changedEntries = files.getChangedRegisteredDomicile();
                if (changedEntries.isChanged()) {
                    for (DriverLicenseChangedEntry entry : changedEntries.getNewRegisteredDomicileList()) {
                        HashMap<String, Object> entryObj = new HashMap();
                        entryObj.put("label", "新本籍");
                        entryObj.put("date", entry.getDate().toString());
                        entryObj.put("ad", sdf.format(entry.getDate().toDate()));
                        entryObj.put("value", dlStringToArray(entry.getValue()));
                        entryObj.put("psc", entry.getPsc());
                        changes.add(entryObj);
                    }
                }
                // Get electronic signature
                progressCallback.onProgress(msgReadingHeader + "電子署名");
                DriverLicenseSignature signature = files.getSignature();
                String signatureIssuer = signature.getIssuer();
                obj.put("dl_signature_issuer", signatureIssuer);
                String signatureSubject = signature.getSubject();
                obj.put("dl_signature_subject", signatureSubject);
                String signatureSKI = Hex.encode(signature.getSubjectKeyIdentifier(), ":");
                obj.put("dl_signature_ski", signatureSKI);

                progressCallback.onProgress(msgReadingHeader + "真正性検証");
                ValidationResult result = files.validate();
                obj.put("dl_verified", result.isValid());
            } catch (UnsupportedOperationException e) {
                // PIN2を入力していないfilesオブジェクトは
                // FileNotFoundExceptionをthrowします。
                // free版の場合、真正性検証処理で
                // UnsupportedOperationException が返ります。
                obj.put("dl_verified", null);
            } catch (Exception e) {
                Log.e(TAG, "error", e);
            }

            obj.put("dl_changes", changes);
            progressCallback.onProgress("読み取り完了");
            flutterPlugin.callback.success(obj);
        } catch (Exception e) {
            Log.e(TAG, "error", e);
            flutterPlugin.callback.error(flutterPlugin.unknown, "Unknown error: " + e, e);
        }
    }

    private ArrayList<HashMap<String, Object>> dlStringToArray(DLString value) {
        try {
            JSONArray jsonArray = new JSONArray(value.toJSON());
            ArrayList<HashMap<String, Object>> list = new ArrayList<>();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject obj = jsonArray.getJSONObject(i);
                HashMap<String, Object> map = new HashMap();
                map.put("type", obj.get("type"));
                map.put("value", obj.get("value"));
                list.add(map);
            }
            return list;
        } catch (IOException | JSONException e) {
            return new ArrayList<>();
        }
    }
}
