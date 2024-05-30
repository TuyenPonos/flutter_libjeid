import 'dart:convert';

abstract class FlutterLibjeidCardData {
  const FlutterLibjeidCardData();

  Map<String, dynamic> toJson();

  factory FlutterLibjeidCardData.fromJson(Map json) {
    switch (json['card_type']) {
      case 'resident_card':
        return ResidentCardData.fromJson(json);

      case 'my_number':
        return MyNumberCardData.fromJson(json);

      case 'driver_license':
        return DriverLicenseCardData.fromJson(json);

      case 'passport':
        return PassportCardData.fromJson(json);

      default:
        throw Exception('Invalid card type: ${json['type']}');
    }
  }
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

  factory DriverLicenseCardData.fromJson(Map json) {
    return DriverLicenseCardData(
      name: json['name'],
      kana: json['kana'],
      aliasName: json['alias_name'],
      callName: json['call_name'],
      birthDate: json['birth_date'],
      address: json['address'],
      issueDate: json['issue_date'],
      refNumber: json['ref_number'],
      colorClass: json['color_class'],
      expireDate: json['expire_date'],
      licenseNumber: json['license_number'],
      pscName: json['psc_name'],
      registeredDomicile: json['registered_domicile'],
      photo: json['photo'],
      signatureIssuer: json['signature_issuer'],
      signatureSubject: json['signature_subject'],
      signatureSKI: json['signature_ski'],
      verified: json['verified'],
      categories: (json['categories'] as List)
          .map((category) => DriverLicenseCardDataCategory.fromJson(category))
          .toList(),
      nameHistoryRecords: (json['name_history_records'] as List)
          .map((record) => ChangeHistory.fromJson(record))
          .toList(),
      addressHistoryRecords: (json['address_history_records'] as List)
          .map((record) => ChangeHistory.fromJson(record))
          .toList(),
      conditionHistoryRecords: (json['condition_history_records'] as List)
          .map((record) => ChangeHistory.fromJson(record))
          .toList(),
      conditionCancellationHistoryRecords:
          (json['condition_cancellation_history_records'] as List)
              .map((record) => ChangeHistory.fromJson(record))
              .toList(),
      registeredDomicileHistoryRecords:
          (json['registered_domicile_history_records'] as List)
              .map((record) => ChangeHistory.fromJson(record))
              .toList(),
    );
  }

  String get formattedName {
    final items =
        (jsonDecode(name) as List).map((e) => DataExplain.fromJson(e)).toList();
    return items.map((e) => e.toString()).join('');
  }

  String get formattedAddress {
    final items = (jsonDecode(address) as List)
        .map((e) => DataExplain.fromJson(e))
        .toList();
    return items.map((e) => e.toString()).join('');
  }

