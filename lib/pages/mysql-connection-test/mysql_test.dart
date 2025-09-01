import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class MysqlTest extends StatefulWidget {
  const MysqlTest({super.key});

  @override
  State<MysqlTest> createState() => _MysqlTestState();
}

class _MysqlTestState extends State<MysqlTest> {
  String _connectionStatus = 'Not Connected';
  bool _isTesting = false;
  String _testResult = '';
  final List<Map<String, String>> _connectionHistory = [];

  // Your test function
  Future<void> testMySQLConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = 'Testing connection...';
      _testResult = '';
    });

    try {
      final settings = ConnectionSettings(
        host: '192.168.1.7',
        port: 3306,
        user: 'maruti_kirba',
        password: r'Cloud9tally123$%',
        db: 'maruti_kirba_database',
      );

      _testResult += 'Connecting to MySQL...\n';
      setState(() {}); // Update UI

      final conn = await MySqlConnection.connect(settings);
      _testResult += 'Connected successfully!\n';
      setState(() {}); // Update UI

      // Test a simple query
      var results = await conn.query('SELECT version()');
      for (var row in results) {
        _testResult += 'MySQL version: ${row[0]}\n';
      }

      // Test if we can access the customer_master table
      try {
        var tableResults = await conn.query(
          'SELECT COUNT(*) FROM customer_master',
        );
        for (var row in tableResults) {
          _testResult += 'Customer records count: ${row[0]}\n';
        }
      } catch (e) {
        _testResult += 'Note: customer_master table might not exist: $e\n';
      }

      await conn.close();
      _testResult += 'Connection closed.\n';

      setState(() {
        _connectionStatus = 'Connected successfully!';
        _connectionHistory.add({
          'timestamp': DateTime.now().toString(),
          'status': 'Success',
          'details': 'MySQL version retrieved successfully',
        });
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed!';
        _testResult += 'Connection failed: $e\n';
        _connectionHistory.add({
          'timestamp': DateTime.now().toString(),
          'status': 'Failed',
          'details': e.toString(),
        });
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  // Function to test inserting data
  Future<void> testInsertData() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = 'Testing data insertion...';
    });

    try {
      final settings = ConnectionSettings(
        host: '192.168.1.7',
        port: 3306,
        user: 'maruti_kirba',
        password: r'Cloud9tally123$%',
        db: 'maruti_kirba_database',
      );

      final conn = await MySqlConnection.connect(settings);

      // Create table if it doesn't exist
      await conn.query('''
        CREATE TABLE IF NOT EXISTS customer_master (
          id INT AUTO_INCREMENT PRIMARY KEY,
          customer_code VARCHAR(50),
          customer_name VARCHAR(100) NOT NULL,
          mobile_number VARCHAR(15),
          email VARCHAR(100),
          created_at DATETIME,
          updated_at DATETIME
        )
      ''');

      // Insert test data
      final result = await conn.query(
        'INSERT INTO customer_master (customer_code, customer_name, mobile_number, email, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'TEST001',
          'Test Customer',
          '1234567890',
          'test@example.com',
          DateTime.now(),
          DateTime.now(),
        ],
      );

      _testResult += 'Inserted record with ID: ${result.insertId}\n';

      // Verify the data was inserted
      var results = await conn.query(
        'SELECT * FROM customer_master WHERE id = ?',
        [result.insertId],
      );
      for (var row in results) {
        _testResult += 'Retrieved customer: ${row['customer_name']}\n';
      }

      await conn.close();

      setState(() {
        _connectionStatus = 'Data inserted successfully!';
        _connectionHistory.add({
          'timestamp': DateTime.now().toString(),
          'status': 'Success',
          'details': 'Test data inserted with ID: ${result.insertId}',
        });
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Data insertion failed!';
        _testResult += 'Insert failed: $e\n';
        _connectionHistory.add({
          'timestamp': DateTime.now().toString(),
          'status': 'Failed',
          'details': e.toString(),
        });
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  // Function to test reading data
  Future<void> testReadData() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = 'Testing data reading...';
    });

    try {
      final settings = ConnectionSettings(
        host: '192.168.1.7',
        port: 3306,
        user: 'maruti_kirba',
        password: r'Cloud9tally123$%',
        db: 'maruti_kirba_database',
      );

      final conn = await MySqlConnection.connect(settings);

      // Try to read data from customer_master table
      try {
        var results = await conn.query('SELECT * FROM customer_master');
        _testResult += 'Found ${results.length} customer records:\n';

        for (var row in results) {
          _testResult +=
              ' - ${row['customer_name']} (${row['customer_code']})\n';
        }

        if (results.isEmpty) {
          _testResult += 'No customer records found in the database.\n';
        }
      } catch (e) {
        _testResult += 'Error reading customer data: $e\n';
        _testResult += 'The customer_master table might not exist yet.\n';
      }

      await conn.close();

      setState(() {
        _connectionStatus = 'Data read successfully!';
        _connectionHistory.add({
          'timestamp': DateTime.now().toString(),
          'status': 'Success',
          'details': 'Data read operation completed',
        });
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Data read failed!';
        _testResult += 'Read failed: $e\n';
        _connectionHistory.add({
          'timestamp': DateTime.now().toString(),
          'status': 'Failed',
          'details': e.toString(),
        });
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  // Clear test results
  void _clearResults() {
    setState(() {
      _testResult = '';
      _connectionStatus = 'Not Connected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MySQL Connection Tester'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearResults,
            tooltip: 'Clear Results',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontSize: 16,
                        color: _connectionStatus.contains('Failed')
                            ? Colors.red
                            : _connectionStatus.contains('Connected') ||
                                  _connectionStatus.contains('Success')
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _isTesting ? null : testMySQLConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  child: _isTesting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Test Connection',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                ElevatedButton(
                  onPressed: _isTesting ? null : testInsertData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  child: _isTesting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Test Insert',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                ElevatedButton(
                  onPressed: _isTesting ? null : testReadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  child: _isTesting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Test Read',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Test results
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResult,
                            style: const TextStyle(
                              fontFamily: 'Monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Connection history
            const Text(
              'Connection History:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _connectionHistory.length,
                itemBuilder: (context, index) {
                  final entry =
                      _connectionHistory[_connectionHistory.length -
                          1 -
                          index]; // Reverse order
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: entry['status'] == 'Success'
                        ? Colors.green[50]
                        : Colors.red[50],
                    child: ListTile(
                      title: Text(
                        '${entry['timestamp']?.split(' ')[1]} - ${entry['status']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: entry['status'] == 'Success'
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                      subtitle: Text(entry['details']!),
                      trailing: Icon(
                        entry['status'] == 'Success'
                            ? Icons.check_circle
                            : Icons.error,
                        color: entry['status'] == 'Success'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
