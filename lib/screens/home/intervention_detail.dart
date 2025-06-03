import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intervention = ModalRoute.of(context)!.settings.arguments as Intervention;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arrière-plan photo avec filtre sombre
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
                        // Titre et bouton retour
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
                            SizedBox(width: 48), // espace pour équilibrer
                          ],
                        ),

                        SizedBox(height: 24),

                        // Section principale avec animation
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
                              _buildRoomSection(context, intervention),
                              if (intervention.medicalTeam != null && intervention.medicalTeam!.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: _buildMedicalTeamSection(context, intervention),
                                ),
                              SizedBox(height: 30),
                              Center(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.description_outlined),
                                  label: Text('Rapport Postopératoire'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(255, 6, 132, 195),
                                    padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                    elevation: 6,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      RapportFormScreen.routeName,
                                      arguments: intervention,
                                    );
                                  },
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

  Widget _buildGeneralInfoCard(BuildContext context, Intervention intervention) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(20),
        child:Column(
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
      intervention.status.toLowerCase(),
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

  Widget _buildRoomSection(BuildContext context, Intervention intervention) {
    final hasRoomInfo = intervention.room != null || intervention.roomId != null;
    if (!hasRoomInfo) return SizedBox.shrink();

    final roomName = intervention.room?.name ?? 'Salle ${intervention.roomId}';
    final location = intervention.room?.location ?? 'Localisation inconnue';
    final category = intervention.room?.category ?? 'Type inconnu';
    final equipment = intervention.room?.equipment;

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
            _buildDetailRow(context, Icons.room, 'Nom', roomName),
            _buildDetailRow(context, Icons.location_on, 'Localisation', location),
            _buildDetailRow(context, Icons.category, 'Catégorie', category),
            if (equipment != null && equipment.isNotEmpty)
              _buildDetailRow(context, Icons.build, 'Équipement', equipment),
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
                          // TODO: Implémenter l'appel téléphonique
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
    switch (status.toLowerCase()) {
      case 'terminée':
        return Colors.green[700]!;
      case 'en attente':
        return Colors.orange[800]!;
      case 'annulée':
        return Colors.red[700]!;
      default:
        return Colors.grey[800]!;
    }
  }
}