package ponos.tech.flutter_libjeid

import android.graphics.Bitmap
import android.nfc.Tag
import android.util.Base64
import jp.co.osstech.libjeid.CardType
import jp.co.osstech.libjeid.DriverLicenseAP
import jp.co.osstech.libjeid.EPMRZ
import jp.co.osstech.libjeid.INTextAP
import jp.co.osstech.libjeid.INVisualAP
import jp.co.osstech.libjeid.JeidReader
import jp.co.osstech.libjeid.PassportAP
import jp.co.osstech.libjeid.RCKey
import jp.co.osstech.libjeid.ResidenceCardAP
import jp.co.osstech.libjeid.dl.DLDate
import jp.co.osstech.libjeid.dl.DriverLicenseChangedEntry
import jp.co.osstech.libjeid.util.BitmapARGB
import jp.co.osstech.libjeid.util.Hex
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone


abstract class FlutterLibjeidCardParser {
    abstract fun read(tag: Tag): HashMap<String, Any?>
}

class LibjeidDriverLicenseCardParser(
        private val pin1: String?,
        private val pin2: String?,
) : FlutterLibjeidCardParser() {
    private fun authenticate(ap: DriverLicenseAP) {
        val files = ap.readFiles()
        val pinSetting = files.pinSetting

        var pin1 = this.pin1
        var pin2 = this.pin2

        if (!pinSetting.isPinSet) {
            pin1 = "****"
            pin2 = "****"
        }

        if (pin1 == null || pin2 == null) {
            throw InvalidMethodArgumentsException()
        }

        ap.verifyPin1(pin1)
        ap.verifyPin2(pin2)
    }

    override fun read(tag: Tag): HashMap<String, Any?> {
        val reader = JeidReader(tag)
        val type = reader.detectCardType()

        if (type != CardType.DL) {
            throw NfcCardTypeMismatchException()
        }

        val ap = reader.selectDriverLicenseAP()

        this.authenticate(ap)

        val files = ap.readFiles()

        val commonData = files.commonData
        val entries = files.entries
        val changedEntries = files.changedEntries
        val photo = files.photo
        val registeredDomicile = files.registeredDomicile
        val signature = files.signature

        val photoSrc = photo.photoBitmapARGB.toBase64PngImage()
        val verifyStatus = files.validate()

        return hashMapOf(
                "card_type" to "driver_license",
                "name" to entries.name.toJSON(),
                "kana" to entries.kana,
                "alias_name" to entries.aliasName.toJSON(),
                "call_name" to entries.callName,
                "birth_date" to entries.birthDate?.toISOString(),
                "address" to entries.addr.toJSON(),
                "issue_date" to commonData.issueDate.toISOString(),
                "ref_number" to entries.refNumber,
                "color_class" to entries.colorClass,
                "expire_date" to commonData.expireDate.toISOString(),
                "license_number" to entries.licenseNumber,
                "psc_name" to entries.pscName,
                "registered_domicile" to registeredDomicile.registeredDomicile.toJSON(),
                "photo" to photoSrc,
                "signature_issuer" to signature.issuer,
                "signature_subject" to signature.subject,
                "signature_ski" to Hex.encode(signature.subjectKeyIdentifier, ":"),
                "verified" to verifyStatus.isValid,
                "categories" to entries.categories.map { cat ->
                    hashMapOf(
                            "tag" to cat.tag,
                            "name" to cat.name,
                            "date" to cat.date.toISOString(),
                            "is_licensed" to cat.isLicensed
                    )
                },
                "name_history_records" to changedEntries.newNameList.map { entry -> entry.toHashMap() },
                "address_history_records" to changedEntries.newAddrList.map { entry -> entry.toHashMap() },
                "condition_history_records" to changedEntries.newConditionList.map { entry -> entry.toHashMap() },
                "condition_cancellation_history_records" to changedEntries.conditionCancellationList.map { entry -> entry.toHashMap() },
                "registered_domicile_history_records" to changedEntries.newRegisteredDomicileList.map { entry -> entry.toHashMap() }
        )
    }
}

class LibjeidMyNumberCardParser(
        private val pin: String,
) : FlutterLibjeidCardParser() {
    private fun authenticate(textAp: INTextAP, visualAp: INVisualAP) {
        textAp.verifyPin(pin)
        visualAp.verifyPin(pin)
    }

    override fun read(tag: Tag): HashMap<String, Any?> {
        val reader = JeidReader(tag)
        val type = reader.detectCardType()

        if (type != CardType.IN) {
            throw NfcCardTypeMismatchException()
        }

        val textAp = reader.selectINTextAP()
        val visualAp = reader.selectINVisualAP()

        this.authenticate(textAp = textAp, visualAp = visualAp)

        val files = textAp.readFiles()

        val myNumberData = files.myNumber
        val attributes = files.attributes

        val visualFiles = visualAp.readFiles()
        val visualEntries = visualFiles.entries

        val expire = visualEntries.expire
        val photoSrc = visualEntries.photoBitmapARGB?.toBase64PngImage()
        val nameImageSrc = visualEntries.name.toBase64PngImage()
        val addressImageSrc = visualEntries.addr.toBase64PngImage()
        val myNumberImageSrc = visualFiles.myNumber.myNumber.toBase64PngImage()
        val verified = visualFiles.validate().isValid

        return hashMapOf(
                "card_type" to "my_number",
                "my_number" to myNumberData.myNumber,
                "name" to attributes.name,
                "address" to attributes.addr,
                "birth_date" to attributes.birth,
                "sex" to attributes.sex,
                "expire_date" to expire,
                "photo" to photoSrc,
                "nameImage" to nameImageSrc,
                "addressImage" to addressImageSrc,
                "myNumberImage" to myNumberImageSrc,
                "verified" to verified
        )
    }
}

