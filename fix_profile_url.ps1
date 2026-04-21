# Profile screen - photo via URL input (no Firebase Storage needed)

function Write-File($path, $content) {
    $dir = Split-Path $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  fixed: $path" -ForegroundColor Cyan
}

Write-File "lib\features\profile\profile_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _initialized = false;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _photoUrlCtrl;
  String? _voicePart;

  static const _parts = [
    'SOPRANO', 'ALTO', 'TENOR', 'BASS', 'PIANO', 'DRUMS', 'GUITAR'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _photoUrlCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  String _normalizeVoicePart(String vp) {
    final upper = vp.toUpperCase().trim();
    return _parts.contains(upper) ? upper : 'SOPRANO';
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    final photoUrl = _photoUrlCtrl.text.trim();
    await ref.read(firestoreServiceProvider).updateProfile(
      uid: uid,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      voicePart: _voicePart,
      photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
    );
    setState(() {
      _saving = false;
      _editing = false;
      _initialized = false;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Profile updated successfully!'),
        ]),
        backgroundColor: AppColors.success,
      ));
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _initialized = false;
    });
  }

  void _showPhotoUrlDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Profile Photo'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Paste a direct image URL from any image hosting site '
            '(e.g. ibb.co, imgur.com, drive.google.com)',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _photoUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://i.ibb.co/...',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 8),
          // Preview
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _photoUrlCtrl,
            builder: (_, v, __) {
              if (v.text.trim().isEmpty) return const SizedBox();
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(v.text.trim(),
                  height: 100, width: 100, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100, width: 100,
                    decoration: BoxDecoration(color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.broken_image, color: AppColors.textHint),
                  ),
                ),
              );
            },
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); setState(() {}); },
            child: const Text('Use This Photo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await ref.read(authServiceProvider).signOut();
                if (mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox();

          if (!_initialized) {
            _nameCtrl.text = user.name;
            _phoneCtrl.text = user.phone;
            _photoUrlCtrl.text = user.photoUrl ?? '';
            _voicePart = _normalizeVoicePart(user.voicePart);
            _initialized = true;
          }

          final effectiveVoicePart = _voicePart ?? _normalizeVoicePart(user.voicePart);
          final displayPhotoUrl = _photoUrlCtrl.text.trim().isNotEmpty
              ? _photoUrlCtrl.text.trim()
              : user.photoUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [

              // ── Avatar ────────────────────────────────────────────────────
              Stack(alignment: Alignment.bottomRight, children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: voicePartColor(effectiveVoicePart).withOpacity(0.4),
                      width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: voicePartColor(effectiveVoicePart).withOpacity(0.15),
                    backgroundImage: (displayPhotoUrl != null && displayPhotoUrl.isNotEmpty)
                        ? NetworkImage(displayPhotoUrl) : null,
                    onBackgroundImageError: (_, __) {},
                    child: (displayPhotoUrl == null || displayPhotoUrl.isEmpty)
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700,
                                color: voicePartColor(effectiveVoicePart)))
                        : null,
                  ),
                ),
                if (_editing)
                  GestureDetector(
                    onTap: _showPhotoUrlDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),

              if (!_editing) ...[
                Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: voicePartColor(effectiveVoicePart).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(effectiveVoicePart,
                      style: TextStyle(color: voicePartColor(effectiveVoicePart),
                          fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 24),

              // ── Edit form ──────────────────────────────────────────────────
              if (_editing) ...[
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _voicePart,
                  decoration: const InputDecoration(
                    labelText: 'Voice / Instrument',
                    prefixIcon: Icon(Icons.music_note_outlined)),
                  items: _parts.map((p) => DropdownMenuItem(
                    value: p,
                    child: Row(children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(
                              color: voicePartColor(p), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(p),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() => _voicePart = v),
                ),
                const SizedBox(height: 12),
                // Photo URL hint
                GestureDetector(
                  onTap: _showPhotoUrlDialog,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(children: [
                      const Icon(Icons.image_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          _photoUrlCtrl.text.trim().isNotEmpty
                              ? 'Photo URL set — tap to change'
                              : 'Tap to set a photo URL',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      ])),
                      Icon(
                        _photoUrlCtrl.text.trim().isNotEmpty
                            ? Icons.check_circle : Icons.chevron_right,
                        color: _photoUrlCtrl.text.trim().isNotEmpty
                            ? AppColors.success : AppColors.textHint,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: _saving ? null : _cancelEdit,
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(user.uid),
                    child: _saving
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes'),
                  )),
                ]),

              // ── View mode ──────────────────────────────────────────────────
              ] else ...[
                _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
                _InfoTile(icon: Icons.phone_outlined, label: 'Phone',
                    value: user.phone.isNotEmpty ? user.phone : 'Not set'),
                if (user.hostel != null && user.hostel!.isNotEmpty)
                  _InfoTile(icon: Icons.home_outlined, label: 'Hostel', value: user.hostel!),
                if (user.level != null && user.level!.isNotEmpty)
                  _InfoTile(icon: Icons.school_outlined, label: 'Level', value: user.level!),
                if (user.memberType != null && user.memberType!.isNotEmpty)
                  _InfoTile(icon: Icons.category_outlined, label: 'Member Type',
                      value: user.memberType!),
                _InfoTile(icon: Icons.calendar_today_outlined, label: 'Joined',
                    value: DateFormat('dd/MM/yyyy').format(user.joinedAt)),
                _InfoTile(icon: Icons.check_circle_outline, label: 'Attendance',
                    value: '${user.attendanceCount} sessions'),
                _InfoTile(icon: Icons.local_fire_department_outlined, label: 'Streak',
                    value: '${user.streak} days'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                ),
              ],
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider.withOpacity(0.5)),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ])),
    ]),
  );
}
'@

Write-Host ""
Write-Host "Profile with photo URL done!" -ForegroundColor Green
Write-Host "Press 'r' to hot reload" -ForegroundColor Yellow
