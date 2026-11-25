import 'dart:convert';

import 'package:excel/excel.dart';
import 'dart:typed_data';

import '../../app/android_file_actions.dart';

enum FinanceExportFormat {
  csv('text/csv'),
  xlsx('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  const FinanceExportFormat(this.mime);
  final String mime;
}

class FinanceExport {
  const FinanceExport(this.name, this.headers, this.rows);

  final String name;
  final List<String> headers;
  final Iterable<List<Object?>> rows;

  Iterable<List<Object?>> get _table sync* {
    yield headers;
    yield* rows;
  }

  Uint8List encode(FinanceExportFormat format) => switch (format) {
    FinanceExportFormat.csv => Uint8List.fromList(
      utf8.encode(
        '\ufeff${_table.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n',
      ),
    ),
    FinanceExportFormat.xlsx => _workbook(),
  };

  static final _formulaPrefix = RegExp(r'^[\s\uFEFF]*[=+@\-]|^[\t\r\n]');

  static String _csvCell(Object? cell) {
    if (cell is num) return cell.toString();
    var text = cell?.toString() ?? '';
    if (_formulaPrefix.hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }

  Uint8List _workbook() {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    for (final row in _table) {
      sheet.appendRow([
        for (final cell in row)
          switch (cell) {
            null => null,
            int value => IntCellValue(value),
            double value => DoubleCellValue(value),
            _ => TextCellValue(cell.toString()),
          },
      ]);
    }
    final encoded =
        excel.encode() ?? (throw StateError('Could not encode workbook'));
    return Uint8List.fromList(encoded);
  }
}

class AndroidFinanceExport {
  const AndroidFinanceExport();

  Future<bool> send(
    FinanceExport table,
    FinanceExportFormat format, {
    required bool share,
  }) => const AndroidFileActions().send(
    name: '${table.name}.${format.name}',
    mime: format.mime,
    bytes: table.encode(format),
    share: share,
  );
}
