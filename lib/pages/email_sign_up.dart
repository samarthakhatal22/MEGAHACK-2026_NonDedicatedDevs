import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';

class EmailSignUpPage extends StatefulWidget {
  const EmailSignUpPage({super.key});

  @override
  State<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends State<EmailSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ministryController = TextEditingController();
  final _roleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create the user in Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // 2. Save additional profile details to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'ministry': _ministryController.text.trim(),
          'role': _roleController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Update the display name in Firebase Auth (optional but good practice)
        await user.updateDisplayName(_fullNameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created for ${user?.email}!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ministryController.dispose();
    _roleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create an Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              
              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),

              // Ministry Field
              TextFormField(
                controller: _ministryController,
                decoration: const InputDecoration(
                  labelText: 'Ministry / Organization',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your ministry' : null,
              ),
              const SizedBox(height: 16),

              // Role Field
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your role' : null,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => value != null && value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please confirm your password' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading 
                      ? const CircularProgressIndicator() 
                      : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
