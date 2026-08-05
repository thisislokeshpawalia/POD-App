import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';

class FarmerFormDialog extends StatefulWidget {
  final Customer? farmer; // Null when creating new farmer, non-null when updating

  const FarmerFormDialog({super.key, this.farmer});

  @override
  State<FarmerFormDialog> createState() => _FarmerFormDialogState();
}

class _FarmerFormDialogState extends State<FarmerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _villageController;
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _pinCodeController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _otpController;

  final List<_ItemControllerGroup> _itemGroups = [];

  @override
  void initState() {
    super.initState();
    final f = widget.farmer;
    _nameController = TextEditingController(text: f?.name ?? '');
    _phoneController = TextEditingController(text: f?.phone ?? '');
    _villageController = TextEditingController(text: f?.village ?? '');
    _addressController = TextEditingController(text: f?.address ?? '');
    _districtController = TextEditingController(text: f?.district ?? 'Damoh');
    _pinCodeController = TextEditingController(text: f?.pinCode ?? '');
    _latController = TextEditingController(text: f != null ? f.latitude.toString() : '23.2599');
    _lngController = TextEditingController(text: f != null ? f.longitude.toString() : '77.4126');
    _otpController = TextEditingController(text: f?.otp ?? '1234');

    if (f != null && f.items.isNotEmpty) {
      for (final item in f.items) {
        _itemGroups.add(_ItemControllerGroup(
          name: item.name,
          quantity: item.quantity.toString(),
          unit: item.unit,
        ));
      }
    } else {
      _itemGroups.add(_ItemControllerGroup(name: 'Cattle Feed', quantity: '25', unit: 'kg'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _otpController.dispose();
    for (final group in _itemGroups) {
      group.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itemGroups.add(_ItemControllerGroup(name: '', quantity: '1', unit: 'kg'));
    });
  }

  void _removeItem(int index) {
    if (_itemGroups.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one delivery item is required')),
      );
      return;
    }
    setState(() {
      _itemGroups[index].dispose();
      _itemGroups.removeAt(index);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final items = _itemGroups.map((g) {
      return DeliveryItem(
        name: g.nameController.text.trim(),
        quantity: double.tryParse(g.quantityController.text.trim()) ?? 1.0,
        unit: g.unitController.text.trim(),
      );
    }).toList();

    final result = Customer(
      id: widget.farmer?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      village: _villageController.text.trim(),
      address: _addressController.text.trim(),
      district: _districtController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
      status: widget.farmer?.status ?? DeliveryStatus.pending,
      latitude: double.tryParse(_latController.text.trim()) ?? 23.2599,
      longitude: double.tryParse(_lngController.text.trim()) ?? 77.4126,
      otp: _otpController.text.trim().isEmpty ? '1234' : _otpController.text.trim(),
      items: items,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.farmer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Update Farmer' : 'Add New Farmer'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              const Text(
                'Farmer Personal Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Farmer Name *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().length != 10) ? '10-digit phone required' : null,
              ),
              const SizedBox(height: 12),

              // Address Details
              const Text(
                'Location Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _villageController,
                decoration: const InputDecoration(labelText: 'Village *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Village is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address / House No. *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'District *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _pinCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Pincode *', border: OutlineInputBorder(), counterText: ''),
                      validator: (v) => (v == null || v.trim().length != 6) ? '6 digits required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid Lat' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid Lng' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Delivery Verification OTP *',
                  hintText: 'default 1234',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().length != 4) ? '4-digit OTP required' : null,
              ),
              const SizedBox(height: 20),

              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Delivery Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(_itemGroups.length, (index) {
                final group = _itemGroups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: group.nameController,
                                decoration: const InputDecoration(labelText: 'Item Name *', border: OutlineInputBorder()),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Item name required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: group.quantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Qty *', border: OutlineInputBorder()),
                                validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0)
                                    ? 'Invalid'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: group.unitController,
                                decoration: const InputDecoration(labelText: 'Unit *', border: OutlineInputBorder()),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEditing ? 'Update Farmer' : 'Create Farmer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemControllerGroup {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  _ItemControllerGroup({
    required String name,
    required String quantity,
    required String unit,
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity),
        unitController = TextEditingController(text: unit);

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}
