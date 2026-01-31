import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// Emergency Contact Model
class EmergencyContact {
  final String id;
  String name;
  String phone;
  String relation;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });
}

/// E-Contact Screen - Manage emergency contacts
class EContactScreen extends ConsumerStatefulWidget {
  const EContactScreen({super.key});

  @override
  ConsumerState<EContactScreen> createState() => _EContactScreenState();
}

class _EContactScreenState extends ConsumerState<EContactScreen> {
  final List<EmergencyContact> _contacts = [];
  
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    // In a real app, load from database/API
    // For demo, initialize with empty slots
    setState(() {
      _contacts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryRed.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryRed,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add up to 5 emergency contacts. They will receive SOS alerts when you raise an emergency.',
                      style: TextStyle(
                        color: AppTheme.neutralGray.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            
            const SizedBox(height: 24),
            
            // Contact Slots
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                final hasContact = index < _contacts.length;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: hasContact
                      ? _buildContactCard(_contacts[index], index)
                      : _buildEmptyContactSlot(index),
                ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: -0.2, end: 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralGray,
                      ),
                    ),
                    Text(
                      contact.relation,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutralGray.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppTheme.primaryRed, size: 20),
                onPressed: () => _editContact(contact, index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.primaryRed, size: 20),
                onPressed: () => _deleteContact(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, color: AppTheme.primaryRed, size: 16),
              const SizedBox(width: 8),
              Text(
                '+91 ${contact.phone}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutralGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContactSlot(int index) {
    return GestureDetector(
      onTap: () => _addContact(index),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.neutralGray.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.neutralGray.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: AppTheme.neutralGray.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Contact ${index + 1}',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutralGray.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addContact(int index) async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => _ContactDialog(contactIndex: index + 1),
    );
    
    if (result != null) {
      setState(() {
        _contacts.add(result);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact added successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _editContact(EmergencyContact contact, int index) async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => _ContactDialog(
        contact: contact,
        contactIndex: index + 1,
      ),
    );
    
    if (result != null) {
      setState(() {
        _contacts[index] = result;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact updated successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _deleteContact(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _contacts.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact deleted successfully!'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }
}

/// Contact Dialog for Add/Edit
class _ContactDialog extends StatefulWidget {
  final EmergencyContact? contact;
  final int contactIndex;

  const _ContactDialog({
    this.contact,
    required this.contactIndex,
  });

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _relationController = TextEditingController(text: widget.contact?.relation ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryRed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: AppTheme.primaryRed),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length != 10) {
                    return 'Phone must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Relation (e.g., Father, Mother)',
                  prefixIcon: Icon(Icons.family_restroom, color: AppTheme.primaryRed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter relation';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveContact,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveContact() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final contact = EmergencyContact(
      id: widget.contact?.id ?? DateTime.now().toString(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relation: _relationController.text.trim(),
    );
    
    Navigator.pop(context, contact);
  }
}
