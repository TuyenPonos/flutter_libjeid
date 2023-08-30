LibJeID (Library for Japanese Electronic ID) is a library for smartphones to access public IC cards such as My Number cards, driver's licenses, and passports that are popular in Japan.

![logo](https://github.com/TuyenPonos/flutter_libjeid/blob/main/logo.png)

## Features

### Official document

<https://www.osstech.co.jp/download/libjeid/>

### Android version function list

- Reading my number card
- Public personal authentication function of My Number Card
- Reading of residence cards and special permanent resident certificates
- Verification of authenticity of residence cards and special permanent resident certificates

### iOS version function list

- Reading my number card
- Reading of residence cards and special permanent resident certificates
- Verification of authenticity of residence cards and special permanent resident certificates

### Functions item in free version and paid version

![available_data](https://github.com/TuyenPonos/flutter_libjeid/blob/main/available_data.png)

## How to use

### 1. Scan My number card

You need pass the **Card PIN** of My number card, include 4 characters. Example "xxxx"

```dart
final result = await FlutterLibjeid().scanINCard(cardPin: "xxxx")
```

The result return as `Map<String, dynamic>`. If scanning is cancelled, it returns empty `{}`

**Data key and type of result**

|Key          |Type          |Description                                                                   |
|:----------------------|:----------------------|:-----------------------------------------------------------------------------|
|card_mynumber|String?|The card number on card face. Free version return `null`|
|card_mynumber_image|String?|The card number image, return Base64 encode as String. Free version return `null`|
|card_name|String|The name on card face|
|card_birth|String| The birthday on card face|
|card_sex|String| The gender on card face|
|card_address|String|The address on card face|
|validation_result|bool?|Return `true` if card is valid. Free version return `null`|
|card_expire|String|The card expired date|
|card_birth2|String|The birthday 2 on card face|
|card_sex2|String| The gender 2 on card face|
|card_name_image|String|The card name image, return Base64 encode as String|
|card_address_image|String|The card address image, return Base64 encode as String|
|card_photo| String| The card photo image, return Base64 encode as String|
|visualap_validation_result|bool?|Verification of authenticity of card surface AP. Return `true` if is valid. Free version return `null`|

### 2. Scan Residence card

You need pass the **Card Number** of My number card. Example "xxxxxxxxxxxx"

```dart
final result = await FlutterLibjeid().scanRCCard(cardNumber: "xxxxxxxxxxxx")
```

The result return as `Map<String, dynamic>`. If scanning is cancelled, it returns empty `{}`

**Data key and type of result**

|Key          |Type          |Description                                                                   |
|:----------------------|:----------------------|:-----------------------------------------------------------------------------|
|rc_card_type|String?|The card type name|
|rc_front_image|String?|The front card image, return Base64 encode as String|
|rc_photo|String?|The card image, return Base64 encode as String|
|comprehensive_permission|String|Comprehensive Permission description|
|individual_permission|String|Individual Permission description|
|update_status|String| The card update status|
|rc_signature|String|Valid card signature|
|rc_address|String|The card address|
|rc_valid|bool?|Return `true` if card is valid. Free version return `null`|

### 3. Stop scanning

After scanning successfully or throw Error, you should call stop scanning to close NFC session.

Try call this

```dart
FlutterLibjeid.stopScan();
```

### 4. Error codes

|Code          |Description                                                                   |
|:----------------------|:-----------------------------------------------------------------------------|
|not_input_card_number| When pass null or empty card number|
|not_input_card_pin|  When pass null or empty card pin|
|nfc_connect_error| Error while connecting NFC, such as: NFC is not support, NFC is off|
|incorrect_card_number| The card number is incorrect when verifying card number|
|incorrect_card_pin| The card pin is incorrect when verifying card pin|
|invalid_card_type| Card type is not support|
|unknown| Common error|

## Contributions

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please fill an issue.
If you fixed a bug or implemented a feature, please send a pull request.
