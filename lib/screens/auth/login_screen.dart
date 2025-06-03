import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  String _errorMessage = '';
  bool _showForgotPassword = false;
  bool _resetSent = false;
  bool _canResend = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_validateEmail(email)) {
      setState(() {
        _errorMessage = email.isEmpty
            ? 'Veuillez entrer votre email'
            : 'Veuillez entrer une adresse email valide';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _resetSent = true;
        _canResend = false;
      });
      Future.delayed(Duration(seconds: 30), () {
        setState(() => _canResend = true);
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Aucun compte trouvé avec cet email';
          break;
        case 'invalid-email':
          msg = 'Format d\'email invalide';
          break;
        case 'too-many-requests':
          msg = 'Trop de tentatives. Réessayez plus tard';
          break;
        default:
          msg = e.message ?? "Erreur lors de l'envoi";
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Email invalide';
      default:
        return 'Échec de la connexion';
    }
  }

  bool _validateEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email.toLowerCase());
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0C89E2), Color(0xFFE280A1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    label,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _resetAdviceBox() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Si vous ne recevez pas l\'email :',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 8),
          Text(
            '• Vérifiez votre dossier spam\n'
            '• Patientez quelques minutes\n'
            '• Assurez-vous que l\'adresse est correcte',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/image/logo.jpg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Circular logo with fixed size
    Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        image: DecorationImage(
          image: AssetImage('assets/image/logo.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    SizedBox(width: 10),
    // Title column with flexible constraints
    Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SGICH',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Système de gestion des interventions chirurgicales',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            softWrap: true,
          ),
        ],
      ),
    ),
  ],
),
                          SizedBox(height: 30),
                          if (!_showForgotPassword) ...[
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration('Email'),
                              style: TextStyle(color: Colors.white),
                              validator: (value) => value!.isEmpty ? 'Entrez votre email' : null,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: _inputDecoration('Mot de passe'),
                              style: TextStyle(color: Colors.white),
                              validator: (value) =>
                                  value!.isEmpty ? 'Entrez votre mot de passe' : null,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) => setState(() => _rememberMe = val!),
                                  activeColor: Colors.cyanAccent,
                                ),
                                Flexible(
                                  child: Text(
                                    'Se souvenir de moi',
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Spacer(),
                                Flexible(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showForgotPassword = true;
                                        _resetSent = false;
                                      });
                                    },
                                    child: Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _actionButton('Connexion', _login),
                          ] else if (!_resetSent) ...[
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration('Email professionnel'),
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 20),
                            _actionButton(
                                _canResend ? 'Envoyer le lien' : 'Veuillez patienter',
                                _canResend ? _resetPassword : null),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showForgotPassword = false;
                                  _resetSent = false;
                                });
                              },
                              child: Text('Retour à la connexion',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ] else ...[
                            Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                            SizedBox(height: 10),
                            Text('Lien envoyé à ${_emailController.text}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white)),
                            SizedBox(height: 16),
                            _resetAdviceBox(),
                            SizedBox(height: 16),
                            _actionButton('Retour à la connexion', () {
                              setState(() {
                                _showForgotPassword = false;
                                _resetSent = false;
                              });
                            }),
                          ],
                          if (_errorMessage.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text(_errorMessage, style: TextStyle(color: Colors.redAccent)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}