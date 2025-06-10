import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medical_intervention_app/models/user.dart';
import 'package:medical_intervention_app/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService authService;

  const ProfileScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    // Define color scheme to match React :root variables
    const Color primary = Color(0xFF6E45E2);
    const Color secondary = Color(0xFF89D4CF);
    const Color textDark = Color(0xFF1A1A1A);
    const Color textLight = Color(0xFFA4A6B3);
    const Color white = Color(0xFFFFFFFF);
    const Color sidebarBg = Color(0xFF2A3042);
    const Color shadowColor = Color.fromRGBO(0, 0, 0, 0.1);
    const Color logoutBg = Color.fromRGBO(231, 76, 60, 0.1);
    const Color logoutHoverBg = Color.fromRGBO(231, 76, 60, 0.2);
    const Color logoutColor = Color(0xFFE74C3C);
    const Color logoutHoverColor = Color(0xFFFF6B6B);

    return FutureBuilder<AppUser?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Utilisateur non trouvé'));
        }

        final user = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated gradient background
                AnimatedContainer(
                  duration: const Duration(seconds: 10),
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      center: Alignment.center,
                      colors: [
                        primary.withOpacity(0.1),
                        secondary.withOpacity(0.1),
                        Colors.pink.withOpacity(0.1),
                        primary.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                
                // Main content
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header with profile picture
                      Container(
                        padding: const EdgeInsets.only(top: 50, bottom: 30),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primary, secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: shadowColor.withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _getImageProvider(user.image),
                                child: _getImageProvider(user.image) == null
                                    ? Icon(Icons.person,
                                        size: 60, color: textLight)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${user.firstName ?? ''} ${user.lastName ?? ''}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile details
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(25),
                              child: Column(
                                children: [
                                  _buildProfileItem(
                                    context,
                                    Icons.person_outline,
                                    'Nom complet',
                                    user.fullName,
                                    white,
                                    white.withOpacity(0.7),
                                  ),
                                  const Divider(
                                    height: 30,
                                    thickness: 0.5,
                                    color: Colors.white30,
                                  ),
                                  _buildProfileItem(
                                    context,
                                    Icons.email_outlined,
                                    'Email',
                                    user.email,
                                    white,
                                    white.withOpacity(0.7),
                                  ),
                                  const Divider(
                                    height: 30,
                                    thickness: 0.5,
                                    color: Colors.white30,
                                  ),
                                  _buildProfileItem(
                                    context,
                                    Icons.work_outline,
                                    'Rôle',
                                    _formatRole(user.role),
                                    white,
                                    white.withOpacity(0.7),
                                  ),
                                  const Divider(
                                    height: 30,
                                    thickness: 0.5,
                                    color: Colors.white30,
                                  ),
                                  _buildProfileItem(
                                    context,
                                    Icons.verified_outlined,
                                    'Statut',
                                    user.isApproved ? 'Approuvé' : 'En attente',
                                    user.isApproved ? Colors.green : Colors.orange,
                                    white.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Edit profile action
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: primary.withOpacity(0.5),
                                ),
                                child: const Text(
                                  'MODIFIER LE PROFIL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Logout action
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: logoutBg,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, color: logoutColor),
                                    const SizedBox(width: 10),
                                    Text(
                                      'DÉCONNEXION',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: logoutColor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
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
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color labelColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6E45E2).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ImageProvider? _getImageProvider(String? image) {
    if (image == null || image.isEmpty) return null;
    if (image.startsWith('data:image')) {
      try {
        final base64String = image.split(',').last;
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error decoding Base64 image: $e');
        return null;
      }
    }
    try {
      return NetworkImage(image);
    } catch (e) {
      debugPrint('Error loading network image: $e');
      return null;
    }
  }

  String _formatRole(String role) {
    if (role.isEmpty) return 'Non spécifié';
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }
}