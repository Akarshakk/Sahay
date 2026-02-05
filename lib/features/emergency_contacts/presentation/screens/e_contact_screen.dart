import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// E-Contact Screen - Manage emergency contacts
class EContactScreen extends ConsumerStatefulWidget {
  const EContactScreen({super.key});

  @override
  ConsumerState<EContactScreen> createState() => _EContactScreenState();
}

class _EContactScreenState extends ConsumerState<EContactScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final contacts = user?.emergencyContacts ?? [];

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
                final hasContact = index < contacts.length;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: hasContact
                      ? _buildContactCard(contacts[index], index)
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
    // Request contacts permission
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission is required to add emergency contacts'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
      return;
    }

    List<Contact> contactsWithPhones = [];
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
      
      // Get all contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      // Filter contacts that have phone numbers
      contactsWithPhones = contacts.where((c) => c.phones.isNotEmpty).toList();
      
      // Dismiss loading
      if (mounted) Navigator.of(context).pop();
      
    } catch (e) {
      // Dismiss loading if still showing
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
      return;
    }
    
    if (contactsWithPhones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No contacts with phone numbers found'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
      return;
    }
    
    // Show contact picker dialog
    final selectedContact = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ContactPickerSheet(contacts: contactsWithPhones),
    );
    
    if (selectedContact == null || !mounted) return;
    
    // Get phone number (remove non-digits, take last 10 digits)
    String phoneNumber = selectedContact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneNumber.length > 10) {
      phoneNumber = phoneNumber.substring(phoneNumber.length - 10);
    }
    
    // Get contact name
    final contactName = selectedContact.displayName;
    
    // Show dialog to enter relation only
    final relation = await showDialog<String>(
      context: context,
      builder: (context) => _RelationDialog(
        contactName: contactName,
        phoneNumber: phoneNumber,
      ),
    );
    
    if (relation != null && relation.isNotEmpty && mounted) {
      final newContact = EmergencyContact(
        name: contactName,
        phone: phoneNumber,
        relation: relation,
      );
      await _updateContacts((currentContacts) => [...currentContacts, newContact]);
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
      await _updateContacts((currentContacts) {
        final newContacts = List<EmergencyContact>.from(currentContacts);
        newContacts[index] = result;
        return newContacts;
      });
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
      await _updateContacts((currentContacts) {
        final newContacts = List<EmergencyContact>.from(currentContacts);
        newContacts.removeAt(index);
        return newContacts;
      });
    }
  }

  Future<void> _updateContacts(List<EmergencyContact> Function(List<EmergencyContact>) updateFn) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final currentContacts = user.emergencyContacts ?? [];
    final updatedContacts = updateFn(currentContacts);

    try {
      // Map back to JSON for API update
      final contactsJson = updatedContacts.map((c) => {
        'name': c.name,
        'phone': c.phone,
        'relation': c.relation,
      }).toList();

      await ref.read(authControllerProvider.notifier).updateUser({
        'emergencyContacts': contactsJson,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update contacts: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
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
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relation: _relationController.text.trim(),
    );
    
    Navigator.pop(context, contact);
  }
}

/// Relation Dialog - Only asks for relation after contact is picked
class _RelationDialog extends StatefulWidget {
  final String contactName;
  final String phoneNumber;

  const _RelationDialog({
    required this.contactName,
    required this.phoneNumber,
  });

  @override
  State<_RelationDialog> createState() => _RelationDialogState();
}

class _RelationDialogState extends State<_RelationDialog> {
  final _relationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final List<String> _commonRelations = [
    'Father',
    'Mother',
    'Spouse',
    'Brother',
    'Sister',
    'Friend',
    'Colleague',
    'Neighbor',
  ];

  @override
  void dispose() {
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Relation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show selected contact info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.contactName.isNotEmpty 
                            ? widget.contactName[0].toUpperCase() 
                            : '?',
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
                          widget.contactName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '+91 ${widget.phoneNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Select or enter relation:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 12),
            
            // Quick select relations
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonRelations.map((relation) {
                final isSelected = _relationController.text == relation;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _relationController.text = relation;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryRed 
                          : AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      relation,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.primaryRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Or type custom relation
            TextFormField(
              controller: _relationController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Or type relation',
                prefixIcon: const Icon(Icons.family_restroom, color: AppTheme.primaryRed),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter or select a relation';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _relationController.text.trim());
            }
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
          child: const Text('Add Contact'),
        ),
      ],
    );
  }
}

/// Contact Picker Sheet - Shows searchable list of contacts
class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerSheet({required this.contacts});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts
            .where((c) => c.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralGray,
                ),
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            
            // Contact list
            Expanded(
              child: _filteredContacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No contacts found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final phone = contact.phones.isNotEmpty 
                            ? contact.phones.first.number 
                            : 'No phone';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                            child: Text(
                              contact.displayName.isNotEmpty 
                                  ? contact.displayName[0].toUpperCase() 
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            contact.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            phone,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          onTap: () => Navigator.pop(context, contact),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}