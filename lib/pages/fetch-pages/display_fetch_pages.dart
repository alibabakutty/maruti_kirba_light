import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maruti_kirba_lighting_solutions/models/customer_master_data.dart';
import 'package:maruti_kirba_lighting_solutions/models/executive_master_data.dart';
import 'package:maruti_kirba_lighting_solutions/models/item_master_data.dart';
import 'package:maruti_kirba_lighting_solutions/service/api_service.dart';
import 'package:maruti_kirba_lighting_solutions/service/mysql_service.dart';
import 'package:provider/provider.dart';

class DisplayFetchPage extends StatefulWidget {
  final String masterType;

  const DisplayFetchPage({super.key, required this.masterType});

  @override
  State<DisplayFetchPage> createState() => _DisplayFetchPageState();
}

class _DisplayFetchPageState extends State<DisplayFetchPage> {
  List<ItemMasterData> items = [];
  List<ExecutiveMasterData> executives = [];
  List<CustomerMasterData> customers = [];

  bool isLoading = false;
  bool hasFetchedItems = false;
  bool hasFetchedExecutives = false;
  bool hasFetchedCustomers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      switch (widget.masterType) {
        case 'item':
          await _fetchItems();
          break;
        case 'executive':
          await _fetchExecutives();
          break;
        case 'customer':
          await _fetchCustomers();
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchItems() async {
    try {
      final mysqlService = Provider.of<MysqlService>(context, listen: false);
      final List<ItemMasterData> itemList = await mysqlService.getAllItems();

      if (!mounted) return;

      setState(() {
        items = itemList;
        hasFetchedItems = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching items: $e')));
    }
  }

  Future<void> _fetchExecutives() async {
    try {
      final mysqlService = Provider.of<MysqlService>(context, listen: false);
      final List<ExecutiveMasterData> executiveList = await mysqlService
          .getAllExecutives();

      if (!mounted) return;

      setState(() {
        executives = executiveList;
        hasFetchedExecutives = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching executives: $e')));
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      // Use ApiService to fetch customers
      final data = await ApiService.getAllCustomers();

      if (!mounted) return;

      // Convert API response to List<CustomerMasterData> objects
      final List<CustomerMasterData>
      customerList = data.map<CustomerMasterData>((custData) {
        // Map camelCase API fields to snake_case fields expected by fromJson
        return CustomerMasterData.fromJson({
          'id': custData['id'],
          'customer_code': custData['customerCode'],
          'customer_name': custData['customerName'],
          'mobile_number': custData['mobileNumber'],
          'email': custData['email'],
          'created_at': custData['createdAt'],
          'updated_at': custData['updatedAt'],
        });
      }).toList();

      setState(() {
        customers = customerList;
        hasFetchedCustomers = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching customers: $e')));
    }
  }

  void _navigateToViewPage(dynamic value) {
    switch (widget.masterType) {
      case 'item':
        context.go(
          '/item_master',
          extra: {'item_name': value, 'isDisplayMode': true},
        );
        break;
      case 'executive':
        context.go(
          '/executive_master',
          extra: {'executive_name': value, 'isDisplayMode': true},
        );
        break;
      case 'customer':
        context.go(
          '/customer_master',
          extra: {'customer_name': value, 'isDisplayMode': true},
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: widget.masterType),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(),
            ),
    );
  }

  String _getPageTitle() {
    switch (widget.masterType) {
      case 'item':
        return 'ITEM MASTER';
      case 'executive':
        return 'EXECUTIVE MASTER';
      case 'customer':
        return 'CUSTOMER MASTER';
      default:
        return 'Master Data';
    }
  }

  Widget _buildContent() {
    switch (widget.masterType) {
      case 'item':
        // Convert ItemMasterData list to map list
        final itemMaps = items
            .map(
              (item) => {
                'code': item.itemCode,
                'name': item.itemName,
                'uom': item.uom,
                'amount': item.totalAmount,
                'status': item.itemStatus,
              },
            )
            .toList();
        return _buildMasterList(
          header: const ['Code', 'Item Name', 'UOM', 'Rate'],
          data: itemMaps,
          nameKey: 'name',
          secondaryKey: 'code',
          tertiaryKey: 'uom',
          quaternaryKey: 'amount', // Add this for fourth column
          statusKey: 'status',
          icon: Icons.fastfood,
          valueFormatter: (value) => '₹ ${value.toStringAsFixed(2)}',
        );
      case 'executive':
        // Convert ExecutiveMasterData list to Map list
        final executiveMaps = executives
            .map(
              (executive) => {
                'name': executive.executiveName,
                'contact': executive.mobileNumber,
                'email': executive.email,
              },
            )
            .toList();
        return _buildMasterList(
          header: const ['Executive Name', 'Contact'],
          data: executiveMaps,
          nameKey: 'name',
          secondaryKey: 'contact',
          icon: Icons.business,
        );
      case 'customer':
        // Convert CustomerMasterData list to Map list
        final customerMaps = customers
            .map(
              (customer) => {
                'name': customer.customerName,
                'mobile': customer.mobileNumber,
                'email': customer.email,
              },
            )
            .toList();
        return _buildMasterList(
          header: const ['Customer Name', 'Mobile', 'Email'],
          data: customerMaps,
          nameKey: 'name',
          secondaryKey: 'mobile',
          tertiaryKey: 'email',
          icon: Icons.person,
        );
      default:
        return const Center(child: Text('Select a master type'));
    }
  }

  Widget _buildMasterList({
    required List<String> header,
    required List<Map<String, dynamic>> data,
    required String nameKey,
    required String secondaryKey,
    String? tertiaryKey,
    String? quaternaryKey,
    String? statusKey,
    required IconData icon,
    String Function(dynamic)? valueFormatter,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No ${widget.masterType}s available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      );
    }

    // Determine column flex values based on master type
    final int firstFlex = widget.masterType == 'item' ? 1 : 2;
    final int secondFlex = widget.masterType == 'item' ? 3 : 2;
    final int thirdFlex = widget.masterType == 'customer' ? 3 : 1;
    final int fourthFlex = 1;

    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              // First column
              Flexible(
                flex: firstFlex,
                child: Text(
                  header[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Second column
              Flexible(
                flex: secondFlex,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    header[1],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Third column (if exists)
              if (header.length > 2)
                Flexible(
                  flex: thirdFlex,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      header[2],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              // Fourth column (if exists)
              if (header.length > 3)
                Flexible(
                  flex: fourthFlex,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      header[3],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Data List
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final isActive = statusKey != null
                  ? (item[statusKey] as bool? ?? false)
                  : true;

              return Container(
                margin: const EdgeInsets.only(bottom: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: InkWell(
                  onTap: () => _navigateToViewPage(item[nameKey]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: [
                        // First column
                        Flexible(
                          flex: firstFlex,
                          child: Text(
                            widget.masterType == 'item'
                                ? item[secondaryKey].toString()
                                : item[nameKey].toString(),
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Second column
                        Flexible(
                          flex: secondFlex,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              widget.masterType == 'item'
                                  ? item[nameKey].toString()
                                  : item[secondaryKey].toString(),
                              style: TextStyle(
                                color: isActive ? Colors.black : Colors.grey,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Third column (if exists)
                        if (tertiaryKey != null)
                          Flexible(
                            flex: thirdFlex,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                header.length > 3
                                    ? item[tertiaryKey].toString()
                                    : valueFormatter != null
                                    ? valueFormatter(item[tertiaryKey])
                                    : item[tertiaryKey].toString(),
                                style: TextStyle(
                                  color: isActive ? Colors.black : Colors.grey,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        // Fourth column (if exists)
                        if (quaternaryKey != null)
                          Flexible(
                            flex: fourthFlex,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                valueFormatter != null
                                    ? valueFormatter(item[quaternaryKey])
                                    : item[quaternaryKey].toString(),
                                style: TextStyle(
                                  color: isActive ? Colors.black : Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
