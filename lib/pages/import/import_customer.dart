import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maruti_kirba_lighting_solutions/service/api_service.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ImportCustomer extends StatefulWidget {
  const ImportCustomer({super.key});

  @override
  State<ImportCustomer> createState() => _ImportCustomerState();
}

class _ImportCustomerState extends State<ImportCustomer> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  int _successCount = 0;
  int _errorCount = 0;
  String? _fileName;
  List<Map<String, dynamic>> _failedRecords = [];

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting Excel file...';
      _hasError = false;
      _successCount = 0;
      _errorCount = 0;
      _fileName = null;
      _failedRecords.clear();
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

      if (table.rows.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Excel file is empty';
          _hasError = true;
        });
        return;
      }

      // Get headers
      final headers = table.rows[0]
          .map((e) => e?.toString().toLowerCase().trim() ?? '')
          .toList();

      // Find column indexes
      int? codeCol, nameCol, mobileCol, emailCol, dateCol;

      for (int i = 0; i < headers.length; i++) {
        final header = headers[i];
        if (header.contains('customer code') || header.contains('cust code')) {
          codeCol = i;
        } else if (header.contains('customer name') ||
            header.contains('cust name')) {
          nameCol = i;
        } else if (header.contains('mobile') || header.contains('phone')) {
          mobileCol = i;
        } else if (header.contains('email')) {
          emailCol = i;
        } else if (header.contains('created') || header.contains('date')) {
          dateCol = i;
        }
      }

      // Validate required columns
      if (codeCol == null || nameCol == null) {
        setState(() {
          _isLoading = false;
          _statusMessage =
              'Required columns not found. Your Excel must contain: '
              '"Customer Code" and "Customer Name" columns';
          _hasError = true;
        });
        return;
      }

      // Process each row
      for (int i = 1; i < table.rows.length; i++) {
        try {
          final row = table.rows[i];

          // Skip empty rows
          if (row.isEmpty ||
              row.every(
                (cell) => cell == null || cell.toString().trim().isEmpty,
              )) {
            continue;
          }

          // Get values
          final customerCode = _parseString(row[codeCol]);
          final customerName = _parseString(row[nameCol]);

          // Skip if required fields are empty
          if (customerCode.isEmpty || customerName.isEmpty) {
            _errorCount++;
            _failedRecords.add({
              'row': i + 1,
              'customerCode': customerCode,
              'customerName': customerName,
              'error': 'Missing required fields',
            });
            continue;
          }

          // Optional fields
          final mobileNumber = mobileCol != null && mobileCol < row.length
              ? _parseString(row[mobileCol])
              : null;

          final email = emailCol != null && emailCol < row.length
              ? _parseString(row[emailCol])
              : null;

          final createdAt =
              dateCol != null && dateCol < row.length && row[dateCol] != null
              ? _parseDateTime(row[dateCol].toString())
              : DateTime.now();

          // Prepare data for API
          final customerData = {
            'customerCode': customerCode,
            'customerName': customerName,
            if (mobileNumber != null && mobileNumber.isNotEmpty)
              'mobileNumber': mobileNumber,
            if (email != null && email.isNotEmpty) 'email': email,
            'createdAt': createdAt.toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          };

          // Call API to create customer
          try {
            final response = await ApiService.createCustomer(customerData);

            if (response != null) {
              _successCount++;
              debugPrint('Successfully created customer: $customerName');
            } else {
              throw Exception('Null response from API');
            }
          } catch (e) {
            _errorCount++;
            _failedRecords.add({
              'row': i + 1,
              'customerCode': customerCode,
              'customerName': customerName,
              'error': e.toString(),
            });
            debugPrint('Failed to create customer $customerName: $e');
          }

          // Update progress
          if (i % 5 == 0 || i == table.rows.length - 1) {
            setState(() {
              _statusMessage =
                  'Processing row $i/${table.rows.length - 1}\n'
                  'Successful: $_successCount, Failed: $_errorCount';
            });
            // Small delay to prevent UI freezing
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          _errorCount++;
          debugPrint('Error processing row $i: $e');
        }
      }

      setState(() {
        _isLoading = false;
        _statusMessage =
            'Import completed!\n'
            'Successful: $_successCount\n'
            'Failed: $_errorCount\n'
            'Total processed: ${table.rows.length - 1}';

        if (_failedRecords.isNotEmpty) {
          _statusMessage += '\n\nFailed records:';
          for (var record in _failedRecords.take(5)) {
            _statusMessage +=
                '\nRow ${record['row']}: ${record['customerName']} - ${record['error']}';
          }
          if (_failedRecords.length > 5) {
            _statusMessage += '\n...and ${_failedRecords.length - 5} more';
          }
        }

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

  void _showFailedRecords() {
    if (_failedRecords.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Failed Records (${_failedRecords.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _failedRecords.length,
            itemBuilder: (context, index) {
              final record = _failedRecords[index];
              return ListTile(
                title: Text('Row ${record['row']}: ${record['customerName']}'),
                subtitle: Text('Error: ${record['error']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Customer Data'),
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
            // Instructions Card (same as before)
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
                      '1. Prepare an Excel file with the following columns:',
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Customer Code (required)'),
                          Text('• Customer Name (required)'),
                          Text('• Mobile Number (optional)'),
                          Text('• Email (optional)'),
                          Text('• Created At (optional date)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('2. The first row should be headers'),
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
                        _hasError ? 'Import Status' : 'Import Status',
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
                      ),
                      if (_failedRecords.isNotEmpty)
                        TextButton(
                          onPressed: _showFailedRecords,
                          child: Text(
                            'View ${_failedRecords.length} failed records',
                            style: const TextStyle(color: Colors.blue),
                          ),
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
