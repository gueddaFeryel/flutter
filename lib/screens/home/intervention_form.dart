import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medical_intervention_app/models/intervention.dart';
import 'package:medical_intervention_app/models/medical_staff.dart';
import 'package:medical_intervention_app/models/patient.dart';
import 'package:medical_intervention_app/services/auth_service.dart';
import 'package:medical_intervention_app/services/intervention_service.dart';
import 'package:provider/provider.dart';

class InterventionFormScreen extends StatefulWidget {
  static const routeName = '/intervention-form';

  @override
  _InterventionFormScreenState createState() => _InterventionFormScreenState();
}

class _InterventionFormScreenState extends State<InterventionFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _patientFirstNameController = TextEditingController();
  final _patientLastNameController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _patientAddressController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _patientBirthDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedType = '';
  String _selectedNationality = 'FR';
  bool _isLoading = false;
  bool _isLoadingStaff = false;
  bool _isNewPatient = true;
  bool _isSearchingPatients = false;
  String _errorMessage = '';
  String _successMessage = '';
  
  List<MedicalStaff> _doctors = [];
  List<MedicalStaff> _anesthetists = [];
  List<MedicalStaff> _nurses = [];
  List<Patient> _foundPatients = [];
  
  int? _selectedDoctor;
  int? _selectedAnesthetist;
  int? _selectedNurse;
  int? _selectedPatientId;

  List<String> _interventionTypes = [];
  
  final List<Map<String, String>> _nationalities = [
    {'code': 'FR', 'name': 'France'},
    {'code': 'US', 'name': 'United States'},
    {'code': 'UK', 'name': 'United Kingdom'},
    {'code': 'DE', 'name': 'Germany'},
    {'code': 'TN', 'name': 'Tunisia'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'IN', 'name': 'India'},
    {'code': 'BR', 'name': 'Brazil'},
  ];
  
  late AnimationController _animationController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _tabController = TabController(length: 3, vsync: this);
    _fetchInterventionTypes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _patientFirstNameController.dispose();
    _patientLastNameController.dispose();
    _patientPhoneController.dispose();
    _patientAddressController.dispose();
    super.dispose();
  }

  Future<void> _fetchInterventionTypes() async {
    try {
      final interventionService = Provider.of<InterventionService>(context, listen: false);
      final types = await interventionService.getInterventionTypes();
      setState(() {
        _interventionTypes = types;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load intervention types: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchMedicalStaff() async {
    if (_selectedType.isEmpty) return;
    
    setState(() {
      _isLoadingStaff = true;
      _errorMessage = '';
    });
    
    try {
      final interventionService = Provider.of<InterventionService>(context, listen: false);
      
      final doctors = await interventionService.getMedicalStaffByRole('MEDECIN');
      final anesthetists = await interventionService.getMedicalStaffByRole('ANESTHESISTE');
      final nurses = await interventionService.getMedicalStaffByRole('INFIRMIER');
      
      setState(() {
        _doctors = doctors;
        _anesthetists = anesthetists;
        _nurses = nurses;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load medical team: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingStaff = false;
      });
    }
  }

  Future<void> _searchPatients(String query) async {
    if (query.length < 2) {
      setState(() {
        _foundPatients = [];
      });
      return;
    }
    
    setState(() {
      _isSearchingPatients = true;
      _errorMessage = '';
    });
    
    try {
      final interventionService = Provider.of<InterventionService>(context, listen: false);
      final patients = await interventionService.searchPatients(query);
      setState(() {
        _foundPatients = patients.whereType<Patient>().toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search patients: ${e.toString()}';
        _foundPatients = [];
      });
    } finally {
      setState(() {
        _isSearchingPatients = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _patientBirthDate = picked;
      });
    }
  }

  bool _validateCurrentTab() {
    setState(() {
      _errorMessage = '';
    });

    if (_tabController.index == 0) {
      if (_selectedDate == null) {
        setState(() => _errorMessage = 'Date is required');
        return false;
      }
      if (_selectedType.isEmpty) {
        setState(() => _errorMessage = 'Intervention type is required');
        return false;
      }
    } else if (_tabController.index == 1 && _isNewPatient) {
      if (_patientFirstNameController.text.isEmpty) {
        setState(() => _errorMessage = 'Patient first name is required');
        return false;
      }
      if (_patientLastNameController.text.isEmpty) {
        setState(() => _errorMessage = 'Patient last name is required');
        return false;
      }
      if (_patientPhoneController.text.isNotEmpty) {
        final phonePattern = _getPhonePattern(_selectedNationality);
        if (!RegExp(phonePattern).hasMatch(_patientPhoneController.text)) {
          setState(() => _errorMessage = 'Invalid phone number format for selected nationality');
          return false;
        }
      }
    }
    return true;
  }

  String _getPhonePattern(String nationality) {
    switch (nationality) {
      case 'FR': return r'^\+33[1-9]\d{8}$';
      case 'US': return r'^\+1\d{10}$';
      case 'UK': return r'^\+44\d{10}$';
      case 'DE': return r'^\+49\d{10,11}$';
      case 'TN': return r'^\+216\d{8}$';
      case 'CA': return r'^\+1\d{10}$';
      case 'AU': return r'^\+61[1-9]\d{8}$';
      case 'IN': return r'^\+91\d{10}$';
      case 'BR': return r'^\+55\d{10,11}$';
      default: return r'^\+?\d{6,15}$';
    }
  }

  void _handleNextTab() {
    if (!_validateCurrentTab()) return;
    
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  void _handlePreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentTab()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final interventionService = Provider.of<InterventionService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final currentUser = await authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Please login to submit a request');
      }

      // Prepare medical team with full details
      final equipeMedicale = {
        if (_selectedDoctor != null) 
          'MEDECIN': {
            'id': _selectedDoctor!,
            'nom': _doctors.firstWhere((d) => d.id == _selectedDoctor).lastName,
            'prenom': _doctors.firstWhere((d) => d.id == _selectedDoctor).firstName,
            'specialite': _doctors.firstWhere((d) => d.id == _selectedDoctor).specialty ?? 'GENERAL',
          },
        if (_selectedAnesthetist != null)
          'ANESTHESISTE': {
            'id': _selectedAnesthetist!,
            'nom': _anesthetists.firstWhere((a) => a.id == _selectedAnesthetist).lastName,
            'prenom': _anesthetists.firstWhere((a) => a.id == _selectedAnesthetist).firstName,
            'specialite': _anesthetists.firstWhere((a) => a.id == _selectedAnesthetist).specialty ?? 'ANESTHESIE',
          },
        if (_selectedNurse != null)
          'INFIRMIER': {
            'id': _selectedNurse!,
            'nom': _nurses.firstWhere((n) => n.id == _selectedNurse).lastName,
            'prenom': _nurses.firstWhere((n) => n.id == _selectedNurse).firstName,
          },
      };

      // Prepare requesting doctor
      final medecinDemandeur = {
        'id': currentUser.id,
        'nom': currentUser.lastName,
        'prenom': currentUser.firstName,
        'specialite': currentUser.specialty ?? currentUser.role,
      };

      // Prepare patient data
      final patientData = _isNewPatient
          ? {
              'nom': _patientLastNameController.text,
              'prenom': _patientFirstNameController.text,
              'dateNaissance': _patientBirthDate != null 
                  ? DateFormat('yyyy-MM-dd').format(_patientBirthDate!)
                  : null,
              'telephone': _patientPhoneController.text.isNotEmpty 
                  ? _patientPhoneController.text 
                  : null,
              'adresse': _patientAddressController.text.isNotEmpty
                  ? _patientAddressController.text
                  : null,
              'nationality': _selectedNationality,
            }
          : null;

      // Build complete payload
      final payload = {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'type': _selectedType,
        'statut': 'DEMANDE',
        'startTime': _startTime != null
            ? '${DateFormat('yyyy-MM-dd').format(_selectedDate!)}T${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'endTime': _endTime != null
            ? '${DateFormat('yyyy-MM-dd').format(_selectedDate!)}T${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'equipeMedicale': equipeMedicale,
        'medecinDemandeur': medecinDemandeur,
        'patient': patientData,
        'patientId': _isNewPatient ? null : _selectedPatientId,
      };

      // Send request
      await interventionService.createInterventionWithPatient(
        payload,
        currentUser.id,
      );
      
      setState(() {
        _successMessage = 'Intervention request submitted successfully!';
      });

      // Clear form after success
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting request: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAnimatedField({
    required Widget child,
    double delay = 0.0,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final opacity = (_animationController.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - opacity) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    bool required = false,
    double delay = 0.0,
  }) {
    return _buildAnimatedField(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                errorStyle: const TextStyle(color: Colors.redAccent),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              validator: required
                  ? (value) => value == null ? 'This field is required' : null
                  : null,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
    double delay = 0.0,
  }) {
    return _buildAnimatedField(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onTap,
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  suffixIcon: Icon(icon, color: Colors.teal.shade700),
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
                child: Text(
                  value ?? 'Select',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffDropdown({
    required String title,
    required List<MedicalStaff> staffList,
    required int? selectedValue,
    required Function(int?) onChanged,
    double delay = 0.0,
  }) {
    return _buildAnimatedField(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selectedValue,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                errorStyle: const TextStyle(color: Colors.redAccent),
              ),
              items: staffList.map((staff) {
                return DropdownMenuItem<int>(
                  value: staff.id,
                  child: Text(
                    '${staff.firstName} ${staff.lastName}${staff.specialty != null ? ' (${staff.specialty})' : ''}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
    double delay = 0.0,
    TextInputType? keyboardType,
  }) {
    return _buildAnimatedField(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                errorStyle: const TextStyle(color: Colors.redAccent),
                hintText: label,
              ),
              validator: required
                  ? (value) => value?.isEmpty ?? true ? 'This field is required' : null
                  : null,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black87),
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade100.withOpacity(0.9),
          border: Border.all(color: Colors.red.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessWidget() {
    if (_successMessage.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade100.withOpacity(0.9),
          border: Border.all(color: Colors.green.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _successMessage,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTypeSelector() {
    return _buildAnimatedField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Type',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(
                    'New patient',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                  value: true,
                  groupValue: _isNewPatient,
                  onChanged: (value) {
                    setState(() {
                      _isNewPatient = value!;
                      _selectedPatientId = null;
                      _foundPatients.clear();
                    });
                  },
                  activeColor: Colors.teal.shade700,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(
                    'Existing patient',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                  value: false,
                  groupValue: _isNewPatient,
                  onChanged: (value) {
                    setState(() {
                      _isNewPatient = value!;
                    });
                  },
                  activeColor: Colors.teal.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSearchField() {
    return _buildAnimatedField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search patient by name or phone',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
              suffixIcon: Icon(Icons.search, color: Colors.teal.shade700),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            style: const TextStyle(color: Colors.black87),
            onChanged: (value) => _searchPatients(value),
          ),
          const SizedBox(height: 8),
          if (_isSearchingPatients)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_foundPatients.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: _foundPatients.length,
                itemBuilder: (context, index) {
                  final patient = _foundPatients[index];
                  return ListTile(
                    title: Text(
                      '${patient.prenom} ${patient.nom}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    subtitle: Text(
                      patient.telephone ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedPatientId = patient.id;
                        _patientFirstNameController.text = patient.prenom;
                        _patientLastNameController.text = patient.nom;
                        _patientPhoneController.text = patient.telephone ?? '';
                        _patientAddressController.text = patient.adresse ?? '';
                        _foundPatients.clear();
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedPatientCard() {
    if (_selectedPatientId == null) return const SizedBox.shrink();

    return _buildAnimatedField(
      child: Card(
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Patient',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Name: ${_patientFirstNameController.text} ${_patientLastNameController.text}',
                style: const TextStyle(color: Colors.black87),
              ),
              if (_patientPhoneController.text.isNotEmpty)
                Text(
                  'Phone: ${_patientPhoneController.text}',
                  style: const TextStyle(color: Colors.black87),
                ),
              if (_patientAddressController.text.isNotEmpty)
                Text(
                  'Address: ${_patientAddressController.text}',
                  style: const TextStyle(color: Colors.black87),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/image/life.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.5),
            colorBlendMode: BlendMode.darken,
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'New Intervention Request',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the row
                    ],
                  ),
                ),
                // TabBar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.teal.shade700,
                  labelColor: Colors.teal.shade700,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: const [
                    Tab(text: 'Intervention'),
                    Tab(text: 'Patient'),
                    Tab(text: 'Medical Team'),
                  ],
                ),
                // TabBarView
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Intervention Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildErrorWidget(),
                                  _buildSuccessWidget(),
                                  
                                  _buildDropdownField(
                                    label: 'Intervention Type*',
                                    items: _interventionTypes,
                                    value: _selectedType.isNotEmpty ? _selectedType : null,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value!;
                                        _fetchMedicalStaff();
                                      });
                                    },
                                    required: true,
                                    delay: 0.0,
                                  ),

                                  _buildDateTimeField(
                                    label: 'Date*',
                                    value: _selectedDate != null 
                                        ? DateFormat('EEEE d MMMM yyyy').format(_selectedDate!)
                                        : null,
                                    icon: Icons.calendar_today,
                                    onTap: () => _selectDate(context),
                                    isRequired: true,
                                    delay: 0.1,
                                  ),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDateTimeField(
                                          label: 'Start Time (optional)',
                                          value: _startTime?.format(context),
                                          icon: Icons.access_time,
                                          onTap: () => _selectStartTime(context),
                                          delay: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDateTimeField(
                                          label: 'End Time (optional)',
                                          value: _endTime?.format(context),
                                          icon: Icons.access_time,
                                          onTap: () => _selectEndTime(context),
                                          delay: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Patient Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildErrorWidget(),
                                  _buildSuccessWidget(),
                                  
                                  _buildPatientTypeSelector(),
                                  
                                  if (!_isNewPatient) _buildPatientSearchField(),
                                  if (!_isNewPatient) _buildSelectedPatientCard(),
                                  
                                  if (_isNewPatient) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextFormField(
                                            label: 'First Name*',
                                            controller: _patientFirstNameController,
                                            required: true,
                                            delay: 0.0,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildTextFormField(
                                            label: 'Last Name*',
                                            controller: _patientLastNameController,
                                            required: true,
                                            delay: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    _buildDateTimeField(
                                      label: 'Birth Date',
                                      value: _patientBirthDate != null 
                                          ? DateFormat('yyyy-MM-dd').format(_patientBirthDate!)
                                          : null,
                                      icon: Icons.calendar_today,
                                      onTap: () => _selectBirthDate(context),
                                      delay: 0.2,
                                    ),

                                    _buildDropdownField(
                                      label: 'Nationality',
                                      items: _nationalities.map((n) => n['name']!).toList(),
                                      value: _nationalities.firstWhere(
                                        (n) => n['code'] == _selectedNationality,
                                        orElse: () => _nationalities.first,
                                      )['name'],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedNationality = _nationalities.firstWhere(
                                            (n) => n['name'] == value,
                                            orElse: () => _nationalities.first,
                                          )['code']!;
                                        });
                                      },
                                      delay: 0.3,
                                    ),

                                    _buildTextFormField(
                                      label: 'Phone',
                                      controller: _patientPhoneController,
                                      keyboardType: TextInputType.phone,
                                      delay: 0.4,
                                    ),

                                    _buildTextFormField(
                                      label: 'Address',
                                      controller: _patientAddressController,
                                      maxLines: 2,
                                      delay: 0.5,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Medical Team Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildErrorWidget(),
                                  _buildSuccessWidget(),
                                  
                                  if (_isLoadingStaff)
                                    const Center(child: CircularProgressIndicator(color: Colors.white))
                                  else ...[
                                    _buildStaffDropdown(
                                      title: 'Doctor',
                                      staffList: _doctors,
                                      selectedValue: _selectedDoctor,
                                      onChanged: (value) => setState(() => _selectedDoctor = value),
                                      delay: 0.0,
                                    ),

                                    _buildStaffDropdown(
                                      title: 'Anesthetist',
                                      staffList: _anesthetists,
                                      selectedValue: _selectedAnesthetist,
                                      onChanged: (value) => setState(() => _selectedAnesthetist = value),
                                      delay: 0.1,
                                    ),

                                    _buildStaffDropdown(
                                      title: 'Nurse',
                                      staffList: _nurses,
                                      selectedValue: _selectedNurse,
                                      onChanged: (value) => setState(() => _selectedNurse = value),
                                      delay: 0.2,
                                    ),

                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                            (states) {
                                              if (states.contains(MaterialState.disabled)) {
                                                return Colors.grey.shade600;
                                              }
                                              return Colors.teal.shade700;
                                            },
                                          ),
                                          shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                          ),
                                          elevation: MaterialStateProperty.all(8),
                                          shadowColor: MaterialStateProperty.all(Colors.black45),
                                        ),
                                        onPressed: _isLoading ? null : _submitForm,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 3,
                                                  ),
                                                )
                                              : const Text(
                                                  'Submit Request',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                // Navigation Buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.black.withOpacity(0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_tabController.index > 0)
                        SizedBox(
                          width: 120,
                          height: 50,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.grey.shade700),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(8),
                            ),
                            onPressed: _handlePreviousTab,
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 120),
                      if (_tabController.index < _tabController.length - 1)
                        SizedBox(
                          width: 120,
                          height: 50,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.teal.shade700),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(8),
                            ),
                            onPressed: _handleNextTab,
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}