  String get formattedDomicile {
    final items = (jsonDecode(registeredDomicile) as List)
        .map((e) => DataExplain.fromJson(e))
        .toList();
    return items.map((e) => e.toString()).join('');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'kana': kana,
      'alias_name': aliasName,
      'call_name': callName,
      'birth_date': birthDate,
      'address': address,
      'issue_date': issueDate,
      'ref_number': refNumber,
      'color_class': colorClass,
      'expire_date': expireDate,
      'license_number': licenseNumber,
      'psc_name': pscName,
      'registered_domicile': registeredDomicile,
      'photo': photo,
      'signature_issuer': signatureIssuer,
      'signature_subject': signatureSubject,
      'signature_ski': signatureSKI,
      'verified': verified,
      'categories': categories?.map((category) => category.toJson()).toList(),
      'name_history_records':
          nameHistoryRecords.map((record) => record.toJson()).toList(),
      'address_history_records':
          addressHistoryRecords.map((record) => record.toJson()).toList(),
      'condition_history_records':
          conditionHistoryRecords.map((record) => record.toJson()).toList(),
      'condition_cancellation_history_records':
          conditionCancellationHistoryRecords
              .map((record) => record.toJson())
              .toList(),
      'registered_domicile_history_records': registeredDomicileHistoryRecords
          .map((record) => record.toJson())
          .toList(),
    };
  }
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

  factory DriverLicenseCardDataCategory.fromJson(Map json) {
    return DriverLicenseCardDataCategory(
      tag: json['tag'],
      name: json['name'],
      date: json['date'],
      isLicensed: json['is_licensed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'date': date,
      'is_licensed': isLicensed,
    };
  }
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

  factory ChangeHistory.fromJson(Map json) {
    return ChangeHistory(
      date: json['date'],
      value: json['value'],
      psc: json['psc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'value': value,
      'psc': psc,
    };
  }
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

  factory MyNumberCardData.fromJson(Map json) {
    return MyNumberCardData(
      myNumber: json['my_number'],
      name: json['name'],
      address: json['address'],
      birthDate: json['birth_date'],
      sex: json['sex'],
      expireDate: json['expire_date'],
      photo: json['photo'],
      nameImage: json['name_image'],
      addressImage: json['address_image'],
      myNumberImage: json['my_number_image'],
      verified: json['verified'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'my_number': myNumber,
      'name': name,
      'address': address,
      'birth_date': birthDate,
      'sex': sex,
      'expire_date': expireDate,
      'photo': photo,
      'name_image': nameImage,
      'address_image': addressImage,
      'my_number_image': myNumberImage,
      'verified': verified,
    };
  }
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

  factory ResidentCardData.fromJson(Map json) {
    return ResidentCardData(
      cardType: json['card_type'],
      photo: json['photo'],
      address: json['address'],
      addressCode: json['address_code'],
      addressUpdatedAt: json['address_updated_at'],
      cardFrontPhoto: json['card_front_photo'],
      updateStatus: json['update_status'],
      individualPermission: json['individual_permission'],
      comprehensivePermission: json['comprehensive_permission'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'card_type': cardType,
      'photo': photo,
      'address': address,
      'address_code': addressCode,
      'address_updated_at': addressUpdatedAt,
      'card_front_photo': cardFrontPhoto,
      'update_status': updateStatus,
      'individual_permission': individualPermission,
      'comprehensive_permission': comprehensivePermission,
    };
  }
}

class PassportCardData extends FlutterLibjeidCardData {
  final String fid;
  final int sfid;
  final String? ldsVersion;
  final String? unicodeVersion;
  final List<int> tags;
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

  factory PassportCardData.fromJson(Map json) {
    return PassportCardData(
      fid: json['fid'],
      sfid: json['sfid'],
      ldsVersion: json['lds_version'],
      unicodeVersion: json['unicode_version'],
      tags: json['tags'],
      documentCode: json['document_code'],
      issuingCountry: json['issuing_country'],
      name: json['name'],
      surname: json['surname'],
      givenName: json['given_name'],
      passportNumber: json['passport_number'],
      passportNumberCheckDigit: json['passport_number_check_digit'],
      nationality: json['nationality'],
      birthDate: json['birth_date'],
      birthDateCheckDigit: json['birth_date_check_digit'],
      sex: json['sex'],
      expirationDate: json['expiration_date'],
      expirationDateCheckDigit: json['expiration_date_check_digit'],
      optionaData: json['optiona_data'],
      optionalDataCheckDigit: json['optional_data_check_digit'],
      compositeCheckDigit: json['composite_check_digit'],
      photo: json['photo'],
      passiveAuthenticationResult: json['passive_authentication_result'],
      activeAuthenticationResult: json['active_authentication_result'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'fid': fid,
      'sfid': sfid,
      'lds_version': ldsVersion,
      'unicode_version': unicodeVersion,
      'tags': tags,
      'document_code': documentCode,
      'issuing_country': issuingCountry,
      'name': name,
      'surname': surname,
      'given_name': givenName,
      'passport_number': passportNumber,
      'passport_number_check_digit': passportNumberCheckDigit,
      'nationality': nationality,
      'birth_date': birthDate,
      'birth_date_check_digit': birthDateCheckDigit,
      'sex': sex,
      'expiration_date': expirationDate,
      'expiration_date_check_digit': expirationDateCheckDigit,
      'optiona_data': optionaData,
      'optional_data_check_digit': optionalDataCheckDigit,
      'composite_check_digit': compositeCheckDigit,
      'photo': photo,
      'passive_authentication_result': passiveAuthenticationResult,
      'active_authentication_result': activeAuthenticationResult,
    };
  }
}

class DataExplain {
  final String type;
  final String value;

  DataExplain({
    required this.type,
    required this.value,
  });

  factory DataExplain.fromJson(Map<String, dynamic> json) {
    return DataExplain(
      type: json['type'],
      value: json['value'],
    );
  }

  @override
  String toString() {
    return value;
  }
}
