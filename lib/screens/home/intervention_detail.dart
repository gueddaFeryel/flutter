import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medical_intervention_app/models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_intervention_app/models/intervention.dart';
import 'rapport_form.dart';

class InterventionDetailScreen extends StatefulWidget {
  static const routeName = '/intervention-detail';

  @override
  State<InterventionDetailScreen> createState() => _InterventionDetailScreenState();
}

class _InterventionDetailScreenState extends State<InterventionDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;
  AppUser? _currentUser;
  String? _errorMessage; // To display loading errors

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    debugPrint('[DEBUG] Starting user load');
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('[ERROR] No Firebase user logged in');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Aucun utilisateur connecté';
        });
        return;
      }

      debugPrint('[DEBUG] Firebase user found: ${firebaseUser.uid}');
      final userData = await _fetchUserData(firebaseUser.uid);
      if (userData.isEmpty) {
        debugPrint('[ERROR] No user data found for UID: ${firebaseUser.uid}');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Données utilisateur introuvables';
          _currentUser = null;
        });
        return;
      }

      setState(() {
        _currentUser = AppUser.fromFirebase(firebaseUser, userData);
        _isLoading = false;
        debugPrint('[DEBUG] User loaded: ${_currentUser!.displayName}, Role: ${_currentUser!.role}');
      });
    } catch (e) {
      debugPrint('[ERROR] Failed to load user: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement: $e';
        _currentUser = null;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    try {
      debugPrint('[DEBUG] Fetching user data for UID: $uid');
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) {
        debugPrint('[ERROR] User document does not exist for UID: $uid');
        return {};
      }
      final data = doc.data()!;
      debugPrint('[DEBUG] User data fetched: $data');
      return data;
    } catch (e) {
      debugPrint('[ERROR] Failed to fetch user data: $e');
      return {};
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _canEditReport(Intervention intervention) {
    debugPrint('[DEBUG] Checking report edit conditions:');
    debugPrint('[DEBUG] Status: ${intervention.status}');
    debugPrint('[DEBUG] End Time: ${intervention.endTime}');

    final status = intervention.status.toLowerCase();
    if (!status.contains('term')) {
      debugPrint('[DEBUG] Failed: Status not terminated');
      return false;
    }

    if (intervention.endTime == null) {
      debugPrint('[DEBUG] Failed: No end time defined');
      return false;
    }

    final now = DateTime.now();
    final endTime = intervention.endTime!;
    final difference = now.difference(endTime);

    debugPrint('[DEBUG] Now: $now');
    debugPrint('[DEBUG] End Time: $endTime');
    debugPrint('[DEBUG] Difference: ${difference.inHours} hours');

    if (difference.inHours > 24) {
      debugPrint('[DEBUG] Failed: 24-hour deadline exceeded');
      return false;
    }

    debugPrint('[DEBUG] Success: Conditions met');
    return true;
  }

  bool _canShowReportButton() {
    if (_currentUser == null) {
      debugPrint('[DEBUG] No user loaded, hiding report button');
      return false;
    }
    final role = _currentUser!.role.toUpperCase().trim();
    debugPrint('[DEBUG] Checking role for report button: $role');
    final canShow = role == 'MEDECIN' || role == 'INFIRMIER';
    debugPrint('[DEBUG] Can show report button: $canShow');
    return canShow;
  }

  @override
  Widget build(BuildContext context) {
    final intervention = ModalRoute.of(context)!.settings.arguments as Intervention;
    final canEditReport = _canEditReport(intervention);
    final canShowReportButton = _canShowReportButton();

    debugPrint('[DEBUG] canEditReport: $canEditReport');
    debugPrint('[DEBUG] canShowReportButton: $canShowReportButton');

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
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Text(
                              'Détails Intervention',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(width: 48),
                          ],
                        ),
                        SizedBox(height: 24),
                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[200], fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ),
                        if (_currentUser != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Rôle actuel: ${_currentUser!.role}',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _animationController.value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - _animationController.value) * 20),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _buildGeneralInfoCard(context, intervention),
                              SizedBox(height: 20),
                              _buildPatientSection(context, intervention),
                              SizedBox(height: 20),
                              _buildRoomSection(context, intervention),
                              if (intervention.medicalTeam != null && intervention.medicalTeam!.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: _buildMedicalTeamSection(context, intervention),
                                ),
                              if (canShowReportButton) ...[
                                SizedBox(height: 30),
                                Center(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.description_outlined),
                                    label: Text('Rapport Postopératoire'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canEditReport
                                          ? Color.fromARGB(255, 6, 132, 195)
                                          : Colors.grey,
                                      padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24)),
                                      elevation: 6,
                                    ),
                                    onPressed: canEditReport
                                        ? () {
                                            debugPrint('[NAVIGATION] Navigating to report form');
                                            Navigator.pushNamed(
                                              context,
                                              RapportFormScreen.routeName,
                                              arguments: intervention,
                                            ).then((_) {
                                              setState(() {
                                                debugPrint('[NAVIGATION] Returned from form');
                                              });
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                                if (!canEditReport)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      children: [
                                        if (!intervention.status.toLowerCase().contains('term'))
                                          Text(
                                            'Le rapport n\'est disponible que pour les interventions terminées',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        if (intervention.status.toLowerCase().contains('term') &&
                                            intervention.endTime == null)
                                          Text(
                                            'Heure de fin non définie - contactez l\'administration',
                                            style: TextStyle(
                                              color: Colors.orange[200],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        if (intervention.status.toLowerCase().contains('term') &&
                                            intervention.endTime != null &&
                                            DateTime.now().difference(intervention.endTime!).inHours > 24)
                                          Text(
                                            'Délai dépassé (${DateTime.now().difference(intervention.endTime!).inHours}h)',
                                            style: TextStyle(
                                              color: Colors.orange[200],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
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

  Widget _buildGeneralInfoCard(BuildContext context, Intervention intervention) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${intervention.type.replaceAll('_', ' ').toUpperCase()}  ${intervention.id}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 6, 160, 195),
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 20),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(intervention.date),
            ),
            if (intervention.startTime != null)
              _buildDetailRow(
                context,
                Icons.access_time,
                'Heure de début',
                DateFormat('HH:mm').format(intervention.startTime!),
              ),
            if (intervention.endTime != null)
              _buildDetailRow(
                context,
                Icons.access_time,
                'Heure de fin',
                DateFormat('HH:mm').format(intervention.endTime!),
              ),
            _buildDetailRow(
              context,
              Icons.info,
              'Statut',
              intervention.status,
              isStatus: true,
            ),
            SizedBox(height: 20),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 6, 147, 208),
              ),
            ),
            SizedBox(height: 8),
            Text(
              intervention.notes ?? 'Aucune note',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSection(BuildContext context, Intervention intervention) {
    final hasPatientData = intervention.patient != null &&
        (intervention.patient!.nom.isNotEmpty || intervention.patient!.prenom.isNotEmpty);

    if (!hasPatientData) return SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start  ,
          children: [
            Text(
              'Patient',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 6, 158, 213),
              ),
            ),
            SizedBox(height: 12),
            if (intervention.patient!.nom.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.person,
                'Nom',
                intervention.patient!.nom,
              ),
            if (intervention.patient!.prenom.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.person_outline,
                'Prénom',
                intervention.patient!.prenom,
              ),
            if (intervention.patient!.dateNaissance != null)
              _buildDetailRow(
                context,
                Icons.cake,
                'Date de naissance',
                DateFormat('dd/MM/yyyy').format(intervention.patient!.dateNaissance!),
              ),
            if (intervention.patient!.telephone != null && intervention.patient!.telephone!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.phone, color: Colors.teal[700]),
                title: Text('Téléphone'),
                subtitle: Text(intervention.patient!.telephone!),
                onTap: () {
                  launchUrl(Uri.parse('tel:${intervention.patient!.telephone!}'));
                },
              ),
            if (intervention.patient!.adresse != null && intervention.patient!.adresse!.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.location_on,
                'Adresse',
                intervention.patient!.adresse!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSection(BuildContext context, Intervention intervention) {
    final hasRoomData = intervention.room != null || intervention.roomId != null;
    if (!hasRoomData) return SizedBox.shrink();

    final room = intervention.room;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salle d\'intervention',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 6, 158, 213),
              ),
            ),
            SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.room,
              'Nom',
              room?.name ?? 'Salle ${intervention.roomId}',
            ),
            if (room?.location != null && room!.location!.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.location_on,
                'Localisation',
                room.location!,
              ),
            if (room?.category != null && room!.category!.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.category,
                'Catégorie',
                room.category!,
              ),
            if (room?.equipment != null && room!.equipment!.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.build,
                'Équipement',
                room.equipment!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalTeamSection(BuildContext context, Intervention intervention) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Équipe médicale',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 8, 157, 202),
              ),
            ),
            SizedBox(height: 12),
            ...intervention.medicalTeam!.map((member) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                tileColor: Colors.teal[50]?.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.person, color: Colors.teal[800]),
                title: Text('${member.firstName} ${member.lastName}',
                  style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(member.role.toLowerCase()),
                trailing: member.phone != null
                    ? IconButton(
                        icon: Icon(Icons.phone, color: Colors.teal[700]),
                        onPressed: () {
                          launchUrl(Uri.parse('tel:${member.phone}'));
                        },
                      )
                    : null,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.teal[700]),
          SizedBox(width: 14),
          Text(
            '$label : ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 4, 130, 221),
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isStatus ? _getStatusColor(value) : Colors.black87,
                fontWeight: isStatus ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('term')) {
      return Colors.green[700]!;
    } else if (lowerStatus.contains('attente')) {
      return Colors.orange[800]!;
    } else if (lowerStatus.contains('annul')) {
      return Colors.red[700]!;
    }
    return Colors.grey[800]!;
  }
}