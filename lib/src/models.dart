import 'dart:ffi';

abstract class FlutterLibjeidCardData {
  const FlutterLibjeidCardData();
}

class DriverLicenseCardData extends FlutterLibjeidCardData {
  final String name;
  final String? kana;
  final String aliasName;
  final String? callName;
  final String? birthDate;
  final String address;
  final String? issueDate;
  final String? refNumber;
  final String? colorClass;
  final String? expireDate;
  final String? licenseNumber;
  final String? pscName;
  final String registeredDomicile;
  final String? photo;
  final String? signatureIssuer;
  final String? signatureSubject;
  final String? signatureSKI;
  final bool? verified;
  final List<DriverLicenseCardDataCategory>? categories;
  final List<ChangeHistory> nameHistoryRecords;
  final List<ChangeHistory> addressHistoryRecords;
  final List<ChangeHistory> conditionHistoryRecords;
  final List<ChangeHistory> conditionCancellationHistoryRecords;
  final List<ChangeHistory> registeredDomicileHistoryRecords;

  const DriverLicenseCardData({
    required this.name,
    required this.kana,
    required this.aliasName,
    required this.callName,
    required this.birthDate,
    required this.address,
    required this.issueDate,
    required this.refNumber,
    required this.colorClass,
    required this.expireDate,
    required this.licenseNumber,
    required this.pscName,
    required this.registeredDomicile,
    required this.photo,
    required this.signatureIssuer,
    required this.signatureSubject,
    required this.signatureSKI,
    required this.verified,
    required this.categories,
    required this.nameHistoryRecords,
    required this.addressHistoryRecords,
    required this.conditionHistoryRecords,
    required this.conditionCancellationHistoryRecords,
    required this.registeredDomicileHistoryRecords,
  });
}

class DriverLicenseCardDataCategory {
  final int tag;
  final String name;
  final String date;
  final bool isLicensed;

  const DriverLicenseCardDataCategory({
    required this.tag,
    required this.name,
    required this.date,
    required this.isLicensed,
  });
}

class ChangeHistory {
  final String date;
  final String value;
  final String psc;

  const ChangeHistory({
    required this.date,
    required this.value,
    required this.psc,
  });
}

class MyNumberCardData extends FlutterLibjeidCardData {
  final String? myNumber;
  final String? name;
  final String? address;
  final String? birthDate;
  final String? sex;
  final String? expireDate;
  final String? photo;
  final String? nameImage;
  final String? addressImage;
  final String? myNumberImage;
  final bool? verified;

  const MyNumberCardData({
    required this.myNumber,
    required this.name,
    required this.address,
    required this.birthDate,
    required this.sex,
    required this.expireDate,
    required this.photo,
    required this.nameImage,
    required this.addressImage,
    required this.myNumberImage,
    required this.verified,
  });
}

class ResidentCardData extends FlutterLibjeidCardData {
  final String? cardType;
  final String? photo;
  final String? address;
  final String? addressCode;
  final String? addressUpdatedAt;
  final String? cardFrontPhoto;
  final String? updateStatus;
  final String? individualPermission;
  final String? comprehensivePermission;

  ResidentCardData({
    required this.cardType,
    required this.photo,
    required this.address,
    required this.addressCode,
    required this.addressUpdatedAt,
    required this.cardFrontPhoto,
    required this.updateStatus,
    required this.individualPermission,
    required this.comprehensivePermission,
  });
}

class PassportCardData extends FlutterLibjeidCardData {
  final String fid;
  final Uint8 sfid;
  final String? ldsVersion;
  final String? unicodeVersion;
  final List<Uint8> tags;
  final String? documentCode;
  final String? issuingCountry;
  final String? name;
  final String? surname;
  final String? givenName;
  final String? passportNumber;
  final String? passportNumberCheckDigit;
  final String? nationality;
  final String? birthDate;
  final String? birthDateCheckDigit;
  final String? sex;
  final String? expirationDate;
  final String? expirationDateCheckDigit;
  final String? optionaData;
  final String? optionalDataCheckDigit;
  final String? compositeCheckDigit;
  final String? photo;
  final bool? passiveAuthenticationResult;
  final bool? activeAuthenticationResult;

  PassportCardData({
    required this.fid,
    required this.sfid,
    required this.ldsVersion,
    required this.unicodeVersion,
    required this.tags,
    required this.documentCode,
    required this.issuingCountry,
    required this.name,
    required this.surname,
    required this.givenName,
    required this.passportNumber,
    required this.passportNumberCheckDigit,
    required this.nationality,
    required this.birthDate,
    required this.birthDateCheckDigit,
    required this.sex,
    required this.expirationDate,
    required this.expirationDateCheckDigit,
    required this.optionaData,
    required this.optionalDataCheckDigit,
    required this.compositeCheckDigit,
    required this.photo,
    required this.passiveAuthenticationResult,
    required this.activeAuthenticationResult,
  });
}
