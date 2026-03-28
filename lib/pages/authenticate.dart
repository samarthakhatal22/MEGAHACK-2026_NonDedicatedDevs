import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'email_sign_in.dart';
import 'email_sign_up.dart';
import 'main_navigation.dart';
import '../widgets/glass_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthenticatePage extends StatefulWidget {
  const AuthenticatePage({super.key});

  @override
  State<AuthenticatePage> createState() => _AuthenticatePageState();
}

class _AuthenticatePageState extends State<AuthenticatePage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted && userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
                ),
              ),
            ).animate().fadeIn(duration: 1.seconds),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shield Icon
                    const Icon(
                      Icons.shield,
                      size: 90,
                      color: Color(0xFF2196F3),
                    ).animate()
                      .fadeIn(duration: 800.ms)
                      .scale(delay: 200.ms, curve: Curves.elasticOut),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      "Civic AI Navigator",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 12),
                    
                    // Subtext
                    Text(
                      "Fight Civic Misinformation\nAccess Government Services Easily",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    
                    const SizedBox(height: 56),

                    // Action Buttons
                    _buildAuthButton(
                      label: "Continue with Google",
                      icon: Icons.login_outlined,
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      isPrimary: false,
                      isLoading: _isLoading,
                      colorScheme: colorScheme,
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 0.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 0.5)),
                      ],
                    ).animate().fadeIn(delay: 900.ms),
                    
                    const SizedBox(height: 16),

                    // Email Buttons
                    _buildAuthButton(
                      label: "Sign In with Email",
                      icon: Icons.email_outlined,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmailSignInPage()),
                      ),
                      isPrimary: false,
                      colorScheme: colorScheme,
                    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 16),

                    _buildAuthButton(
                      label: "Sign Up with Email",
                      icon: Icons.person_add_outlined,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmailSignUpPage()),
                      ),
                      isPrimary: false,
                      isOutlined: true,
                      colorScheme: colorScheme,
                    ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isOutlined = false,
    bool isLoading = false,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: GlassContainer(
        opacity: isPrimary ? 0.2 : (isOutlined ? 0.0 : 0.05),
        borderRadius: 30,
        borderWidth: 1.0,
        borderColor: isOutlined ? colorScheme.onSurface.withOpacity(0.3) : null,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? colorScheme.primary : Colors.transparent,
            foregroundColor: isPrimary ? Colors.black : colorScheme.onSurface,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
