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


abstract class FlutterLibjeidCardParser<T: CardData> {
    abstract fun read(tag: Tag): T
}

class LibjeidDriverLicenseCardParser(
        private val pin1: String?,
        private val pin2: String?,
): FlutterLibjeidCardParser<DriverLicenseCardData>() {
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

    override fun read(tag: Tag): DriverLicenseCardData {
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

        return DriverLicenseCardData(
            name = entries.name.toString(),
            kana = entries.kana,
            aliasName = entries.aliasName.toString(),
            callName = entries.callName,
            birthDate = entries.birthDate?.toISOString(),
            address = entries.addr.toString(),
            issueDate = commonData.issueDate.toISOString(),
            refNumber = entries.refNumber,
            colorClass = entries.colorClass,
            expireDate = commonData.expireDate.toISOString(),
            licenseNumber = entries.licenseNumber,
            pscName = entries.pscName,
            registeredDomicile = registeredDomicile.registeredDomicile.toString(),
            photo = photoSrc,
            signatureIssuer = signature.issuer,
            signatureSubject = signature.subject,
            signatureSKI = Hex.encode(signature.subjectKeyIdentifier, ":"),
            verified = verifyStatus.isValid,
            categories = entries.categories.map { cat ->
                DriverLicenseCardData.Category(
                        tag = cat.tag,
                        name = cat.name,
                        date = cat.date.toISOString(),
                        isLicensed = cat.isLicensed
                )
            },
            nameHistoryRecords = changedEntries.newNameList.map { entry -> entry.toChangeHistory() },
            addressHistoryRecords = changedEntries.newAddrList.map { entry -> entry.toChangeHistory() },
            conditionHistoryRecords = changedEntries.newConditionList.map { entry -> entry.toChangeHistory() },
            conditionCancellationHistoryRecords = changedEntries.conditionCancellationList.map { entry -> entry.toChangeHistory() },
            registeredDomicileHistoryRecords = changedEntries.newRegisteredDomicileList.map { entry -> entry.toChangeHistory() }
        )
    }
}

class LibjeidMyNumberCardParser(
        private val pin: String,
): FlutterLibjeidCardParser<MyNumberCardData>() {
    private fun authenticate(textAp: INTextAP, visualAp: INVisualAP) {
        textAp.verifyPin(pin)
        visualAp.verifyPin(pin)
    }

    override fun read(tag: Tag): MyNumberCardData {
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

        return MyNumberCardData(
            myNumber = myNumberData.myNumber,
            name = attributes.name,
            address = attributes.addr,
            birthDate = attributes.birth,
            sex = attributes.sex,
            expireDate = expire,
            photo = photoSrc,
            nameImage = nameImageSrc,
            addressImage = addressImageSrc,
            myNumberImage = myNumberImageSrc,
            verified = verified
        )
    }
}

class LibjeidResidentCardParser(
        private val cardNumber: String,
): FlutterLibjeidCardParser<ResidentCardData>() {
    private fun authenticate(ap: ResidenceCardAP) {
        val cardKey = RCKey(cardNumber)
        ap.startAC(cardKey)
    }

    override fun read(tag: Tag): ResidentCardData {
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

        return ResidentCardData(
            cardType = cardType.type,
            photo = photoSrc,
            address = address.address,
            addressCode = address.code,
            addressUpdatedAt = address.date,
            cardFrontPhoto = cardFrontPhotoSrc,
            updateStatus = updateStatus,
            individualPermission = individualPermission,
            comprehensivePermission = comprehensivePermission
        )
    }
}

class LibjeidPassportCardParser(
        private val cardNumber: String,
        private val birthDate: String,
        private val expiredDate: String,
): FlutterLibjeidCardParser<PassportCardData>() {
    private fun authenticate(ap: PassportAP) {
        val epKey = EPMRZ(cardNumber, birthDate, expiredDate)
        ap.startBAC(epKey)
    }

    override fun read(tag: Tag): PassportCardData {
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

        return PassportCardData(
            fid = commonData.fid,
            sfid = commonData.shortFID.toUInt(),
            ldsVersion = commonData.ldsVersion,
            unicodeVersion = commonData.unicodeVersion,
            tags = commonData.tagList.map { t -> t.toUInt() }.toTypedArray(),
            documentCode = dataGroup1Mrz.documentCode,
            issuingCountry = dataGroup1Mrz.issuingCountry,
            name = dataGroup1Mrz.name,
            surname = dataGroup1Mrz.surname,
            givenName = dataGroup1Mrz.givenName,
            passportNumber = dataGroup1Mrz.passportNumber,
            passportNumberCheckDigit = dataGroup1Mrz.passportNumberCheckDigit,
            nationality = dataGroup1Mrz.nationality,
            birthDate = dataGroup1Mrz.birthDate,
            birthDateCheckDigit = dataGroup1Mrz.birthDateCheckDigit,
            sex = dataGroup1Mrz.sex,
            expirationDate = dataGroup1Mrz.expirationDate,
            expirationDateCheckDigit = dataGroup1Mrz.expirationDateCheckDigit,
            optionaData = dataGroup1Mrz.optionalData,
            optionalDataCheckDigit = dataGroup1Mrz.optionalDataCheckDigit,
            compositeCheckDigit = dataGroup1Mrz.compositeCheckDigit,
            photo = photoSrc,
            passiveAuthenticationResult = passiveAuthenticationResult,
            activeAuthenticationResult = activeAuthenticationResult
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

fun DriverLicenseChangedEntry.toChangeHistory(): DriverLicenseCardData.ChangeHistory {
    return DriverLicenseCardData.ChangeHistory(
        date = date.toISOString(),
        value = value.toString(),
        psc = psc
    )
}