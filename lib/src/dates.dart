part of dsg;

String _parseDate(String dateStr, String parseFormat, String outputFormat) {
  try {
    final date = DateFormat(parseFormat).parseLoose(dateStr.trim());
    return DateFormat(outputFormat).format(date);
  } catch (e) {
    Log.w('dates.dart', 'FAILED to parse date: $dateStr $e');
    return dateStr;
  }
}
