import 'package:dart_helper_utils/dart_helper_utils.dart';

class CurrencyRequest {
  CurrencyRequest(this.currencyDate, this.currencyFrom, this.currencyTo);

  CurrencyRequest.fromJson(Map<String, Object?> jsonObject) {
    for (final mapEntry in jsonObject.entries) {
      switch (mapEntry.key) {
        case 'date':
          final dateString = mapEntry.value as String?;
          final parsedDate = dateString.tryToDateAutoFormat();
          if (parsedDate != null) {
            currencyDate = parsedDate;
          }
        case 'currencyFrom':
          final currency = mapEntry.value as String?;
          if (currency != null) {
            currencyFrom = currency;
          }
        case 'currencyTo':
          final currency = mapEntry.value as String?;
          if (currency != null) {
            currencyTo = currency;
          }
        case 'amountFrom':
          final amount = mapEntry.value as double?;
          if (amount != null) {
            amountFrom = amount;
          }
        default:
          throw FormatException('Unhandled SunRequest format', jsonObject);
      }
    }
  }

  DateTime currencyDate = DateTime.now();
  String currencyFrom = 'USD';
  String currencyTo = 'USD';
  double amountFrom = 1;

  @override
  String toString() => {
        'currencyDate': currencyDate.format('yyyy-MM-dd'),
        'currencyFrom': currencyFrom,
        'currencyTo': currencyTo,
        'amountFrom': amountFrom,
      }.toString();
}
