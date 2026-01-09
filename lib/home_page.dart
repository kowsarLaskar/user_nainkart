import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:nainkart_user/api_services/home_page_api_services.dart';
import 'package:nainkart_user/astro_model.dart';
import 'package:nainkart_user/bottomnavigation_screens/audio_screen.dart';
import 'package:nainkart_user/bottomnavigation_screens/chat_screen.dart';
import 'package:nainkart_user/bottomnavigation_screens/video_screen.dart';
import 'package:nainkart_user/consult_services/consult.dart';
import 'package:nainkart_user/drawer.dart';
import 'package:nainkart_user/provider/wallet_provider.dart';
import 'package:nainkart_user/wallet_utils/wallet_recharge.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<dynamic> sliderData = [];
  List<Astrologer> astrologers = [];
  late HomePageApiServices homePageApiServices;
  Timer? _statusPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    homePageApiServices = HomePageApiServices();
    fetchInitialData();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _stopStatusPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startStatusPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopStatusPolling();
    }
  }

  Future<void> fetchInitialData() async {
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.fetchWallet(widget.token);

      final sliders = await homePageApiServices.fetchSliders(widget.token);
      final astro = await homePageApiServices.fetchAstrologers(widget.token);

      setState(() {
        sliderData = sliders;
        astrologers = astro;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in fetchInitialData: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  void _startStatusPolling() {
    _stopStatusPolling();
    _fetchAstrologerStatus();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchAstrologerStatus();
    });
  }

  void _stopStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
  }

  Future<void> _fetchAstrologerStatus() async {
    try {
      final updatedAstrologers =
          await homePageApiServices.fetchAstrologers(widget.token);
      if (!mounted) return;

      setState(() => astrologers = updatedAstrologers);
    } catch (e) {
      debugPrint('Error polling astrologer status: $e');
    }
  }

  void _showConsultationDialog(BuildContext context, String consultationType,
      double price, int astrologerId, String astrologerName, bool isOnline) {
    if (!isOnline) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Astrologer Offline'),
            content: Text(
                'Oops! Currently $astrologerName is offline at this moment.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$consultationType Consultation'),
          content: Text(
              'Price: ₹${price.toStringAsFixed(2)} per minute\n\nDo you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsultationPage(
                      astologerName: astrologerName,
                      astroUserId: astrologerId,
                      token: widget.token,
                      consultationType: consultationType.toLowerCase(),
                    ),
                  ),
                );
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final walletAmount = walletProvider.walletAmount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Home",
          style: TextStyle(color: Colors.purple, fontSize: 24),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.purple),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.purple),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              fetchInitialData();
            },
          ),
        ],
      ),
      drawer: AppDrawer(token: widget.token),
      body: Column(
        children: [
          Expanded(
            child: _isLoading || walletProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Wallet Section (unchanged)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6)
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: Colors.white, size: 40),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Wallet Balance",
                                    style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text("₹$walletAmount",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => WalletRechargePage(
                                            token: widget.token,
                                            currentBalance: walletAmount,
                                          )),
                                ).then((_) {
                                  walletProvider.fetchWallet(widget.token);
                                });
                              },
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              splashRadius: 20,
                              tooltip: 'Add money to wallet',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Slider Section (unchanged)
                      if (sliderData.isNotEmpty)
                        CarouselSlider(
                          options:
                              CarouselOptions(height: 150.0, autoPlay: true),
                          items: sliderData.map((slider) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[200],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      '${homePageApiServices.imageBaseUrl}${slider['image']}',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.purple[100],
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                    Icons.image_not_supported,
                                                    size: 40),
                                                Text(
                                                  slider['title'],
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Generate Kundli Button (unchanged)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/generate-kundli',
                              arguments: widget.token,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Generate Your Kundli',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Services Header
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Our Services",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple)),
                            Text("View All",
                                style: TextStyle(color: Colors.purple)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Astrologer List - UPDATED FOR MODEL
                      if (astrologers.isNotEmpty)
                        ...astrologers.map((astro) {
                          return Column(
                            children: [
                              _buildServiceCard(
                                astrologer: astro,
                                onChatPressed: () => _showConsultationDialog(
                                  context,
                                  'Chat',
                                  astro.chatCharge,
                                  astro.userId,
                                  astro.name,
                                  astro.isOnline,
                                ),
                                onCallPressed: () => _showConsultationDialog(
                                  context,
                                  'Audio',
                                  astro.audioCallCharge,
                                  astro.userId,
                                  astro.name,
                                  astro.isOnline,
                                ),
                                onVideoPressed: () => _showConsultationDialog(
                                  context,
                                  'Video',
                                  astro.videoCallCharge,
                                  astro.userId,
                                  astro.name,
                                  astro.isOnline,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
          ),
          // Bottom Navigation Panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomIcon(
            Icons.chat,
            "",
            Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    token: widget.token,
                    astrologers: astrologers,
                  ),
                ),
              );
            },
          ),
          _buildBottomIcon(
            Icons.call,
            "",
            Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioScreen(
                    token: widget.token,
                    astrologers: astrologers,
                  ),
                ),
              );
            },
          ),
          _buildBottomIcon(
            Icons.video_call,
            "",
            Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoScreen(
                    token: widget.token,
                    astrologers: astrologers,
                  ),
                ),
              );
            },
          ),
          _buildBottomIcon(
            Icons.temple_hindu,
            "",
            Colors.orange,
            onTap: () =>
                Navigator.pushNamed(context, '/pooja', arguments: widget.token),
          ),
          _buildBottomIcon(
            Icons.shopping_bag,
            "",
            Colors.red,
            onTap: () => Navigator.pushNamed(context, '/products',
                arguments: widget.token),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required Astrologer astrologer,
    required VoidCallback onChatPressed,
    required VoidCallback onCallPressed,
    required VoidCallback onVideoPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.purple.shade100]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple[100],
                child: ClipOval(
                  child: astrologer.image != null
                      ? Image.network(
                          '${homePageApiServices.imageBaseUrl}${astrologer.image}',
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(astrologer.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(astrologer.skills ?? '',
                        style: const TextStyle(fontSize: 14)),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 10,
                            color: astrologer.isOnline
                                ? Colors.green
                                : Colors.grey),
                        const SizedBox(width: 4),
                        Text(astrologer.isOnline ? "Online" : "Offline",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildServiceOption(
                  Icons.chat,
                  "Chat",
                  "₹${astrologer.chatCharge.toStringAsFixed(2)}/min",
                  onChatPressed),
              _buildServiceOption(
                  Icons.call,
                  "Call",
                  "₹${astrologer.audioCallCharge.toStringAsFixed(2)}/min",
                  onCallPressed),
              _buildServiceOption(
                  Icons.video_call,
                  "Video",
                  "₹${astrologer.videoCallCharge.toStringAsFixed(2)}/min",
                  onVideoPressed),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildServiceOption(
      IconData icon, String label, String rate, VoidCallback onPressed) {
    Color color;
    switch (label) {
      case "Chat":
        color = Colors.blue.shade100;
        break;
      case "Call":
        color = Colors.green.shade100;
        break;
      case "Video":
        color = Colors.purple.shade100;
        break;
      default:
        color = Colors.grey.shade100;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 90,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label),
            Text(rate, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, String label, Color color,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
