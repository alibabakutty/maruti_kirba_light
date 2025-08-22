class ExecutiveMasterData {
  final String executiveName;
  final String mobileNumber;
  final String email;
  final String password;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExecutiveMasterData({
    required this.executiveName,
    required this.mobileNumber,
    required this.email,
    required this.password,
    required this.createdAt,
    this.updatedAt,
  });

  // convert data from firestore to ExecutiveName Master object
  factory ExecutiveMasterData.fromFetchMySql(Map<String, dynamic> data) {
    return ExecutiveMasterData(
      executiveName: data['executive_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      createdAt: data['created_at'] is DateTime
          ? data['created_at']
          : DateTime.parse(data['created_at'].toString()),
      updatedAt: data['updated_at'] is DateTime
          ? data['updated_at']
          : DateTime.parse(data['updated_at'].toString()),
    );
  }

  // convert Executive Master Master Data object to firestore data
  Map<String, dynamic> toStoreMySql() {
    return {
      'executive_name': executiveName,
      'mobile_number': mobileNumber,
      'email': email,
      'password': password,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
