import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:medical_intervention_app/models/rapport.dart';
import 'package:medical_intervention_app/screens/home/rapport_form.dart';
import 'package:medical_intervention_app/services/auth_service.dart';
import 'package:medical_intervention_app/services/intervention_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ListRapportScreen extends StatefulWidget {
  static const routeName = '/rapports';

  @override
  State<ListRapportScreen> createState() => _ListRapportScreenState();
}

class _ListRapportScreenState extends State<ListRapportScreen> {
  final _searchController = TextEditingController();
  List<Rapport> _allRapports = [];
  List<Rapport> _filteredRapports = [];
  String? _userRole;
  int? _staffId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserAndRapports();
  }

  Future<void> _loadUserAndRapports() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _errorMessage = "Utilisateur non connecté.";
          _isLoading = false;
        });
        return;
      }
      _staffId = user.id;
      _userRole = user.role;

      if (_staffId != null) {
        final interventionService = InterventionService();
        final rapports = await interventionService.getRapportsByStaff(_staffId!, '');
        setState(() {
          _allRapports = rapports;
          _filteredRapports = rapports;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "ID du personnel médical introuvable.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors du chargement : $e";
        _isLoading = false;
      });
    }
  }

  void _filterRapports(String query) {
    setState(() {
      _filteredRapports = _allRapports.where((r) {
        final q = query.toLowerCase();
        return (r.diagnostic ?? '').toLowerCase().contains(q) ||
            (r.complications ?? '').toLowerCase().contains(q) ||
            (r.recommandations ?? '').toLowerCase().contains(q) ||
            (r.notesInfirmier ?? '').toLowerCase().contains(q) ||
            (r.interventionId.toString().contains(q));
      }).toList();
    });
  }

  Widget _buildRapportCard(Rapport rapport) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Optional: Add tap functionality if needed
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Intervention #${rapport.interventionId}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(rapport.statut),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rapport.statut.toString().split('.').last,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildInfoRow(Icons.medical_services, 'Diagnostic', rapport.diagnostic ?? 'N/A'),
              _buildInfoRow(Icons.warning, 'Complications', rapport.complications ?? 'Aucune'),
              _buildInfoRow(Icons.recommend, 'Recommandations', rapport.recommandations ?? 'N/A'),
              _buildInfoRow(Icons.note, 'Notes Infirmier', rapport.notesInfirmier ?? 'N/A'),
              SizedBox(height: 8),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy - HH:mm').format(rapport.dateCreation),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RapportFormScreen.routeName,
                        arguments: rapport,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 4),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic statut) {
    switch (statut.toString().split('.').last) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Rapports Postopératoires"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[800]!, Colors.blue[600]!],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserAndRapports,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRapports,
              decoration: InputDecoration(
                hintText: "Rechercher des rapports...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUserAndRapports,
                              child: Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredRapports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  "Aucun rapport trouvé",
                                  style: TextStyle(color: Colors.grey, fontSize: 18),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Essayez de modifier vos critères de recherche",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUserAndRapports,
                            color: Colors.blue[700],
                            child: ListView.builder(
                              padding: EdgeInsets.only(bottom: 16),
                              itemCount: _filteredRapports.length,
                              itemBuilder: (ctx, i) => _buildRapportCard(_filteredRapports[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            RapportFormScreen.routeName,
            arguments: null, // Pass null for new report
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[700],
      ),
    );
  }
}