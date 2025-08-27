class CustomerMasterData {
  final String customerCode;
  final String customerName;
  final String? mobileNumber;
  final String? email;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomerMasterData({
    required this.customerCode,
    required this.customerName,
    this.mobileNumber,
    this.email,
    required this.createdAt,
    this.updatedAt,
  });

  // convert data from MySql to customerName Master object
  factory CustomerMasterData.fromFetchMySql(Map<String, dynamic> data) {
    return CustomerMasterData(
      customerCode: data['customer_code'] ?? '',
      customerName: data['customer_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['created_at'] is DateTime
          ? data['created_at']
          : DateTime.parse(data['created_at'].toString()),
      updatedAt: data['updated_at'] is DateTime
          ? data['updated_at']
          : DateTime.parse(data['updated_at'].toString()),
    );
  }

  String? get id => null;

  // convert Customer master data object to MySql data
  Map<String, dynamic> toStoreMySql() {
    return {
      'customer_code': customerCode,
      'customer_name': customerName,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (email != null) 'email': email,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
