import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../providers/farmer_provider.dart';
import 'farmer_form_dialog.dart';

class FarmerManagementScreen extends StatefulWidget {
  const FarmerManagementScreen({super.key});

  @override
  State<FarmerManagementScreen> createState() => _FarmerManagementScreenState();
}

class _FarmerManagementScreenState extends State<FarmerManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().fetchFarmers();
    });
  }

  Future<void> _openAddFarmerDialog() async {
    final newFarmer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (_) => const FarmerFormDialog()),
    );

    if (newFarmer != null && mounted) {
      final success = await context.read<FarmerProvider>().addFarmer(newFarmer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Farmer created successfully!' : 'Failed to create farmer',
            ),
            backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditFarmerDialog(Customer farmer) async {
    final updatedFarmer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (_) => FarmerFormDialog(farmer: farmer)),
    );

    if (updatedFarmer != null && mounted) {
      final success = await context
          .read<FarmerProvider>()
          .updateFarmer(farmer.id, updatedFarmer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Farmer updated successfully!' : 'Failed to update farmer',
            ),
            backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteFarmer(Customer farmer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Farmer'),
        content: Text('Are you sure you want to delete ${farmer.name} (${farmer.id})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<FarmerProvider>().deleteFarmer(farmer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Farmer deleted successfully!' : 'Failed to delete farmer',
            ),
            backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FarmerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refreshFarmers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFarmerDialog,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Farmer'),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshFarmers(),
        color: const Color(0xFF2E7D32),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(FarmerProvider provider) {
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
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading farmers:\n${provider.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.fetchFarmers(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.farmers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 70, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No farmers found in backend database.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openAddFarmerDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Farmer'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: provider.farmers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final farmer = provider.farmers[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  child: Text(
                    farmer.initials,
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${farmer.name} (${farmer.id})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text('${farmer.village}, ${farmer.district}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text('Phone: ${farmer.phone}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text('${farmer.items.length} items', style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _openEditFarmerDialog(farmer),
                  tooltip: 'Edit Farmer',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteFarmer(farmer),
                  tooltip: 'Delete Farmer',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
