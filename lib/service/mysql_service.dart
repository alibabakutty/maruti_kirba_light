import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maruti_kirba_lighting_solutions/models/customer_master_data.dart';
import 'package:maruti_kirba_lighting_solutions/models/item_master_data.dart';
import 'package:mysql1/mysql1.dart';
import 'package:maruti_kirba_lighting_solutions/models/executive_master_data.dart';

class MysqlService {
  static final MysqlService _instance = MysqlService._internal();
  late MySqlConnection _connection;

  factory MysqlService() {
    return _instance;
  }

  MysqlService._internal();

  // Initialize database connection
  Future<void> initialize() async {
    final settings = ConnectionSettings(
      host: dotenv.get('DB_HOST'),
      port: int.parse(dotenv.get('DB_PORT')),
      user: dotenv.get('DB_USER'), // Replace with your MySQL username
      password: dotenv.get('DB_PASSWORD'), // Replace with your MySQL password
      db: dotenv.get('DB_NAME'), // Replace with your database name
    );

    _connection = await MySqlConnection.connect(settings);

    // Create table if it doesn't exist
    await _createTableIfNotExists();
  }

  Future<void> _createTableIfNotExists() async {
    // Executive Master Table
    await _connection.query('''
      CREATE TABLE IF NOT EXISTS executive_master_data (
        id INT AUTO_INCREMENT PRIMARY KEY,
        executive_name VARCHAR(255) NOT NULL UNIQUE,
        mobile_number VARCHAR(15) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NULL
      )
    ''');

    // Customer Master Table
    await _connection.query('''
        CREATE TABLE IF NOT EXISTS customer_master_data (
          id INT AUTO_INCREMENT PRIMARY KEY,
          customer_code VARCHAR(50) NOT NULL UNIQUE,
          customer_name VARCHAR(255) NOT NULL,
          mobile_number VARCHAR(15) NULL,
          email VARCHAR(255) NOT NULL,
          created_at DATETIME NOT NULL,
          updated_at DATETIME NULL
        )
      ''');

    // Item Master Table
    await _connection.query('''
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
      ''');
  }

  String _formatDateTime(DateTime dt) {
    // Format as: YYYY-MM-DD HH:MM:SS
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

  // ========== EXECUTIVE MASTER METHODS ==========

  // Add executive data to MySQL
  Future<bool> addExecutiveMasterData(
    ExecutiveMasterData executiveMasterData,
  ) async {
    try {
      await _connection.query(
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
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding executive master data: $e');
      return false;
    }
  }

  // Fetch executive by executive name
  Future<ExecutiveMasterData?> getExecutiveByExecutiveName(
    String executiveName,
  ) async {
    try {
      final results = await _connection.query(
        'SELECT * FROM executive_master_data WHERE executive_name = ? LIMIT 1',
        [executiveName],
      );

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
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching executive by name: $e');
      return null;
    }
  }

  // Fetch executive by mobile number
  Future<ExecutiveMasterData?> getExecutiveByMobileNumber(
    String mobileNumber,
  ) async {
    try {
      final results = await _connection.query(
        'SELECT * FROM executive_master_data WHERE mobile_number = ? LIMIT 1',
        [mobileNumber],
      );

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
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching executive by mobile: $e');
      return null;
    }
  }

  // Fetch all executives
  Future<List<ExecutiveMasterData>> getAllExecutives() async {
    try {
      final results = await _connection.query(
        'SELECT * FROM executive_master_data ORDER BY executive_name',
      );

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
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching all executives: $e');
      return [];
    }
  }

  // Update executive by executive name
  Future<bool> updateExecutiveMasterDataByExecutiveName(
    String oldExecutiveName,
    ExecutiveMasterData updatedData,
  ) async {
    try {
      // Check for duplicate executive name
      if (oldExecutiveName != updatedData.executiveName) {
        final duplicateCheck = await _connection.query(
          'SELECT id FROM executive_master_data WHERE executive_name = ? LIMIT 1',
          [updatedData.executiveName],
        );

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      // Update the record
      final result = await _connection.query(
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
      );

      return result.affectedRows! > 0;
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
        final duplicateCheck = await _connection.query(
          'SELECT id FROM executive_master_data WHERE mobile_number = ? LIMIT 1',
          [updatedData.mobileNumber],
        );

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      // Update the record
      final result = await _connection.query(
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

  // Add customer data to MySQL
  Future<bool> addCustomerMasterData(
    CustomerMasterData customerMasterData,
  ) async {
    try {
      await _connection.query(
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
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding customer master data: $e');
      return false;
    }
  }

  // Fetch customer by customer name
  Future<CustomerMasterData?> getCustomerByCustomerName(
    String customerName,
  ) async {
    try {
      final results = await _connection.query(
        'SELECT * FROM customer_master_data WHERE customer_name = ? LIMIT 1',
        [customerName],
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
      print('Error fetching customer by name: $e');
      return null;
    }
  }

  // Fetch customer by mobile number
  Future<CustomerMasterData?> getCustomerByMobileNumber(
    String mobileNumber,
  ) async {
    try {
      final results = await _connection.query(
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

  // Fetch all customers
  Future<List<CustomerMasterData>> getAllCustomers() async {
    try {
      final results = await _connection.query(
        'SELECT * FROM customer_master_data ORDER BY customer_name',
      );

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
        final duplicateCheck = await _connection.query(
          'SELECT id FROM customer_master_data WHERE customer_name = ? LIMIT 1',
          [updatedData.customerName],
        );

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      // Update the record
      final result = await _connection.query(
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

  // Add item data to MySQL
  Future<bool> addItemMasterData(ItemMasterData itemMasterData) async {
    try {
      await _connection.query(
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
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding item master data: $e');
      return false;
    }
  }

  // Fetch item by item name
  Future<ItemMasterData?> getItemByItemName(String itemName) async {
    try {
      final results = await _connection.query(
        'SELECT * FROM item_master_data WHERE item_name = ? LIMIT 1',
        [itemName],
      );

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
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching item by name: $e');
      return null;
    }
  }

  // Fetch all items
  Future<List<ItemMasterData>> getAllItems() async {
    try {
      final results = await _connection.query(
        'SELECT * FROM item_master_data ORDER BY item_name',
      );

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
        final duplicateCheck = await _connection.query(
          'SELECT id FROM item_master_data WHERE item_name = ? LIMIT 1',
          [updatedData.itemName],
        );

        if (duplicateCheck.isNotEmpty) {
          return false;
        }
      }

      // Update the record
      final result = await _connection.query(
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
    await _connection.close();
  }
}
