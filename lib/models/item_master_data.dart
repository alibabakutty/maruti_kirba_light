class ItemMasterData {
  final int itemCode;
  final String itemName;
  final String uom;
  final double itemRateAmount;
  final double gstRate;
  final double gstAmount;
  final double totalAmount;
  final double mrpAmount;
  final bool itemStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ItemMasterData({
    required this.itemCode,
    required this.itemName,
    this.uom = 'Nos',
    required this.itemRateAmount,
    this.gstRate = 0.0,
    this.gstAmount = 0.0,
    this.totalAmount = 0.0,
    this.mrpAmount = 0.0,
    required this.itemStatus,
    required this.createdAt,
    this.updatedAt,
  });

  // convert data from MySql to a ItemMasterData object
  factory ItemMasterData.fromFetchMySql(Map<String, dynamic> data) {
    return ItemMasterData(
      itemCode: data['item_code'] ?? 0,
      itemName: data['item_name'] ?? '',
      uom: data['uom'] ?? '',
      itemRateAmount: data['item_rate_amount'] ?? 0.0,
      gstRate: data['gst_rate'] ?? 0.0,
      gstAmount: data['gst_amount'] ?? 0.0,
      totalAmount: data['total_amount'] ?? 0.0,
      mrpAmount: data['mrp_amount'] ?? 0.0,
      // Convert integer to boolean
      itemStatus: (data['item_status'] == 1) || (data['item_status'] == true),
      createdAt: data['created_at'] is DateTime
          ? data['created_at']
          : DateTime.parse(data['created_at'].toString()),
      updatedAt: data['updated_at'] is DateTime
          ? data['updated_at']
          : DateTime.parse(data['updated_at'].toString()),
    );
  }

  // convert a itemmasterdata object into a map object for MySql
  Map<String, dynamic> toStoreMySql() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'uom': uom,
      'item_rate_amount': itemRateAmount,
      'gst_rate': gstRate,
      'gst_amount': gstAmount,
      'total_amount': totalAmount,
      'mrp_amount': mrpAmount,
      'item_status': itemStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
