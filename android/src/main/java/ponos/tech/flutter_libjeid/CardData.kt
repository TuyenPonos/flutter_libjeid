package ponos.tech.flutter_libjeid

interface CardData {
    fun toJSON(): Map<String, Any?>
}

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
        val isLicensed: Boolean
    ) {
        fun toJSON(): Map<String, Any?> {
            return mapOf(
                "tag" to tag,
                "name" to name,
                "date" to date,
                "isLicensed" to isLicensed
            )
        }
    }

    data class ChangeHistory(
        val date: String,
        val value: String,
        val psc: String,
    ) {
        fun toJSON(): Map<String, Any?> {
            return mapOf(
                "date" to date,
                "value" to value,
                "psc" to psc
            )
        }
    }

    override fun toJSON(): Map<String, Any?> {
        return mapOf(
            "name" to name,
            "kana" to kana,
            "aliasName" to aliasName,
            "callName" to callName,
            "birthDate" to birthDate,
            "address" to address,
            "issueDate" to issueDate,
            "refNumber" to refNumber,
            "colorClass" to colorClass,
            "expireDate" to expireDate,
            "licenseNumber" to licenseNumber,
            "pscName" to pscName,
            "registeredDomicile" to registeredDomicile,
            "photo" to photo,
            "signatureIssuer" to signatureIssuer,
            "signatureSubject" to signatureSubject,
            "signatureSKI" to signatureSKI,
            "verified" to verified,
            "categories" to categories?.map { it.toJSON() },
            "nameHistoryRecords" to nameHistoryRecords.map { it.toJSON() },
            "addressHistoryRecords" to addressHistoryRecords.map { it.toJSON() },
            "conditionHistoryRecords" to conditionHistoryRecords.map { it.toJSON() },
            "conditionCancellationHistoryRecords" to conditionCancellationHistoryRecords.map { it.toJSON() },
            "registeredDomicileHistoryRecords" to registeredDomicileHistoryRecords.map { it.toJSON() },
        )
    }
}

data class MyNumberCardData(
    val myNumber: String?,
    val name: String?,
    val address: String?,
    val birthDate: String?,
    val sex : String?,
    val expireDate: String?,
    val photo: String?,
    val nameImage: String?,
    val addressImage: String?,
    val myNumberImage: String?,
    val verified: Boolean?
): CardData {
    override fun toJSON(): Map<String, Any?> {
        return mapOf(
            "myNumber" to myNumber,
            "name" to name,
            "address" to address,
            "birthDate" to birthDate,
            "sex" to sex,
            "expireDate" to expireDate,
            "photo" to photo,
            "nameImage" to nameImage,
            "addressImage" to addressImage,
            "myNumberImage" to myNumberImage,
            "verified" to verified,
        )
    }
}

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
): CardData {
    override fun toJSON(): Map<String, Any?> {
        return mapOf(
            "cardType" to cardType,
            "photo" to photo,
            "address" to address,
            "addressCode" to addressCode,
            "addressUpdatedAt" to addressUpdatedAt,
            "cardFrontPhoto" to cardFrontPhoto,
            "updateStatus" to updateStatus,
            "individualPermission" to individualPermission,
            "comprehensivePermission" to comprehensivePermission,
        )
    }
}

data class PassportCardData(
    val fid: String,
    val sfid: UInt,
    val ldsVersion: String?,
    val unicodeVersion: String?,
    val tags: Array<UInt>,
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
): CardData {
    override fun toJSON(): Map<String, Any?> = mapOf(
        "fid" to fid,
        "sfid" to sfid,
        "ldsVersion" to ldsVersion,
        "unicodeVersion" to unicodeVersion,
        "tags" to tags,
        "documentCode" to documentCode,
        "issuingCountry" to issuingCountry,
        "name" to name,
        "surname" to surname,
        "givenName" to givenName,
        "passportNumber" to passportNumber,
        "passportNumberCheckDigit" to passportNumberCheckDigit,
        "nationality" to nationality,
        "birthDate" to birthDate,
        "birthDateCheckDigit" to birthDateCheckDigit,
        "sex" to sex,
        "expirationDate" to expirationDate,
        "expirationDateCheckDigit" to expirationDateCheckDigit,
        "optionaData" to optionaData,
        "optionalDataCheckDigit" to optionalDataCheckDigit,
        "compositeCheckDigit" to compositeCheckDigit,
        "photo" to photo,
        "passiveAuthenticationResult" to passiveAuthenticationResult,
        "activeAuthenticationResult" to activeAuthenticationResult,
    )
}

sealed interface FlutterLibjeidEvent {
    data object Scanning: FlutterLibjeidEvent
    data object Connecting: FlutterLibjeidEvent
    data object Parsing: FlutterLibjeidEvent
    data class Success(val data: CardData) : FlutterLibjeidEvent
    data class Failed(val error: FlutterLibjeidException) : FlutterLibjeidEvent
    data object Cancelled: FlutterLibjeidEvent

    fun toJSON(): Map<String, Any?> {
        return when (this) {
            is Scanning -> mapOf("event" to "scanning")
            is Connecting -> mapOf("event" to "connecting")
            is Parsing -> mapOf("event" to "parsing")
            is Success -> mapOf("event" to "success", "data" to data.toJSON())
            is Failed -> mapOf("event" to "failed", "data" to error.toJSON())
            is Cancelled -> mapOf("event" to "cancelled")
        }
    }
}
