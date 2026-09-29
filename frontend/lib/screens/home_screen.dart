import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/call_record.dart';
import '../services/api_service.dart';
import '../widgets/risk_badge.dart';
import 'active_call_screen.dart';
import 'caller_lookup_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CallRecord> _callHistory = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final history = await ApiService.getCallHistory(limit: 20);
    final stats = await ApiService.getSecurityStats();
    setState(() {
      _callHistory = history;
      _stats = stats;
      _isLoading = false;
    });
  }

  void _simulateCall({
    required String phoneNumber,
    required String callerName,
    required bool isDeepfake,
    required String sampleTranscript,
    required String riskLevel,
    required double riskScore,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActiveCallScreen(
          phoneNumber: phoneNumber,
          callerName: callerName,
          initialRiskLevel: riskLevel,
          initialRiskScore: riskScore,
          isDeepfakeSimulation: isDeepfake,
          simulationTranscript: sampleTranscript,
        ),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _showSimulationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulate Incoming Call Test',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test real-time deepfake audio detection, AI screening, and dynamic risk scoring:',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEF4444),
                  child: Icon(Icons.gpp_bad, color: Colors.white),
                ),
                title: const Text('🔴 High Risk: IRS Tax Extortion Scam', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Requests OTP & immediate gift card transfer', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _simulateCall(
                    phoneNumber: '+18005550199',
                    callerName: 'IRS Tax Relief Scam',
                    isDeepfake: false,
                    sampleTranscript: 'This is the Federal IRS Police. You have an arrest warrant. Send OTP code now.',
                    riskLevel: 'HIGH',
                    riskScore: 92.0,
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF8B5CF6),
                  child: Icon(Icons.record_voice_over, color: Colors.white),
                ),
                title: const Text('🤖 Deepfake Voice Clone: Family Emergency', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Synthesized AI audio asking for bail money', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _simulateCall(
                    phoneNumber: '+14155552671',
                    callerName: 'Sarah Miller (Mom - Voice Cloned)',
                    isDeepfake: true,
                    sampleTranscript: 'Mom needs help! Send money immediately to this crypto address right now!',
                    riskLevel: 'HIGH',
                    riskScore: 89.0,
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF59E0B),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                ),
                title: const Text('🟡 Medium Risk: Telemarketer / Unknown', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Unverified cold caller', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _simulateCall(
                    phoneNumber: '+13125550178',
                    callerName: 'Apex Telemarketing',
                    isDeepfake: false,
                    sampleTranscript: 'Good afternoon, we have special insurance refinancing options available today.',
                    riskLevel: 'MEDIUM',
                    riskScore: 55.0,
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Icons.verified, color: Colors.white),
                ),
                title: const Text('🟢 Safe: Verified Family / Contact', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Dr. Robert Chen (Contact Whitelist)', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _simulateCall(
                    phoneNumber: '+14155559823',
                    callerName: 'Dr. Robert Chen',
                    isDeepfake: false,
                    sampleTranscript: 'Hello, calling to confirm your appointment for tomorrow at 10 AM.',
                    riskLevel: 'LOW',
                    riskScore: 8.0,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Color(0xFF818CF8), size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'VoxGuard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CallerLookupScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Color(0xFF10B981), size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Active Protection Enabled',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'AI Call Screening & Deepfake Audio Guard running in background',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Metrics Row
              Row(
                children: [
                  _buildStatCard(
                    'Screened',
                    '${_stats?['total_calls_screened'] ?? 0}',
                    Icons.phone_in_talk,
                    const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    'Blocked',
                    '${_stats?['scams_blocked'] ?? 0}',
                    Icons.block,
                    const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    'Deepfakes',
                    '${_stats?['deepfakes_detected'] ?? 0}',
                    Icons.record_voice_over,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showSimulationDialog,
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                  label: const Text('Test Incoming Call Simulation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Call Security Logs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Call Logs',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _loadDashboardData,
                    child: const Text('Refresh', style: TextStyle(color: Color(0xFF818CF8))),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_callHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No call logs recorded yet.', style: TextStyle(color: Colors.white60)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _callHistory.length,
                  itemBuilder: (context, index) {
                    final call = _callHistory[index];
                    return _buildCallLogItem(call);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLogItem(CallRecord call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: RiskBadge(
          riskLevel: call.riskLevel,
          score: call.finalRiskScore,
          isDeepfake: call.isDeepfake,
          animatePulse: false,
          size: 44,
        ),
        title: Text(
          call.callerName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(call.callerNumber, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            if (call.scamDetected)
              Text(
                'Scam: ${call.scamCategory ?? "Detected"}',
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
              )
            else if (call.isDeepfake)
              const Text(
                'AI Synthetic Voice Flagged',
                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('hh:mm a').format(call.timestamp),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: call.status == 'blocked'
                    ? const Color(0xFFEF4444).withOpacity(0.2)
                    : const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                call.status.toUpperCase(),
                style: TextStyle(
                  color: call.status == 'blocked' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
