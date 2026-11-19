import 'package:intl/intl.dart';

final _decimal = NumberFormat.decimalPattern('pt_BR');
final _oneDecimal = NumberFormat.decimalPatternDigits(
  locale: 'pt_BR',
  decimalDigits: 1,
);
final _dateTime = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
final _month = DateFormat('MMM/yy', 'pt_BR');
final _hour = DateFormat("HH'h'", 'pt_BR');
final _hourWithDate = DateFormat("dd/MM\nHH'h'", 'pt_BR');
final _chartDateTime = DateFormat('dd/MM HH:mm', 'pt_BR');

String formatNumber(num value, {int decimals = 0}) =>
    decimals == 1 ? _oneDecimal.format(value) : _decimal.format(value);

String formatDateTime(DateTime value) => _dateTime.format(value.toLocal());

String formatMonth(DateTime value) => _month.format(value).replaceAll('.', '');

String formatHour(DateTime value) => _hour.format(value);

String formatHourWithDate(DateTime value) => _hourWithDate.format(value);

String formatChartDateTime(DateTime value) => _chartDateTime.format(value);

String formatSignedPercent(double value) =>
    '${value >= 0 ? '+' : ''}${_oneDecimal.format(value)}%';
