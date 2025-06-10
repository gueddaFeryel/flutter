import 'package:flutter/material.dart';
import 'package:medical_intervention_app/models/user.dart';
import 'package:medical_intervention_app/screens/auth/login_screen.dart';
import 'package:medical_intervention_app/screens/home/calendar_screen.dart';
import 'package:medical_intervention_app/screens/home/list_rapport_screen.dart';
import 'package:medical_intervention_app/screens/home/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  AppUser? _currentUser;
  String? _userErrorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _userErrorMessage = null;
    });
    debugPrint('[DEBUG] Starting user load');
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('[ERROR] No Firebase user logged in');
        setState(() {
          _isLoading = false;
          _userErrorMessage = 'Aucun utilisateur connecté';
        });
        return;
      }

      debugPrint('[DEBUG] Firebase user found: ${firebaseUser.uid}');
      final userData = await _fetchUserData(firebaseUser.uid);
      if (userData.isEmpty) {
        debugPrint('[ERROR] No user data found for UID: ${firebaseUser.uid}');
        setState(() {
          _isLoading = false;
          _userErrorMessage = 'Données utilisateur introuvables';
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
        _userErrorMessage = 'Erreur de chargement: $e';
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

  bool _canShowRapportTab() {
    if (_currentUser == null) {
      debugPrint('[DEBUG] No user loaded, hiding rapport tab');
      return false;
    }
    final role = _currentUser!.role.toUpperCase().trim();
    debugPrint('[DEBUG] Checking role for rapport tab: $role');
    final canShow = role == 'MEDECIN' || role == 'INFIRMIER';
    debugPrint('[DEBUG] Can show rapport tab: $canShow');
    return canShow;
  }

  List<Widget> _buildScreens() {
    final screens = [
      const CalendarScreen(),
      if (_canShowRapportTab()) ListRapportScreen(),
      Consumer<AuthService>(
        builder: (context, authService, child) => ProfileScreen(authService: authService),
      ),
    ];
    return screens;
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Calendrier',
      ),
      if (_canShowRapportTab())
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Rapports',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
    return items;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _performLogout() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.logout();

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de déconnexion: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();
    final navigationItems = _buildNavigationItems();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                  image: const DecorationImage(
                    image: AssetImage('assets/image/logo.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Text('Intervention Médicale'),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _confirmLogout,
              tooltip: 'Déconnexion',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_userErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _userErrorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (_currentUser != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Rôle actuel: ${_currentUser!.role}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: screens,
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: navigationItems,
        ),
      ),
    );
  }
}