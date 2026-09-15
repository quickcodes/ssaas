class CsvHelper {
  CsvHelper._();

  static String toCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final str = cell?.toString() ?? '';
        if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\r\n');
  }
}
