class FlutterLibjeidError extends Error {
  FlutterLibjeidError(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Map<String, String?>? details;

  @override
  String toString() {
    return 'FlutterLibjeidError(code: $code, message: $message, details: ${details.toString()})';
  }

  factory FlutterLibjeidError.fromJSON(Map<String, dynamic> json) {
    switch (json['code']) {
      case 'NfcNotAvailable':
        return NfcNotAvailableError();

      case 'NfcTagUnableToConnect':
        return NfcTagUnableToConnectError(json['details']);

      case 'NfcCardBlocked':
        return NfcCardBlockedError(json['details']);

      case 'NfcCardTypeMismatch':
        return NfcCardTypeMismatchError(json['details']);

      case 'InvalidMethodArguments':
        return InvalidMethodArgumentsError(json['details']);

      case 'InvalidPin':
        return InvalidCardPinError(json['details']);

      case 'InvalidKey':
        return InvalidCardKeyError(json['details']);

      default:
        return UnknownError(json['details']);
    }
  }
}

class NfcNotAvailableError extends FlutterLibjeidError {
  NfcNotAvailableError() : super('NfcNotAvailable', 'NFC is not available');
}

class NfcTagUnableToConnectError extends FlutterLibjeidError {
  NfcTagUnableToConnectError(Map<String, String?>? details)
      : super('NfcTagUnableToConnect', 'Cannot connect to NFC tag', details);
}

class NfcCardBlockedError extends FlutterLibjeidError {
  NfcCardBlockedError(Map<String, String?>? details)
      : super('NfcCardBlocked', 'The card is blocked', details);
}

class NfcCardTypeMismatchError extends FlutterLibjeidError {
  NfcCardTypeMismatchError(Map<String, String?>? details)
      : super('NfcCardTypeMismatch', 'Cannot connect to NFC tag', details);
}

class InvalidMethodArgumentsError extends FlutterLibjeidError {
  InvalidMethodArgumentsError(Map<String, String?>? details)
      : super('InvalidMethodArguments', 'Invalid method channel arguments', details);
}

class InvalidCardPinError extends FlutterLibjeidError {
  final int remainingTimes;

  InvalidCardPinError._({required this.remainingTimes})
      : super('InvalidPin', 'Invalid card pin, remaining time(s): $remainingTimes');

  InvalidCardPinError(Map<String, String> details)
      : this._(remainingTimes: int.parse(details['remainingTimes']!));
}

class InvalidCardKeyError extends FlutterLibjeidError {
  InvalidCardKeyError(Map<String, String?>? details)
      : super('InvalidKey', 'Invalid card key', details);
}

class UnknownError extends FlutterLibjeidError {
  UnknownError(Map<String, String?>? details) : super('Unknown', 'Unknown error', details);
}
