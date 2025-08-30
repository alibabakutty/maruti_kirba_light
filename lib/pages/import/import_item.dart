import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maruti_kirba_lighting_solutions/models/item_master_data.dart';
import 'package:maruti_kirba_lighting_solutions/service/mysql_service.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ImportItem extends StatefulWidget {
  const ImportItem({super.key});

  @override
  State<ImportItem> createState() => _ImportItemState();
}

class _ImportItemState extends State<ImportItem> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  int _successCount = 0;
  int _errorCount = 0;
  final MysqlService _mysqlService = MysqlService();
  String? _fileName;

  @override
  void initState() {
    super.initState();
    // Ensure MySql service is initialized
    _initializeMySqlService();
  }

  Future<void> _initializeMySqlService() async {
    try {
      await _mysqlService.initialize();
    } catch (e) {
      debugPrint('MySQL initialization error: $e');
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting Excel file...';
      _hasError = false;
      _successCount = 0;
      _errorCount = 0;
      _fileName = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No file selected';
        });
        return;
      }

      final file = result.files.single;
      setState(() => _fileName = file.name);

      if (file.bytes == null || file.bytes!.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'File is empty or cannot be read';
          _hasError = true;
        });
        return;
      }

      await _processExcelFile(file.bytes!);
    } catch (e) {
      debugPrint('Import error: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: ${e.toString()}';
        _hasError = true;
      });
    }
  }

  Future<void> _processExcelFile(Uint8List bytes) async {
    setState(() => _statusMessage = 'Processing Excel file...');

    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      final table = decoder.tables.values.first;

      if (table.rows.length <= 1) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No data found in Excel sheet (only header row)';
          _hasError = true;
        });
        return;
      }

      // Process each row individually
      for (int i = 1; i < table.rows.length; i++) {
        try {
          final row = table.rows[i];
          if (row.length < 5) {
            _errorCount++;
            continue;
          }

          final itemCode = _parseInt(row[0]);
          if (itemCode == null || itemCode <= 0) {
            _errorCount++;
            continue;
          }

          final itemName = _parseString(row[1]);
          final uom = _parseString(row[2]).isNotEmpty
              ? _parseString(row[2])
              : 'Nos';
          final itemRateAmount = Decimal.parse(_parseDouble(row[3]).toString());
          final gstRate = row.length > 4 ? _parseDouble(row[4]) : 0.0;
          final gstAmount = row.length > 5 ? _parseDouble(row[5]) : 0.0;
          final totalAmount = row.length > 6 ? _parseDouble(row[6]) : 0.0;
          final mrpAmount = row.length > 7 ? _parseDouble(row[7]) : 0.0;
          final itemStatus = _parseBool(row.length > 8 ? row[8] : true) ?? true;

          final createdAt = row.length > 9 && row[9] != null
              ? _parseDateTime(row[9].toString())
              : DateTime.now();

          final item = ItemMasterData(
            itemCode: itemCode,
            itemName: itemName,
            uom: uom,
            itemRateAmount: itemRateAmount.toDouble(),
            gstRate: gstRate,
            gstAmount: gstAmount,
            totalAmount: totalAmount,
            mrpAmount: mrpAmount,
            itemStatus: itemStatus,
            createdAt: createdAt,
          );

          // Add to MySql database
          final success = await _mysqlService.addItemMasterData(item);

          if (success) {
            _successCount++;
          } else {
            _errorCount++;
          }

          if (i % 10 == 0 || i == table.rows.length - 1) {
            setState(() {
              _statusMessage = 'Processing row $i/${table.rows.length - 1}...';
            });
            await Future.delayed(const Duration(milliseconds: 1));
          }
        } catch (e) {
          debugPrint('Error processing row $i: $e');
          _errorCount++;
        }
      }

      setState(() {
        _isLoading = false;
        _statusMessage =
            '''
Import completed!
Successful: $_successCount
Failed: $_errorCount
Total: ${table.rows.length - 1}''';
        _hasError = _errorCount > 0;
      });
    } catch (e) {
      debugPrint('Excel processing error: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error processing Excel file: ${e.toString()}';
        _hasError = true;
      });
    }
  }

  DateTime _parseDateTime(String dateString) {
    try {
      final formats = [
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd-MM-yyyy'),
        DateFormat('yyyy/MM/dd'),
        DateFormat('dd/MM/yyyy HH:mm:ss'),
        DateFormat('MM/dd/yyyy HH:mm:ss'),
        DateFormat('yyyy-MM-dd HH:mm:ss'),
      ];

      for (final format in formats) {
        try {
          return format.parse(dateString);
        } catch (_) {}
      }
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  String _parseString(dynamic value) => value?.toString().trim() ?? '';

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final strValue = value.toString().trim().toLowerCase();
    return strValue == 'true' ||
        strValue == '1' ||
        strValue == 'yes' ||
        strValue == 'y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Item Master Data'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1. Prepare an Excel file with the following columns in order:',
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Item Code (required, must be unique)'),
                          Text('• Item Name (required)'),
                          Text('• UOM (required, default to "Nos")'),
                          Text('• Item Rate Amount (required)'),
                          Text('• GST Rate (optional, default 0.0)'),
                          Text('• GST Amount (optional, default 0.0)'),
                          Text('• Total Amount (optional, default 0.0)'),
                          Text('• MRP Amount (optional, default 0.0)'),
                          Text('• Item Status (optional, default true)'),
                          Text('• Timestamp (optional)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '2. The first row should be headers (will be skipped)',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fileName != null
                          ? 'Selected file: $_fileName'
                          : 'No file selected',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: _fileName != null ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Select Excel File'),
                onPressed: _isLoading ? null : _importData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_statusMessage.isNotEmpty)
              Card(
                color: _hasError ? Colors.red[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _hasError ? 'Import Status (Errors)' : 'Import Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _hasError
                              ? Colors.red[800]
                              : Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _hasError
                              ? Colors.red[800]
                              : Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

