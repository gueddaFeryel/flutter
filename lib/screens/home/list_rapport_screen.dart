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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getCurrentUser();
    _staffId = user?.id;
    _userRole = user?.role;
   
  }

 
  void _filterRapports(String query) {
    setState(() {
      _filteredRapports = _allRapports.where((r) {
        return (r.diagnostic ?? '').toLowerCase().contains(query.toLowerCase()) ||
            (r.complications ?? '').toLowerCase().contains(query.toLowerCase()) ||
            (r.recommandations ?? '').toLowerCase().contains(query.toLowerCase()) ||
            (r.notesInfirmier ?? '').toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _buildRapportCard(Rapport rapport) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRapportRow("Intervention", rapport.interventionId.toString()),
              _buildRapportRow("Diagnostic", rapport.diagnostic ?? 'N/A'),
              _buildRapportRow("Complications", rapport.complications ?? 'Aucune'),
              _buildRapportRow("Recommandations", rapport.recommandations ?? 'N/A'),
              _buildRapportRow("Notes Infirmier", rapport.notesInfirmier ?? 'N/A'),
              _buildRapportRow("Statut", rapport.statut.toString().split('.').last),
              _buildRapportRow("Date", DateFormat('dd/MM/yyyy HH:mm').format(rapport.dateCreation)),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Modifier'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      RapportFormScreen.routeName,
                      arguments: rapport,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.9),
                    shape: StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRapportRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$title : ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Rapports Postopératoires", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/life.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterRapports,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Rechercher...",
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _filteredRapports.isEmpty
                          ? Center(
                              child: Text("Aucun rapport trouvé",
                                  style: TextStyle(color: Colors.white, fontSize: 18)),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: 20),
                              itemCount: _filteredRapports.length,
                              itemBuilder: (ctx, i) => _buildRapportCard(_filteredRapports[i]),
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
