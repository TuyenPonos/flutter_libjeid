class FlutterLibjeidError extends Error {
  FlutterLibjeidError(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Map? details;

  factory FlutterLibjeidError.fromJson(Map json) {
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

  @override
  String toString() {
    return "$runtimeType($code, $message, $details)";
  }
}

class NfcNotAvailableError extends FlutterLibjeidError {
  NfcNotAvailableError() : super('NfcNotAvailable', 'NFC is not available');
}

class NfcTagUnableToConnectError extends FlutterLibjeidError {
  NfcTagUnableToConnectError(Map? details)
      : super('NfcTagUnableToConnect', 'Cannot connect to NFC tag', details);
}

class NfcCardBlockedError extends FlutterLibjeidError {
  NfcCardBlockedError(Map? details)
      : super('NfcCardBlocked', 'The card is blocked', details);
}

class NfcCardTypeMismatchError extends FlutterLibjeidError {
  NfcCardTypeMismatchError(Map? details)
      : super('NfcCardTypeMismatch', 'Cannot connect to NFC tag', details);
}

class InvalidMethodArgumentsError extends FlutterLibjeidError {
  InvalidMethodArgumentsError(Map? details)
      : super('InvalidMethodArguments', 'Invalid method channel arguments',
            details);
}

class InvalidCardPinError extends FlutterLibjeidError {
  final int remainingTimes;

  InvalidCardPinError._({required this.remainingTimes})
      : super('InvalidPin',
            'Invalid card pin, remaining time(s): $remainingTimes');

  InvalidCardPinError(Map details)
      : this._(remainingTimes: int.parse(details['remainingTimes']!));
}

class InvalidCardKeyError extends FlutterLibjeidError {
  InvalidCardKeyError(Map? details)
      : super('InvalidKey', 'Invalid card key', details);
}

class UnknownError extends FlutterLibjeidError {
  UnknownError(Map? details) : super('Unknown', 'Unknown error', details);
}
