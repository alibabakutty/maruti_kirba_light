import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maruti_kirba_lighting_solutions/models/customer_master_data.dart';
import 'package:maruti_kirba_lighting_solutions/models/item_master_data.dart';
import 'package:mysql1/mysql1.dart';
import 'package:maruti_kirba_lighting_solutions/models/executive_master_data.dart';

class MysqlService {
  static final MysqlService _instance = MysqlService._internal();
  MySqlConnection? _connection;
  bool _isInitialized = false;
  bool _isInitializing = false;

  factory MysqlService() {
    return _instance;
  }

  MysqlService._internal();

  // Initialize database connection with error handling and timeout
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      print("Initializing MySQL connection...");

      final settings = ConnectionSettings(
        host: dotenv.get('DB_HOST', fallback: 'localhost'),
        port: int.parse(dotenv.get('DB_PORT', fallback: '3306')),
        user: dotenv.get('DB_USER', fallback: 'root'),
        password: dotenv.get('DB_PASSWORD', fallback: ''),
        db: dotenv.get('DB_NAME', fallback: 'test_db'),
        timeout: const Duration(seconds: 10),
      );

      _connection = await MySqlConnection.connect(
        settings,
      ).timeout(const Duration(seconds: 15));

      // Test connection with a simple query
      await _connection!.query('SELECT 1').timeout(const Duration(seconds: 5));

      // Create tables if they don't exist (but don't block on this)
      unawaited(_createTableIfNotExists());

