LibJeID (Library for Japanese Electronic ID) is a library for smartphones to access public IC cards such as My Number cards, driver's licenses, and passports that are popular in Japan.

![logo](https://github.com/TuyenPonos/flutter_libjeid/blob/main/logo.png)

## Features

**Now we are using free version of libjeid, so you don't need any product library key to install. The product library is under developing**

### Official document

<https://www.osstech.co.jp/download/libjeid/>

### Android version function list

- Reading my number card
- Public personal authentication function of My Number Card
- Reading of residence cards and special permanent resident certificates
- Verification of authenticity of residence cards and special permanent resident certificates
- Reading driver's license
- Driving license authenticity verification

### iOS version function list

- Reading my number card
- Reading of residence cards and special permanent resident certificates
- Verification of authenticity of residence cards and special permanent resident certificates
- Reading driver's license
- Driving license authenticity verification

### Functions item in free version and paid version

![available_data](https://github.com/TuyenPonos/flutter_libjeid/blob/main/available_data.png)

## How to use

Heading to [example project](/example) to see the complete example of how to use this library.

First create an instance of FlutterLibjeid(), check for the NFC availability, and then subscribe to the events

```dart
final _scanner = FlutterLibjeid();

final isNfcAvailable = await _scanner.isAvailable();

if (!isNfcAvailable) {
  // Show error message
  return;
}

final _subscription = _scanner.eventStream.listen((event) {
  switch (event) {
    case FlutterLibjeidEventScanning():
      // Use .setMessage() to show the message inside the scanning dialog
      _scanner.setMessage(message: 'Scanning...');
      break;

    case FlutterLibjeidEventConnecting():
      _scanner.setMessage(message: 'Connecting...');
      break;

    case FlutterLibjeidEventParsing():
      _scanner.setMessage(message: 'Parsing...');
      break;

    case FlutterLibjeidEventSuccess(data: FlutterLibjeidCardData data):
      // Use .stopScan() to cancel the scanning process
      _scanner.stopScan();
      _onSuccess(data);
      break;

    case FlutterLibjeidEventFailed(error: FlutterLibjeidError error):
      _scanner.stopScan();
      _onError(error);
      break;

    case FlutterLibjeidEventCancelled():
        break;
  }
});
```

And then handling the data/error as needed

```dart
void _onSuccess(FlutterLibjeidCardData data) {
  switch (data) {
    case ResidentCardData():
      // Do something with the data
      break;

    case MyNumberCardData():
      // Do something with the data
      break;

    case DriverLicenseCardData():
      // Do something with the data
      break;

    case PassportCardData():
      // Do something with the data
      break;
  }
}

void _onError(FlutterLibjeidError error) {
  switch (error) {
    case NfcNotAvailableError():
      // Do something with the error
      break;

    case NfcTagUnableToConnectError():
      // Do something with the error
      break;

    case NfcCardBlockedError():
      // Do something with the error
      break;

    case NfcCardTypeMismatchError():
      // Do something with the error
      break;

    case InvalidMethodArgumentsError():
      // Do something with the error
      break;

    case InvalidCardPinError(int remainingTimes):
      // Do something with the error
      break;

    case InvalidCardKeyError():
      // Do something with the error
      break;

    case UnknownError():
      // Do something with the error
      break;
  }
}
```

Next, calling the scan method you want to use

```dart
await _scanner.scanResidentCard(cardNumber: 'xxxxxxxxxxxx');

await _scanner.scanMyNumberCard(pin: 'xxxx');

await _scanner.scanDriverLicenseCard(pin1: 'xxxx', pin2: 'xxxx');

await _scanner.scanPassportCard(cardNumber: 'xxxxxxxxxx', birthDate: 'xxxxxxxxxx', expiredDate: 'xxxxxxxxxx');
```

Finally, don't forget to unsubscribe the event stream when you no longer need it

```dart
_subscription.cancel();
```

## Issue Tag Connection Lost

There are some reason cause tag connect lost

- The iPhone is very sensitive to positioning, so even a slight movement of the card during reading may result in "Tag connection lost".
- There are differences in readability between devices. We have also confirmed that some devices can hardly read cards. Even with the same model, there may be individual differences.
- Try to keep your card near by tag while reading, don't move it

Issue is reported in official repository: <https://github.com/osstech-jp/libjeid-ios-app/issues/1>

## Contributions

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please fill an issue.
If you fixed a bug or implemented a feature, please send a pull request.
