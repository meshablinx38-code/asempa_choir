import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _voicePart = 'SOPRANO';
  bool _loading = false, _obscurePass = true;
  String? _error;

  static const _parts = ['SOPRANO','ALTO','TENOR','BASS','PIANO','DRUMS','GUITAR'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).register(
        name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(),
        password: _passCtrl.text, phone: _phoneCtrl.text.trim(),
        voicePart: _voicePart);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account created! Awaiting admin approval.')));
        context.go('/home');
      }
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.contains('email-already-in-use')
          ? 'This email is already registered.'
          : 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(children: [
            const Icon(Icons.music_note, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            const Text('Join Asempa Choir',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            Text('Create your account',
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(controller: _nameCtrl, textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined), hintText: '+233...'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _voicePart,
                  decoration: const InputDecoration(labelText: 'Voice / Instrument',
                      prefixIcon: Icon(Icons.music_note_outlined)),
                  items: _parts.map((p) => DropdownMenuItem(value: p,
                      child: Row(children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: voicePartColor(p), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(p),
                      ]))).toList(),
                  onChanged: (v) => setState(() => _voicePart = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(controller: _passCtrl, obscureText: _obscurePass,
                    decoration: InputDecoration(labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass))),
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ])),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 14),
                Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Your account needs admin approval before full access.',
                        style: TextStyle(color: AppColors.info, fontSize: 12))),
                    ])),
              ])),
            ),
          ]),
        ),
      ),
    );
  }
}