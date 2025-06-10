import 'package:flutter/material.dart';
import 'package:medical_intervention_app/models/intervention.dart';
import 'package:medical_intervention_app/models/rapport.dart';
import 'package:medical_intervention_app/services/auth_service.dart';
import 'package:medical_intervention_app/services/intervention_service.dart';
import 'package:provider/provider.dart';

class RapportFormScreen extends StatefulWidget {
  static const routeName = '/rapport-form';

  @override
  _RapportFormScreenState createState() => _RapportFormScreenState();
}

class _RapportFormScreenState extends State<RapportFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _diagnosticController = TextEditingController();
  final _complicationsController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _nurseNotesController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  Rapport? _existingRapport;
  Intervention? _intervention;
  String? _userRole;
  int? _userId;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Intervention) {
        setState(() => _intervention = args);
        _loadUserData();
        _loadRapport();
      }
    });
    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final user = await authService.getCurrentUser();
      setState(() {
        _userId = user?.id;
        _userRole = user?.role;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur chargement utilisateur: $e';
      });
    }
  }

  Future<void> _loadRapport() async {
    if (_intervention == null) return;

    setState(() => _isLoading = true);
    try {
      final interventionService = Provider.of<InterventionService>(context, listen: false);
      final rapport = await interventionService.getRapportByIntervention(_intervention!.id);
      setState(() {
        _existingRapport = rapport;
        if (rapport != null) {
          _diagnosticController.text = rapport.diagnostic;
          _complicationsController.text = rapport.complications ?? '';
          _recommendationsController.text = rapport.recommandations;
          _nurseNotesController.text = rapport.notesInfirmier ?? '';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Erreur chargement rapport: $e');
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

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
    bool enabled = true,
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
            enabled
                ? TextFormField(
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
                    onChanged: (value) => setState(() {}),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.text.isEmpty ? 'Non spécifié' : controller.text,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null || _userRole == null) {
      setState(() => _errorMessage = 'Utilisateur non authentifié');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final interventionService = Provider.of<InterventionService>(context, listen: false);
      final rapportData = <String, dynamic>{};

      if (_userRole == 'MEDECIN') {
        rapportData.addAll({
          'diagnostic': _diagnosticController.text,
          'complications': _complicationsController.text.isNotEmpty 
              ? _complicationsController.text 
              : null,
          'recommandations': _recommendationsController.text,
          'statut': 'BROUILLON',
        });
      } else if (_userRole == 'INFIRMIER') {
        rapportData['notesInfirmier'] = _nurseNotesController.text;
      }

      if (_existingRapport != null) {
        await interventionService.updateRapport(
          _existingRapport!.id,
          rapportData,
          _userId!,
          _userRole!,
        );
        _successMessage = 'Rapport mis à jour avec succès!';
      } else {
        await interventionService.createRapport(
          _intervention!.id,
          _userId!,
          rapportData,
          _userRole!,
        );
        _successMessage = 'Rapport créé avec succès!';
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get _canSubmit {
    if (_userRole == 'MEDECIN') {
      return _diagnosticController.text.isNotEmpty &&
             _recommendationsController.text.isNotEmpty;
    } else if (_userRole == 'INFIRMIER') {
      return _nurseNotesController.text.isNotEmpty;
    }
    return false;
  }

  bool get _canMedecinEdit {
    return _userRole == 'MEDECIN';
  }

  bool get _canInfirmierEdit {
    return _userRole == 'INFIRMIER';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/image/life.jpg', // Use the same background image
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
                        // Title and back button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              _existingRapport != null ? 'Modifier Rapport' : 'Nouveau Rapport',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 48), // Balance the row
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Intervention: ${_intervention?.type?.replaceAll('_', ' ') ?? ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (_errorMessage.isNotEmpty) _buildErrorWidget(),
                        if (_successMessage.isNotEmpty) _buildSuccessWidget(),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Diagnostic (visible to all, editable by doctor only)
                              _buildTextFormField(
                                label: 'Diagnostic*',
                                controller: _diagnosticController,
                                maxLines: 3,
                                required: _userRole == 'MEDECIN',
                                enabled: _canMedecinEdit,
                                delay: 0.0,
                              ),

                              // Complications (visible to all, editable by doctor only)
                              _buildTextFormField(
                                label: 'Complications',
                                controller: _complicationsController,
                                maxLines: 2,
                                enabled: _canMedecinEdit,
                                delay: 0.1,
                              ),

                              // Recommendations (visible to all, editable by doctor only)
                              _buildTextFormField(
                                label: 'Recommandations*',
                                controller: _recommendationsController,
                                maxLines: 3,
                                required: _userRole == 'MEDECIN',
                                enabled: _canMedecinEdit,
                                delay: 0.2,
                              ),

                              // Nurse Notes (visible to all, editable by nurse only)
                              _buildTextFormField(
                                label: 'Notes Infirmier*',
                                controller: _nurseNotesController,
                                maxLines: 3,
                                required: _userRole == 'INFIRMIER',
                                enabled: _canInfirmierEdit,
                                delay: 0.3,
                              ),

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
                                  onPressed: _canSubmit && !_isLoading ? _submitForm : null,
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
                                            'Enregistrer',
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

  @override
  void dispose() {
    _animationController.dispose();
    _diagnosticController.dispose();
    _complicationsController.dispose();
    _recommendationsController.dispose();
    _nurseNotesController.dispose();
    super.dispose();
  }
}