import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/screens/intro_screen.dart';
import 'package:horizon_protocol/services/audio_service.dart';

class TestSelectionScreen extends StatefulWidget {
  const TestSelectionScreen({super.key});

  @override
  State<TestSelectionScreen> createState() => _TestSelectionScreenState();
}

class _TestSelectionScreenState extends State<TestSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeController.forward();
    AudioService().playPowerOn();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          FadeTransition(
            opacity: _fadeController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  _buildHeader(),
                  const SizedBox(height: 60),
                  Text(
                    "MÜSAİT PROTOKOLLER",
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTestCard(
                          title: "Horizon Core Protocol",
                          subtitle: "Genesis Prime Assessment (Demo)",
                          description: "13 Kritik Bölümden oluşan temel bilişsel ve davranışsal analiz modülü. Stres toleransı, karar hızı ve etik önceliklendirme ölçümü.",
                          isLocked: false,
                          onTap: () {
                            AudioService().playTypingBeep();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const IntroScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 25),
                        _buildTestCard(
                          title: "Cognitive Nexus Suite",
                          subtitle: "Advanced Neural Mapping",
                          description: "Çok katmanlı problem çözme ve soyut mantık yürütme protokolü. Üst düzey yönetim kademeleri için derinlemesine analiz.",
                          isLocked: true,
                        ),
                        const SizedBox(height: 25),
                        _buildTestCard(
                          title: "Neural Integrity Matrix",
                          subtitle: "Ethical Resilience Test",
                          description: "Sistemik risk yönetimi ve kriz anında dürüstlük/şeffaflık ölçümleme protokolü.",
                          isLocked: true,
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PROTOKOL SEÇİMİ",
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "SİSTEM ÇEVRİMİÇİ // ERİŞİM YETKİSİ ONAYLANDI",
              style: GoogleFonts.sourceCodePro(
                color: AppTheme.neonCyan.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.security, color: AppTheme.neonCyan, size: 24),
        ),
      ],
    );
  }

  Widget _buildTestCard({
    required String title,
    required String subtitle,
    required String description,
    required bool isLocked,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLocked ? Colors.white.withOpacity(0.01) : AppTheme.neonCyan.withOpacity(0.03),
          border: Border.all(
            color: isLocked ? Colors.white10 : AppTheme.neonCyan.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                        color: isLocked ? Colors.white24 : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.sourceCodePro(
                        color: isLocked ? Colors.white10 : AppTheme.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (isLocked)
                  const Icon(Icons.lock_outline, color: Colors.white10, size: 24)
                else
                  const Icon(Icons.arrow_forward_ios, color: AppTheme.neonCyan, size: 16),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: GoogleFonts.inter(
                color: isLocked ? Colors.white.withOpacity(0.05) : Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (!isLocked) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "ERİŞİLEBİLİR",
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.neonCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white24;
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint..strokeWidth = 0.2);
    }
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint..strokeWidth = 0.2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