class LibjeidResidentCardParser(
        private val cardNumber: String,
) : FlutterLibjeidCardParser() {
    private fun authenticate(ap: ResidenceCardAP) {
        val cardKey = RCKey(cardNumber)
        ap.startAC(cardKey)
    }

    override fun read(tag: Tag): HashMap<String, Any?> {
        val reader = JeidReader(tag)
        val type = reader.detectCardType()

        if (type != CardType.RC) {
            throw NfcCardTypeMismatchException()
        }

        val ap = reader.selectResidenceCardAP()

        this.authenticate(ap)

        val files = ap.readFiles()

        val cardType = files.cardType
        val address = files.address
        val photo = files.photo
        val cardEntries = files.cardEntries

        val photoSrc = photo.photoBitmapARGB.toBase64PngImage()
        val cardFrontPhotoSrc = cardEntries.bitmapARGB.toBase64PngImage()

        var updateStatus: String? = null
        var individualPermission: String? = null
        var comprehensivePermission: String? = null

        if (cardType.type.equals("1")) {
            updateStatus = files.updateStatus.status
            individualPermission = files.individualPermission.permission
            comprehensivePermission = files.comprehensivePermission.permission
        }

        return hashMapOf(
                "card_type" to "resident_card",
                "type" to cardType.type,
                "photo" to photoSrc,
                "address" to address.address,
                "address_code" to address.code,
                "address_updated_at" to address.date,
                "card_front_photo" to cardFrontPhotoSrc,
                "update_status" to updateStatus,
                "individual_permission" to individualPermission,
                "comprehensive_permission" to comprehensivePermission
        )
    }
}

class LibjeidPassportCardParser(
        private val cardNumber: String,
        private val birthDate: String,
        private val expiredDate: String,
) : FlutterLibjeidCardParser() {
    private fun authenticate(ap: PassportAP) {
        val epKey = EPMRZ(cardNumber, birthDate, expiredDate)
        ap.startBAC(epKey)
    }

    override fun read(tag: Tag): HashMap<String, Any?> {
        val reader = JeidReader(tag)
        val type = reader.detectCardType()

        if (type != CardType.EP) {
            throw NfcCardTypeMismatchException()
        }

        val ap = reader.selectPassportAP()

        this.authenticate(ap)

        val files = ap.readFiles()
        val commonData = files.commonData
        val dataGroup1 = files.dataGroup1
        val dataGroup2 = files.dataGroup2

        val dataGroup1Mrz = EPMRZ(dataGroup1.mrz)

        val photoSrc = dataGroup2.faceJpeg.toBase64PngImage()
        val passiveAuthenticationResult = files.validate().isValid
        val activeAuthenticationResult = ap.activeAuthentication(files)

        return hashMapOf(
                "card_type" to "passport",
                "fid" to commonData.fid,
                "sfid" to commonData.shortFID,
                "lds_version" to commonData.ldsVersion,
                "unicode_version" to commonData.unicodeVersion,
                "tags" to commonData.tagList,
                "document_code" to dataGroup1Mrz.documentCode,
                "issuing_country" to dataGroup1Mrz.issuingCountry,
                "name" to dataGroup1Mrz.name,
                "surname" to dataGroup1Mrz.surname,
                "given_name" to dataGroup1Mrz.givenName,
                "passport_number" to dataGroup1Mrz.passportNumber,
                "passport_number_check_digit" to dataGroup1Mrz.passportNumberCheckDigit,
                "nationality" to dataGroup1Mrz.nationality,
                "birth_date" to dataGroup1Mrz.birthDate,
                "birth_date_check_digit" to dataGroup1Mrz.birthDateCheckDigit,
                "sex" to dataGroup1Mrz.sex,
                "expiration_date" to dataGroup1Mrz.expirationDate,
                "expiration_date_check_digit" to dataGroup1Mrz.expirationDateCheckDigit,
                "optiona_data" to dataGroup1Mrz.optionalData,
                "optional_data_check_digit" to dataGroup1Mrz.optionalDataCheckDigit,
                "composite_check_digit" to dataGroup1Mrz.compositeCheckDigit,
                "photo" to photoSrc,
                "passive_authentication_result" to passiveAuthenticationResult,
                "active_authentication_result" to activeAuthenticationResult
        )
    }
}

fun ByteArray.toBase64PngImage(): String {
    val base64 = Base64.encodeToString(this, Base64.DEFAULT)
    return "data:image/jpeg;base64,$base64"
}

fun BitmapARGB.toBase64PngImage(): String {
    val bitmap = Bitmap.createBitmap(this.data, this.width, this.height, Bitmap.Config.ARGB_8888)
    val os = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, os)

    return os.toByteArray().toBase64PngImage()
}

fun Date.toISOString(): String {
    val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    formatter.timeZone = TimeZone.getTimeZone("GMT")
    return formatter.format(this)
}

fun DLDate.toISOString(): String {
    return toDate().toISOString()
}

fun DriverLicenseChangedEntry.toHashMap(): HashMap<String, Any?> {
    return hashMapOf(
            "date" to date.toISOString(),
            "value" to value.toString(),
            "psc" to psc
    )
}