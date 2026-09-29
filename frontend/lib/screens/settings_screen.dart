import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/call_screening_service.dart';
import '../services/overlay_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController(text: ApiService.baseUrl);
  bool _isScreeningRoleHeld = false;
  bool _hasOverlayPermission = false;
  double _deepfakeThreshold = 75.0;
  double _autoBlockThreshold = 70.0;
  String _preferredLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final roleHeld = await CallScreeningService.isScreeningRoleHeld();
    final overlayGranted = await OverlayService.hasPermission();
    setState(() {
      _isScreeningRoleHeld = roleHeld;
      _hasOverlayPermission = overlayGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('VoxGuard Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Android Native Permissions Section
          _buildSectionHeader('ANDROID NATIVE INTEGRATIONS'),
          _buildPermissionTile(
            title: 'Call Screening Service Role',
            subtitle: 'Allows VoxGuard to intercept and screen incoming calls before phone rings',
            isGranted: _isScreeningRoleHeld,
            onTap: () async {
              await CallScreeningService.requestScreeningRole();
              _checkPermissions();
            },
          ),
          const SizedBox(height: 8),
          _buildPermissionTile(
            title: 'SYSTEM_ALERT_WINDOW Overlay',
            subtitle: 'Enables 🟢/🟡/🔴 floating badge directly on top of native phone call screen',
            isGranted: _hasOverlayPermission,
            onTap: () async {
              await OverlayService.requestPermission();
              _checkPermissions();
            },
          ),

          const SizedBox(height: 24),

          // 2. Backend Server Configuration
          _buildSectionHeader('BACKEND & AI INFERENCE SERVER'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FastAPI Backend URL', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'http://10.0.2.2:8000',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    ApiService.setBaseUrl(_urlController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backend URL saved.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: const Text('Update Base URL'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. AI Assistant & Threshold Settings
          _buildSectionHeader('DETECTION SENSITIVITY & THRESHOLDS'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deepfake Synthetic Audio Threshold: ${_deepfakeThreshold.toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Slider(
                  value: _deepfakeThreshold,
                  min: 50.0,
                  max: 95.0,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) => setState(() => _deepfakeThreshold = val),
                ),
                const SizedBox(height: 12),
                Text(
                  'Auto-Block High Risk Score Threshold: ${_autoBlockThreshold.toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Slider(
                  value: _autoBlockThreshold,
                  min: 50.0,
                  max: 95.0,
                  activeColor: const Color(0xFFEF4444),
                  onChanged: (val) => setState(() => _autoBlockThreshold = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isGranted ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          ),
          onPressed: onTap,
          child: Text(isGranted ? 'Active' : 'Enable'),
        ),
      ),
    );
  }
}
