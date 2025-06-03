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

class _RapportFormScreenState extends State<RapportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosticController = TextEditingController();
  final _complicationsController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _nurseNotesController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  Rapport? _existingRapport;
  Intervention? _intervention;
  String? _userRole;
  int? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Intervention) {
        setState(() => _intervention = args);
        _loadUserData();
        _loadRapport();
      }
    });
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          enabled
              ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: label,
                  ),
                  maxLines: maxLines,
                  validator: required
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          return null;
                        }
                      : null,
                  readOnly: !enabled,
                  onChanged: (value) => setState(() {}), // Pour rafraîchir l'état du bouton
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    controller.text.isEmpty ? 'Non spécifié' : controller.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
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
      } else {
        await interventionService.createRapport(
          _intervention!.id,
          _userId!,
          rapportData,
          _userRole!,
        );
      }

      Navigator.pop(context, true);
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
      appBar: AppBar(
        title: Text(_existingRapport != null ? 'Modifier Rapport' : 'Nouveau Rapport'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage.isNotEmpty)
                      _buildErrorWidget(),
                    
                    Text(
                      'Intervention: ${_intervention?.type?.replaceAll('_', ' ') ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Diagnostic (visible à tous, modifiable par médecin seulement)
                    _buildFormField(
                      label: 'Diagnostic*',
                      controller: _diagnosticController,
                      enabled: _canMedecinEdit,
                      required: true,
                      maxLines: 3,
                    ),
                    
                    // Complications (visible à tous, modifiable par médecin seulement)
                    _buildFormField(
                      label: 'Complications',
                      controller: _complicationsController,
                      enabled: _canMedecinEdit,
                      maxLines: 2,
                    ),
                    
                    // Recommandations (visible à tous, modifiable par médecin seulement)
                    _buildFormField(
                      label: 'Recommandations*',
                      controller: _recommendationsController,
                      enabled: _canMedecinEdit,
                      required: true,
                      maxLines: 3,
                    ),
                    
                    // Notes Infirmier (visible à tous, modifiable par infirmier seulement)
                    _buildFormField(
                      label: 'Notes Infirmier*',
                      controller: _nurseNotesController,
                      enabled: _canInfirmierEdit,
                      required: _userRole == 'INFIRMIER',
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _submitForm : null,
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _diagnosticController.dispose();
    _complicationsController.dispose();
    _recommendationsController.dispose();
    _nurseNotesController.dispose();
    super.dispose();
  }
}