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
      host: '10.0.2.2',
      port: 3306,
      user: 'root', // Replace with your MySQL username
      password: r'Rup@@.123$', // Replace with your MySQL password
      db: 'maruti_kirba_database', // Replace with your database name
    );

    _connection = await MySqlConnection.connect(settings);

    // Create table if it doesn't exist
    await _createTableIfNotExists();
  }

  Future<void> _createTableIfNotExists() async {
    await _connection.query('''
      CREATE TABLE IF NOT EXISTS executive_master_data (
        id INT AUTO_INCREMENT PRIMARY KEY,
        executive_name VARCHAR(255) NOT NULL UNIQUE,
        mobile_number VARCHAR(15) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    ''');
  }

  // Add executive data to MySQL
  Future<bool> addExecutiveMasterData(
    ExecutiveMasterData executiveMasterData,
  ) async {
    try {
      await _connection.query(
        'INSERT INTO executive_master_data (executive_name, mobile_number, email, password) VALUES (?, ?, ?, ?)',
        [
          executiveMasterData.executiveName,
          executiveMasterData.mobileNumber,
          executiveMasterData.email,
          executiveMasterData.password,
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
        return ExecutiveMasterData.fromFetchFirestore({
          'executive_name': row['executive_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'password': row['password'],
          'created_at': row['created_at'],
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
        return ExecutiveMasterData.fromFetchFirestore({
          'executive_name': row['executive_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'password': row['password'],
          'created_at': row['created_at'],
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
        return ExecutiveMasterData.fromFetchFirestore({
          'executive_name': row['executive_name'],
          'mobile_number': row['mobile_number'],
          'email': row['email'],
          'password': row['password'],
          'created_at': row['created_at'],
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
           SET executive_name = ?, mobile_number = ?, email = ?, password = ?
           WHERE executive_name = ?''',
        [
          updatedData.executiveName,
          updatedData.mobileNumber,
          updatedData.email,
          updatedData.password,
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
           SET executive_name = ?, mobile_number = ?, email = ?, password = ?
           WHERE mobile_number = ?''',
        [
          updatedData.executiveName,
          updatedData.mobileNumber,
          updatedData.email,
          updatedData.password,
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

  // Close connection
  Future<void> close() async {
    await _connection.close();
  }
}
