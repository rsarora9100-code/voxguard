import 'package:flutter/material.dart';
import '../models/caller_info.dart';
import '../services/api_service.dart';
import '../widgets/risk_badge.dart';

class CallerLookupScreen extends StatefulWidget {
  const CallerLookupScreen({Key? key}) : super(key: key);

  @override
  State<CallerLookupScreen> createState() => _CallerLookupScreenState();
}

class _CallerLookupScreenState extends State<CallerLookupScreen> {
  final TextEditingController _searchController = TextEditingController(text: '+18005550199');
  CallerInfo? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _performLookup() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    final info = await ApiService.lookupCaller(query);
    setState(() {
      _result = info;
      _isLoading = false;
      if (info == null) _error = 'Failed to lookup phone number. Check backend connection.';
    });
  }

  void _showReportDialog() {
    final catController = TextEditingController(text: 'Financial Fraud');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Report Caller as Spam', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: catController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Spam Category',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () async {
                Navigator.pop(context);
                final success = await ApiService.reportSpam(
                  phoneNumber: _searchController.text.trim(),
                  category: catController.text.trim(),
                  description: descController.text.trim(),
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted successfully!')),
                  );
                  _performLookup();
                }
              },
              child: const Text('Submit Report'),
            ),
          ],
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
        title: const Text('Caller ID & Risk Lookup', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      hintText: 'Enter phone number (+1...)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _performLookup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lookup'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444)))
            else if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _result!.riskLevel == 'HIGH'
                        ? const Color(0xFFEF4444).withOpacity(0.5)
                        : const Color(0xFF10B981).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    RiskBadge(
                      riskLevel: _result!.riskLevel,
                      score: _result!.baseRiskScore,
                      size: 72,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result!.nameTag,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result!.phoneNumber,
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 8),

                    _buildInfoRow('Category', _result!.category),
                    _buildInfoRow('Community Reports', '${_result!.reportsCount} users'),
                    _buildInfoRow('Recommendation', _result!.recommendation),
                    _buildInfoRow('Contact Whitelist', _result!.isWhitelisted ? 'Yes (Trusted)' : 'No'),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showReportDialog,
                        icon: const Icon(Icons.report_problem, color: Color(0xFFEF4444)),
                        label: const Text('Report Caller as Spam', style: TextStyle(color: Color(0xFFEF4444))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
