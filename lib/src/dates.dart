part of dsg;

String _parseDate(String dateStr, String parseFormat, String outputFormat) {
  final _logger = Logger('dsg.dates');

  try {
    final date = DateFormat(parseFormat).parseLoose(dateStr.trim());
    return DateFormat(outputFormat).format(date);
  } catch (e) {
    _logger.warning('FAILED to parse date: $dateStr $e');
    return dateStr;
  }
}
