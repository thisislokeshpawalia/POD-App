import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/auth_provider.dart';
import '../providers/farmer_provider.dart';
import 'customer_detail_screen.dart';
import 'farmer/farmer_management_screen.dart';

enum CustomerFilter { all, pending, delivered }

class CustomerListScreen extends StatefulWidget {
  final List<Customer>? customers;
  final void Function(String customerId)? onCustomerDelivered;

  const CustomerListScreen({
    super.key,
    this.customers,
    this.onCustomerDelivered,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().fetchFarmers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEE, dd MMM yyyy').format(DateTime.now());
    final farmerProvider = context.watch<FarmerProvider>();
    final authProvider = context.watch<AuthProvider>();
    final filter = farmerProvider.filter;
    final customersList = farmerProvider.filteredFarmers;
    final deliveredCount = farmerProvider.deliveredCount;
    final totalCount = farmerProvider.totalCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authProvider.partner != null
                  ? 'Hello, ${authProvider.partner!.name}'
                  : 'Today\'s Deliveries',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              today,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$deliveredCount/$totalCount Delivered',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: RefreshIndicator(
        onRefresh: () => context.read<FarmerProvider>().refreshFarmers(),
        color: const Color(0xFF2E7D32),
        child: Column(
          children: [
            // Header Action Card for Farmer Management
            Container(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FarmerManagementScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.people_alt, color: Color(0xFF2E7D32)),
                      label: const Text(
                        'Farmer Management (CRUD)',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: filter == CustomerFilter.all,
                    onSelected: () => farmerProvider.setFilter(CustomerFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pending',
                    selected: filter == CustomerFilter.pending,
                    onSelected: () => farmerProvider.setFilter(CustomerFilter.pending),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Delivered',
                    selected: filter == CustomerFilter.delivered,
                    onSelected: () => farmerProvider.setFilter(CustomerFilter.delivered),
                  ),
                ],
              ),
            ),

            // List Content
            Expanded(
              child: _buildListContent(farmerProvider, customersList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(FarmerProvider provider, List<Customer> customersList) {
    if (provider.isLoading && provider.farmers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (provider.errorMessage != null && provider.farmers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Error loading deliveries:\n${provider.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchFarmers(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (customersList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Text(
              'No customers in this category',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: customersList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final customer = customersList[index];
        return _CustomerTile(
          customer: customer,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(
                  customer: customer,
                  onCustomerDelivered: (id) async {
                    if (widget.onCustomerDelivered != null) {
                      widget.onCustomerDelivered!(id);
                    }
                    await provider.markDelivered(id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final partner = authProvider.partner;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                partner?.name.isNotEmpty == true ? partner!.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
            ),
            accountName: Text(partner?.name ?? 'Delivery Agent', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(partner?.phone ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Aadhaar Number'),
            subtitle: Text(partner?.aadhaar ?? 'Not provided'),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); // close drawer
              authProvider.logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerTile({
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivered = customer.isDelivered;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                backgroundImage: (customer.photoUrls != null && customer.photoUrls!.isNotEmpty)
                    ? NetworkImage(customer.photoUrls!.first)
                    : null,
                child: (customer.photoUrls != null && customer.photoUrls!.isNotEmpty)
                    ? null
                    : Text(
                        customer.initials,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.village,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDelivered ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDelivered ? Colors.green.shade300 : Colors.orange.shade300,
                  ),
                ),
                child: Text(
                  isDelivered ? 'Delivered' : 'Pending',
                  style: TextStyle(
                    color: isDelivered ? Colors.green.shade700 : Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
