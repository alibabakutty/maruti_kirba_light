class CustomerMasterData {
  final int? id;
  final String customerCode;
  final String customerName;
  final String? mobileNumber;
  final String? email;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomerMasterData({
    this.id,
    required this.customerCode,
    required this.customerName,
    this.mobileNumber,
    this.email,
    required this.createdAt,
    this.updatedAt,
  });

  // convert data from MySql to customerName Master object
  factory CustomerMasterData.fromJson(Map<String, dynamic> data) {
    return CustomerMasterData(
      id: data['id'],
      customerCode: data['customer_code'] ?? '',
      customerName: data['customer_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      email: data['email'] ?? '',
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  // Helper method to parse DateTime safely
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is DateTime) {
      return dateValue;
    }

    try {
      if (dateValue is String && dateValue.isNotEmpty) {
        return DateTime.parse(dateValue);
      }
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
    }

    return null;
  }

  // convert Customer master data object to MySql data
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customerCode': customerCode,
      'customerName': customerName,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (email != null) 'email': email,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
