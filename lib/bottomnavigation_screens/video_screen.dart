import 'package:flutter/material.dart';
import 'package:nainkart_user/astro_model.dart';
import 'package:nainkart_user/consult_services/consult.dart';

class VideoScreen extends StatefulWidget {
  final String token;
  final List<Astrologer> astrologers;

  const VideoScreen({
    super.key,
    required this.token,
    required this.astrologers,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late List<Astrologer> filteredAstrologers;

  @override
  void initState() {
    super.initState();
    filteredAstrologers =
        widget.astrologers.where((astro) => astro.videoCallCharge > 0).toList();
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConsultationDialog(Astrologer astro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video Call with ${astro.name}'),
        content: Text(
          'Video Call Rate: ₹${astro.videoCallCharge.toStringAsFixed(2)}/min\n\nDo you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConsultationPage(
                    astroUserId: astro.userId,
                    token: widget.token,
                    consultationType: 'video',
                    astologerName: astro.name,
                  ),
                ),
              );
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _handleAstrologerTap(Astrologer astro) {
    if (!astro.isOnline) {
      _showAlert(
        'Astrologer Offline',
        'Currently ${astro.name} is not available for video calls.',
      );
      return;
    }
    _showConsultationDialog(astro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call Astrologers'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: filteredAstrologers.isEmpty
          ? const Center(
              child: Text('No astrologers available for video calls'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredAstrologers.length,
              itemBuilder: (context, index) {
                final astro = filteredAstrologers[index];
                return _buildAstrologerCard(astro);
              },
            ),
    );
  }

  Widget _buildAstrologerCard(Astrologer astro) {
    final imageUrl = astro.image != null
        ? 'https://astroboon.com/storage/${astro.image}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleAstrologerTap(astro),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple.shade100,
                child: ClipOval(
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.purple[800],
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.purple[800],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      astro.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      astro.skills ?? 'Astrology',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: astro.isOnline ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          astro.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '₹${astro.videoCallCharge.toStringAsFixed(2)}/min',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _handleAstrologerTap(astro),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.videocam,
                        size: 20, color: Colors.white),
                    label: const Text(
                      'Video',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
