import 'package:dart_helper_utils/dart_helper_utils.dart';

class CurrencyRequest {
  CurrencyRequest(this.currencyDate, this.currencyFrom, this.currencyTo);

  CurrencyRequest.fromJson(Map<String, Object?> jsonObject) {
    currencyDate = DateTime.now();
    currencyFrom = 'USD';
    currencyTo = 'USD';
    amountFrom = 1.0;
    switch (jsonObject) {
      case {'date': final String dateString}:
        final parsedDate = dateString.tryToDateAutoFormat();
        if (parsedDate != null) {
          currencyDate = parsedDate;
        }
      case {'currencyFrom': final String currency}:
        currencyFrom = currency;
      case {'currencyTo': final String currency}:
        currencyTo = currency;
      case {'amountFrom': final double amount}:
        amountFrom = amount;
      default:
        throw FormatException('Unhandled SunRequest format', jsonObject);
    }
  }

  late final DateTime currencyDate;
  late final String currencyFrom;
  late final String currencyTo;
  late final double amountFrom;

  @override
  String toString() => {
        'currencyDate': currencyDate.format('yyyy-MM-dd'),
        'currencyFrom': currencyFrom,
        'currencyTo': currencyTo,
        'amountFrom': amountFrom,
      }.toString();
}