      _isInitialized = true;
      print("MySQL Service initialized successfully");
    } on TimeoutException catch (e) {
      print("MySQL connection timeout: $e");
      _isInitialized = false;
    } on MySqlException catch (e) {
      print("MySQL connection error: $e");
      _isInitialized = false;
    } catch (e) {
      print("Unexpected error during MySQL initialization: $e");
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _createTableIfNotExists() async {
    if (!isConnected) return;

    try {
      // Executive Master Table
      await _connection!
          .query('''
        CREATE TABLE IF NOT EXISTS executive_master_data (
          id INT AUTO_INCREMENT PRIMARY KEY,
          executive_name VARCHAR(255) NOT NULL UNIQUE,
          mobile_number VARCHAR(15) NOT NULL UNIQUE,
          email VARCHAR(255) NOT NULL UNIQUE,
          password VARCHAR(255) NOT NULL,
          created_at DATETIME NOT NULL,
          updated_at DATETIME NULL
        )
      ''')
          .timeout(const Duration(seconds: 10));

      // Customer Master Table
      await _connection!
          .query('''
        CREATE TABLE IF NOT EXISTS customer_master_data (
          id INT AUTO_INCREMENT PRIMARY KEY,
          customer_code VARCHAR(50) NOT NULL UNIQUE,
          customer_name VARCHAR(255) NOT NULL,
          mobile_number VARCHAR(15) NULL,
          email VARCHAR(255) NOT NULL,
          created_at DATETIME NOT NULL,
          updated_at DATETIME NULL
        )
      ''')
          .timeout(const Duration(seconds: 10));

      // Item Master Table
      await _connection!
          .query('''
        CREATE TABLE IF NOT EXISTS item_master_data(
          id INT AUTO_INCREMENT PRIMARY KEY,
          item_code INT NOT NULL UNIQUE,
          item_name VARCHAR(255) NOT NULL,
          uom VARCHAR(20) DEFAULT 'Nos',
          item_rate_amount DECIMAL(10,2) NOT NULL,
          gst_rate DECIMAL(5,2) DEFAULT 0.0,
          gst_amount DECIMAL(10,2) DEFAULT 0.0,
          total_amount DECIMAL(10,2) DEFAULT 0.0,
          mrp_amount DECIMAL(10,2) DEFAULT 0.0,
          item_status BOOLEAN DEFAULT TRUE,
          created_at DATETIME NOT NULL,
          updated_at DATETIME NULL
        ) 
      ''')
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      // ignore: avoid_print
      print("Table creation timeout: $e");
    } catch (e) {
      // ignore: avoid_print
      print("Error creating tables: $e");
    }
  }

  String _formatDateTime(DateTime dt) {
    return dt.toIso8601String().substring(0, 19).replaceFirst('T', ' ');
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  // Helper method to check connection before executing queries
  Future<bool> _checkConnection() async {
    if (!isConnected) {
      try {
        await initialize();
        return isConnected;
      } catch (e) {
        // ignore: avoid_print
        print("Failed to re-establish connection: $e");
        return false;
      }
    }
    return true;
  }

  // Check if connection is available
  bool get isConnected => _isInitialized && _connection != null;

  // ========== EXECUTIVE MASTER METHODS ==========

  Future<bool> addExecutiveMasterData(
    ExecutiveMasterData executiveMasterData,
  ) async {
    if (!await _checkConnection()) return false;

    try {
      await _connection!
          .query(
            '''
        INSERT INTO executive_master_data (executive_name, mobile_number, email, password, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)
        ''',
            [
              executiveMasterData.executiveName,
              executiveMasterData.mobileNumber,
              executiveMasterData.email,
              executiveMasterData.password,
              _formatDateTime(executiveMasterData.createdAt),
              executiveMasterData.updatedAt != null
                  ? _formatDateTime(executiveMasterData.updatedAt!)
                  : null,
            ],
          )
          .timeout(const Duration(seconds: 15));
      return true;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout adding executive master data");
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding executive master data: $e');
      return false;
    }
  }

  Future<ExecutiveMasterData?> getExecutiveByExecutiveName(
    String executiveName,
  ) async {
    if (!await _checkConnection()) return null;

    try {
      final results = await _connection!
          .query(
            'SELECT * FROM executive_master_data WHERE executive_name = ? LIMIT 1',
            [executiveName],
          )
          .timeout(const Duration(seconds: 15));

      if (results.isNotEmpty) {
        final row = results.first;
        return ExecutiveMasterData.fromFetchMySql({
          'executive_name': row['executive_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'password': row['password'],
          'created_at': row['created_at'],
          'updated_at': row['updated_at'],
        });
      }
      return null;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout fetching executive by name");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching executive by name: $e');
      return null;
    }
  }

  Future<ExecutiveMasterData?> getExecutiveByMobileNumber(
    String mobileNumber,
  ) async {
    if (!await _checkConnection()) return null;

    try {
      final results = await _connection!
          .query(
            'SELECT * FROM executive_master_data WHERE mobile_number = ? LIMIT 1',
            [mobileNumber],
          )
          .timeout(const Duration(seconds: 15));

      if (results.isNotEmpty) {
        final row = results.first;
        return ExecutiveMasterData.fromFetchMySql({
          'executive_name': row['executive_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'password': row['password'],
          'created_at': row['created_at'],
          'updated_at': row['updated_at'],
        });
      }
      return null;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout fetching executive by mobile");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching executive by mobile: $e');
      return null;
    }
  }

  Future<List<ExecutiveMasterData>> getAllExecutives() async {
    if (!await _checkConnection()) return [];

    try {
      final results = await _connection!
          .query('SELECT * FROM executive_master_data ORDER BY executive_name')
          .timeout(const Duration(seconds: 15));

      return results.map((row) {
        return ExecutiveMasterData.fromFetchMySql({
          'executive_name': row['executive_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'password': row['password'],
          'created_at': row['created_at'],
          'updated_at': row['updated_at'],
        });
      }).toList();
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout fetching all executives");
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching all executives: $e');
      return [];
    }
  }

  Future<bool> updateExecutiveMasterDataByExecutiveName(
    String oldExecutiveName,
    ExecutiveMasterData updatedData,
  ) async {
    if (!await _checkConnection()) return false;

    try {
      if (oldExecutiveName != updatedData.executiveName) {
        final duplicateCheck = await _connection!
            .query(
              'SELECT id FROM executive_master_data WHERE executive_name = ? LIMIT 1',
              [updatedData.executiveName],
            )
            .timeout(const Duration(seconds: 10));

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      final result = await _connection!
          .query(
            '''UPDATE executive_master_data 
           SET executive_name = ?, mobile_number = ?, email = ?, password = ?, updated_at = ?
           WHERE executive_name = ?''',
            [
              updatedData.executiveName,
              updatedData.mobileNumber,
              updatedData.email,
              updatedData.password,
              _formatDateTime(DateTime.now()),
              oldExecutiveName,
            ],
          )
          .timeout(const Duration(seconds: 15));

      return result.affectedRows! > 0;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout updating executive by name");
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating executive by name: $e');
      return false;
    }
  }

  // Update executive by mobile number
  Future<bool> updateExecutiveMasterDataByMobileNumber(
    String oldMobileNumber,
    ExecutiveMasterData updatedData,
  ) async {
    try {
      // Check for duplicate mobile number
      if (oldMobileNumber != updatedData.mobileNumber) {
        final duplicateCheck = await _connection!.query(
          'SELECT id FROM executive_master_data WHERE mobile_number = ? LIMIT 1',
          [updatedData.mobileNumber],
        );

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      // Update the record
      final result = await _connection!.query(
        '''UPDATE executive_master_data 
           SET executive_name = ?, mobile_number = ?, email = ?, password = ?, updated_at = ?
           WHERE mobile_number = ?''',
        [
          updatedData.executiveName,
          updatedData.mobileNumber,
          updatedData.email,
          updatedData.password,
          _formatDateTime(DateTime.now()),
          oldMobileNumber,
        ],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating executive by mobile: $e');
      return false;
    }
  }

  // ========== CUSTOMER MASTER METHODS ==========

  Future<bool> addCustomerMasterData(
    CustomerMasterData customerMasterData,
  ) async {
    if (!await _checkConnection()) return false;

    try {
      await _connection!
          .query(
            '''
        INSERT INTO customer_master_data (customer_code, customer_name, mobile_number, email, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
            [
              customerMasterData.customerCode,
              customerMasterData.customerName,
              customerMasterData.mobileNumber,
              customerMasterData.email,
              _formatDateTime(customerMasterData.createdAt),
              customerMasterData.updatedAt != null
                  ? _formatDateTime(customerMasterData.updatedAt!)
                  : null,
            ],
          )
          .timeout(const Duration(seconds: 15));
      return true;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout adding customer master data");
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding customer master data: $e');
      return false;
    }
  }

  Future<CustomerMasterData?> getCustomerByCustomerName(
    String customerName,
  ) async {
    if (!await _checkConnection()) return null;

    try {
      final results = await _connection!
          .query(
            'SELECT * FROM customer_master_data WHERE customer_name = ? LIMIT 1',
            [customerName],
          )
          .timeout(const Duration(seconds: 15));

      if (results.isNotEmpty) {
        final row = results.first;
        return CustomerMasterData.fromFetchMySql({
          'customer_code': row['customer_code'],
          'customer_name': row['customer_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'created_at': _parseDateTime(row['created_at']),
          'updated_at': _parseDateTime(row['updated_at']),
        });
      }
      return null;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout fetching customer by name");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching customer by name: $e');
      return null;
    }
  }

  // Fetch customer by mobile number
  Future<CustomerMasterData?> getCustomerByMobileNumber(
    String mobileNumber,
  ) async {
    try {
      final results = await _connection!.query(
        'SELECT * FROM customer_master_data WHERE mobile_number = ? LIMIT 1',
        [mobileNumber],
      );

      if (results.isNotEmpty) {
        final row = results.first;
        return CustomerMasterData.fromFetchMySql({
          'customer_code': row['customer_code'],
          'customer_name': row['customer_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'created_at': _parseDateTime(row['created_at']),
          'updated_at': _parseDateTime(row['updated_at']),
        });
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching customer by mobile: $e');
      return null;
    }
  }

  Future<List<CustomerMasterData>> getAllCustomers() async {
    if (!await _checkConnection()) return [];

    try {
      final results = await _connection!
          .query('SELECT * FROM customer_master_data ORDER BY customer_name')
          .timeout(const Duration(seconds: 15));

      return results.map((row) {
        return CustomerMasterData.fromFetchMySql({
          'customer_code': row['customer_code'],
          'customer_name': row['customer_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'created_at': _parseDateTime(row['created_at']),
          'updated_at': _parseDateTime(row['updated_at']),
        });
      }).toList();
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout fetching all customers");
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching all customers: $e');
      return [];
    }
  }

  // Update customer by customer name
  Future<bool> updateCustomerDataByCustomerName(
    String oldCustomerName,
    CustomerMasterData updatedData,
  ) async {
    try {
      // check for duplicate customer name
      if (oldCustomerName != updatedData.customerName) {
        final duplicateCheck = await _connection!.query(
          'SELECT id FROM customer_master_data WHERE customer_name = ? LIMIT 1',
          [updatedData.customerName],
        );

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      // Update the record
      final result = await _connection!.query(
        '''UPDATE customer_master_data 
           SET customer_code = ?, customer_name = ?, mobile_number = ?, email = ?, updated_at = ?
           WHERE customer_name = ?''',
        [
          updatedData.customerCode,
          updatedData.customerName,
          updatedData.mobileNumber,
          updatedData.email,
          _formatDateTime(DateTime.now()),
          oldCustomerName,
        ],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating customer by customer name: $e');
      return false;
    }
  }

  // ========== ITEM MASTER METHODS ==========

  Future<bool> addItemMasterData(ItemMasterData itemMasterData) async {
    if (!await _checkConnection()) return false;

    try {
      await _connection!
          .query(
            '''
        INSERT INTO item_master_data (item_code, item_name, uom, item_rate_amount, gst_rate, gst_amount, total_amount, mrp_amount, item_status, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
            [
              itemMasterData.itemCode,
              itemMasterData.itemName,
              itemMasterData.uom,
              itemMasterData.itemRateAmount,
              itemMasterData.gstRate,
              itemMasterData.gstAmount,
              itemMasterData.totalAmount,
              itemMasterData.mrpAmount,
              itemMasterData.itemStatus,
              _formatDateTime(itemMasterData.createdAt),
              itemMasterData.updatedAt != null
                  ? _formatDateTime(itemMasterData.updatedAt!)
                  : null,
            ],
          )
          .timeout(const Duration(seconds: 15));
      return true;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout adding item master data");
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding item master data: $e');
      return false;
    }
  }

  Future<ItemMasterData?> getItemByItemName(String itemName) async {
    if (!await _checkConnection()) return null;

    try {
      final results = await _connection!
          .query('SELECT * FROM item_master_data WHERE item_name = ? LIMIT 1', [
            itemName,
          ])
          .timeout(const Duration(seconds: 15));

      if (results.isNotEmpty) {
        final row = results.first;
        return ItemMasterData.fromFetchMySql({
          'item_code': row['item_code'],
          'item_name': row['item_name'],
          'uom': row['uom'],
          'item_rate_amount': row['item_rate_amount'],
          'gst_rate': row['gst_rate'],
          'gst_amount': row['gst_amount'],
          'total_amount': row['total_amount'],
          'mrp_amount': row['mrp_amount'],
          'item_status': row['item_status'],
          'created_at': _parseDateTime(row['created_at']),
          'updated_at': _parseDateTime(row['updated_at']),
        });
      }
      return null;
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout fetching item by name");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching item by name: $e');
      return null;
    }
  }

  Future<List<ItemMasterData>> getAllItems() async {
    if (!await _checkConnection()) return [];

    try {
      final results = await _connection!
          .query('SELECT * FROM item_master_data ORDER BY item_name')
          .timeout(const Duration(seconds: 15));

      return results.map((row) {
        return ItemMasterData.fromFetchMySql({
          'item_code': row['item_code'],
          'item_name': row['item_name'],
          'uom': row['uom'],
          'item_rate_amount': row['item_rate_amount'],
          'gst_rate': row['gst_rate'],
          'gst_amount': row['gst_amount'],
          'total_amount': row['total_amount'],
          'mrp_amount': row['mrp_amount'],
          'item_status': row['item_status'],
          'created_at': _parseDateTime(row['created_at']),
          'updated_at': _parseDateTime(row['updated_at']),
        });
      }).toList();
    } on TimeoutException {
      // ignore: avoid_print
      print("Timeout fetching all items");
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching all items: $e');
      return [];
    }
  }

  // update item by item name
  Future<bool> updateItemMasterDataByItemName(
    String oldItemName,
    ItemMasterData updatedData,
  ) async {
    try {
      // check for duplicate item name
      if (oldItemName != updatedData.itemName) {
        final duplicateCheck = await _connection!.query(
          'SELECT id FROM item_master_data WHERE item_name = ? LIMIT 1',
          [updatedData.itemName],
        );

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      // Update the record
      final result = await _connection!.query(
        '''UPDATE item_master_data 
           SET item_code = ?, item_name = ?, uom = ?, item_rate_amount = ?, 
               gst_rate = ?, gst_amount = ?, total_amount = ?, mrp_amount = ?, 
               item_status = ?, updated_at = ?
           WHERE item_name = ?''',
        [
          updatedData.itemCode,
          updatedData.itemName,
          updatedData.uom,
          updatedData.itemRateAmount,
          updatedData.gstRate,
          updatedData.gstAmount,
          updatedData.totalAmount,
          updatedData.mrpAmount,
          updatedData.itemStatus,
          _formatDateTime(DateTime.now()),
          oldItemName,
        ],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating item by name: $e');
      return false;
    }
  }

  // Close connection
  Future<void> close() async {
    try {
      await _connection?.close().timeout(const Duration(seconds: 5));
      _isInitialized = false;
    } catch (e) {
      // ignore: avoid_print
      print("Error closing connection: $e");
    }
  }

  // Reconnect method
  Future<bool> reconnect() async {
    try {
      await close();
      await initialize();
      return isConnected;
    } catch (e) {
      // ignore: avoid_print
      print("Error reconnecting: $e");
      return false;
    }
  }
}
