import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medical_intervention_app/models/medical_staff.dart';
import 'package:medical_intervention_app/services/auth_service.dart';
import 'package:medical_intervention_app/services/intervention_service.dart';
import 'package:provider/provider.dart';

class InterventionFormScreen extends StatefulWidget {
  static const routeName = '/intervention-form';

  @override
  _InterventionFormScreenState createState() => _InterventionFormScreenState();
}

class _InterventionFormScreenState extends State<InterventionFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedType = '';
  String _selectedUrgency = 'NORMAL';
  bool _isLoading = false;
  bool _isLoadingStaff = false;
  String _errorMessage = '';
  String _successMessage = '';
  
  List<MedicalStaff> _doctors = [];
  List<MedicalStaff> _anesthetists = [];
  List<MedicalStaff> _nurses = [];
  
  int? _selectedDoctor;
  int? _selectedAnesthetist;
  int? _selectedNurse;

  List<String> _interventionTypes = [];
  final List<String> _urgencyLevels = ['FAIBLE', 'NORMAL', 'ELEVEE', 'URGENT'];
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchInterventionTypes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
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
        _errorMessage = 'Échec du chargement des types d\'intervention';
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
        _errorMessage = 'Échec du chargement de l\'équipe médicale';
      });
    } finally {
      setState(() {
        _isLoadingStaff = false;
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

  bool _validateForm() {
    if (_selectedDate == null) {
      setState(() => _errorMessage = 'La date est requise');
      return false;
    }

    if (_selectedType.isEmpty) {
      setState(() => _errorMessage = 'Le type est requis');
      return false;
    }

    if (_descriptionController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez fournir une description');
      return false;
    }

    if (_startTime != null && _endTime != null) {
      final start = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final end = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (start.isAfter(end)) {
        setState(() => _errorMessage = 'L\'heure de fin doit être après l\'heure de début');
        return false;
      }

      final durationHours = end.difference(start).inHours;
      if (durationHours > 24) {
        setState(() => _errorMessage = 'La durée ne doit pas dépasser 24 heures');
        return false;
      }
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

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
        throw Exception('Veuillez vous connecter pour soumettre une demande');
      }

      final equipeMedicale = {
        if (_selectedDoctor != null) 'MEDECIN': _selectedDoctor!,
        if (_selectedAnesthetist != null) 'ANESTHESISTE': _selectedAnesthetist!,
        if (_selectedNurse != null) 'INFIRMIER': _selectedNurse!,
      };

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
        'description': _descriptionController.text,
        'urgencyLevel': _selectedUrgency,
        'equipeMedicale': equipeMedicale,
      };

      await interventionService.createInterventionWithRoomAndUser(
        payload,
        currentUser.id,
      );
      
      setState(() {
        _successMessage = 'Demande envoyée avec succès!';
      });

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString().replaceAll('"', '')}';
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: value,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                validator: required
                    ? (value) => value == null ? 'Ce champ est obligatoire' : null
                    : null,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
              ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.black87),
                    const SizedBox(width: 10),
                    Text(
                      value ?? 'Sélectionner',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            if (isRequired && value == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ce champ est obligatoire',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<int>(
                value: selectedValue,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: staffList.map((staff) {
                  return DropdownMenuItem<int>(
                    value: staff.id,
                    child: Text(
                      '${staff.firstName} ${staff.lastName}' + 
                      (staff.specialty != null ? ' (${staff.specialty})' : ''),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
              ),
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
                hintText: label,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                errorStyle: const TextStyle(color: Colors.redAccent),
              ),
              validator: required
                  ? (value) => value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null
                  : null,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/image/life.jpg', // Remplace par ta photo en assets
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.5),
            colorBlendMode: BlendMode.darken,
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre et bouton retour
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Nouvelle demande d\'intervention',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 48), // espace pour équilibrer la ligne
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (_errorMessage.isNotEmpty) _buildErrorWidget(),
                        if (_successMessage.isNotEmpty) _buildSuccessWidget(),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildDropdownField(
                                label: 'Type d\'intervention*',
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

                              _buildDropdownField(
                                label: 'Niveau d\'urgence',
                                items: _urgencyLevels,
                                value: _selectedUrgency,
                                onChanged: (value) => setState(() => _selectedUrgency = value!),
                                delay: 0.1,
                              ),

                              _buildDateTimeField(
                                label: 'Date*',
                                value: _selectedDate != null 
                                    ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!)
                                    : null,
                                icon: Icons.calendar_today,
                                onTap: () => _selectDate(context),
                                isRequired: true,
                                delay: 0.2,
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateTimeField(
                                      label: 'Heure de début (optionnel)',
                                      value: _startTime?.format(context),
                                      icon: Icons.access_time,
                                      onTap: () => _selectStartTime(context),
                                      delay: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDateTimeField(
                                      label: 'Heure de fin (optionnel)',
                                      value: _endTime?.format(context),
                                      icon: Icons.access_time,
                                      onTap: () => _selectEndTime(context),
                                      delay: 0.4,
                                    ),
                                  ),
                                ],
                              ),

                              _buildTextFormField(
                                label: 'Description détaillée*',
                                controller: _descriptionController,
                                maxLines: 5,
                                required: true,
                                delay: 0.5,
                              ),

                              const SizedBox(height: 24),
                              const Divider(color: Colors.white54, thickness: 1),
                              const SizedBox(height: 16),

                              const Text(
                                'Équipe Médicale',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_isLoadingStaff)
                                const Center(child: CircularProgressIndicator(color: Colors.white))
                              else ...[
                                _buildStaffDropdown(
                                  title: 'Médecin',
                                  staffList: _doctors,
                                  selectedValue: _selectedDoctor,
                                  onChanged: (value) => setState(() => _selectedDoctor = value),
                                  delay: 0.6,
                                ),

                                _buildStaffDropdown(
                                  title: 'Anesthésiste',
                                  staffList: _anesthetists,
                                  selectedValue: _selectedAnesthetist,
                                  onChanged: (value) => setState(() => _selectedAnesthetist = value),
                                  delay: 0.7,
                                ),

                                _buildStaffDropdown(
                                  title: 'Infirmier',
                                  staffList: _nurses,
                                  selectedValue: _selectedNurse,
                                  onChanged: (value) => setState(() => _selectedNurse = value),
                                  delay: 0.8,
                                ),
                              ],

                              const SizedBox(height: 32),

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
                                            'Envoyer la demande',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
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
          ),
        ],
      ),
    );
  }
}