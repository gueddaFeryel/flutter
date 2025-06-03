import 'package:flutter/material.dart';
import 'package:medical_intervention_app/screens/auth/login_screen.dart';
import 'package:medical_intervention_app/screens/home/calendar_screen.dart';
import 'package:medical_intervention_app/screens/home/list_rapport_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();

  final List<Widget> _screens = [
    CalendarScreen(),
    ListRapportScreen(),
    const Center(child: Text('Profil')),
  ];

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
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular logo on the left
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
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendrier',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Rapports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}