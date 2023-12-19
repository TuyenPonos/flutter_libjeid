package ponos.tech.flutter_libjeid.models

import org.bouncycastle.oer.its.ieee1609dot2.basetypes.UINT8

interface CardData

data class DriverLicenseCardData(
    val name: String,
    val kana: String?,
    val aliasName: String,
    val callName: String?,
    val birthDate: String?,
    val address: String,
    val issueDate: String?,
    val refNumber: String?,
    val colorClass: String?,
    val expireDate: String?,
    val licenseNumber: String?,
    val pscName: String?,
    val registeredDomicile: String,
    val photo: String?,
    val signatureIssuer: String?,
    val signatureSubject: String?,
    val signatureSKI: String?,
    val verified: Boolean?,
    val categories: List<Category>?,
    val nameHistoryRecords: List<ChangeHistory>,
    val addressHistoryRecords: List<ChangeHistory>,
    val conditionHistoryRecords: List<ChangeHistory>,
    val conditionCancellationHistoryRecords: List<ChangeHistory>,
    val registeredDomicileHistoryRecords: List<ChangeHistory>,
) : CardData {
    data class Category(
        val tag: Int,
        val name: String,
        val date: String,
        val isLicensed: Boolean,
    )

    data class ChangeHistory(
        val date: String,
        val value: String,
        val psc: String,
    )
}

data class MyNumberCardData(
    val myNumber: String?,
    val name: String?,
    val address: String?,
    val birthDate: String?,
    val sex : String?,
): CardData

data class ResidentCardData(
    val cardType: String?,
    val photo: String?,
    val address: String?,
    val addressCode: String?,
    val addressUpdatedAt: String?,
    val cardFrontPhoto: String?,
    val updateStatus: String?,
    val individualPermission: String?,
    val comprehensivePermission: String?,
): CardData

data class PassportCardData(
    val fid: String,
    val sfid: UINT8,
    val ldsVersion: String?,
    val unicodeVersion: String?,
    val tags: Array<UINT8>,
    val documentCode: String?,
    val issuingCountry: String?,
    val name: String?,
    val surname: String?,
    val givenName: String?,
    val passportNumber: String?,
    val passportNumberCheckDigit: String?,
    val nationality: String?,
    val birthDate: String?,
    val birthDateCheckDigit: String?,
    val sex: String?,
    val expirationDate: String?,
    val expirationDateCheckDigit: String?,
    val optionaData: String?,
    val optionalDataCheckDigit: String?,
    val compositeCheckDigit: String?,
    val photo: String?,
    val passiveAuthenticationResult: Boolean?,
    val activeAuthenticationResult: Boolean?,
): CardData
