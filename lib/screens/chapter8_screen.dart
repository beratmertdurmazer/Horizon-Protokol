import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/chapter9_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';

class Chapter8Screen extends StatefulWidget {
  const Chapter8Screen({super.key});

  @override
  State<Chapter8Screen> createState() => _Chapter8ScreenState();
}

class _Chapter8ScreenState extends State<Chapter8Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  Timer? _countdownTimer;
  Timer? _vibrationTimer;
  int _secondsRemaining = 30;
  bool _isFinished = false;
  
  late AnimationController _shakeController;
  late AnimationController _windController;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 50))..repeat(reverse: true);
    _windController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    
    _startCountdown();
    _startEffects();
    PersonaMR().startChapterTimer("Bölüm 8: Dış Gövde Çatlağı");
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isFinished || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _endChapter("TIMEOUT");
        }
      });
    });
  }

  void _startEffects() {
    AudioService().playStructuralShake();
    _vibrationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isFinished || !mounted) {
        timer.cancel();
        return;
      }
      AudioService().playVacuumHiss();
      if (_secondsRemaining < 10) AudioService().playStructuralShake();
    });
  }

  void _handleDecision(String choice) {
    PersonaMR().recordInteraction("Bölüm 8: Dış Gövde Çatlağı", "DECISION_MADE", metadata: {"choice": choice});
    _endChapter(choice);
  }

  void _endChapter(String choice) {
    if (_isFinished) return;
    setState(() => _isFinished = true);
    _stopwatch.stop();
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
    AudioService().stopAll();
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 8: Dış Gövde Çatlağı",
      choiceId: choice,
      durationMs: totalTime,
      triggers: ["hull_breach", choice.toLowerCase()],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 8: Dış Gövde Çatlağı",
      totalTimeMs: totalTime,
      additionalData: {
        "reactionTimeMs": totalTime,
        "finalResult": choice,
      },
    );

    _showResult(choice);
  }

  void _showResult(String result) {
    String title = "";
    String desc = "";
    IconData icon = Icons.info;
    Color color = Colors.white;

    switch (result) {
      case "OXYGEN_MASK":
        title = "GÜVENLİ PROTOKOL";
        desc = "Önce can güvenliğini sağladın. Oksijen maskesi ile sızıntıya müdahale şansın arttı.";
        icon = Icons.air_outlined;
        color = AppTheme.neonCyan;
        break;
      case "BREACH_AREA":
        title = "GÖRÜŞ KAYBI / BİLİNÇ SİLİNDİRİ";
        desc = "Korunmasızca sızıntıya koştun. Oksijensizlikten ciğerlerin yanıyor ve görüşün kararıyor. (Kalıcı Bilişsel Hasar Riski)";
        icon = Icons.visibility_off;
        color = Colors.red;
        break;
      case "TIMEOUT":
        title = "KRİTİK HATA";
        desc = "Karar veremedin. Basınç kaybı istasyonu boşluğa sürükledi.";
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: BorderSide(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 60),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.rajdhani(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
                      completedChapterTitle: "Bölüm 8: Dış Gövde Çatlağı",
                      nextChapterHint: "Basınç stabilize edildi. Son analiz bekleniyor.",
                      nextScreen: Chapter9Screen(),
                    )),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.2), side: BorderSide(color: color)),
                child: Text("DEVAM ET", style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
    _shakeController.dispose();
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          double offset = (_secondsRemaining < 10) ? _shakeController.value * 5 : _shakeController.value * 2;
          return Transform.translate(
            offset: Offset(offset, offset),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                "assets/images/chapter8_background.png",
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.85),
                colorBlendMode: BlendMode.darken,
              ),
            ),

            // Wind/Debris Effect
            Positioned.fill(
              child: _buildWindEffect(),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const Spacer(),
                    _buildNarrative(),
                    const SizedBox(height: 40),
                    _buildDecisionMaps(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            const DevNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildWindEffect() {
    return AnimatedBuilder(
      animation: _windController,
      builder: (context, child) {
        return CustomPaint(
          painter: WindPainter(progress: _windController.value),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("BÖLÜM 8: DIŞ GÖVDE ÇATLAĞI", style: GoogleFonts.rajdhani(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text("BASINÇ KAYBI: KRİTİK SEVİYE", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
          ],
        ),
        _buildTimer(),
      ],
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(4)),
      child: Text("${_secondsRemaining}S", style: GoogleFonts.sourceCodePro(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNarrative() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), border: Border.all(color: Colors.red.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
      child: Text(
        "\"Gövde delindi! Hava hızla boşluğa kaçıyor. Operatör, ya kendini güvene al (Maske) ya da doğrudan tehlikeye koş (Sızıntı). Karar ver!\"",
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: Colors.white, height: 1.6, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildDecisionMaps() {
    return Row(
      children: [
        Expanded(
          child: _buildMapCard(
            "OKSİJEN MASKESİ",
            "BÖLME 12-A / LOJİSTİK",
            Icons.masks,
            AppTheme.neonCyan,
            () => _handleDecision("OXYGEN_MASK"),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMapCard(
            "SIZINTI BÖLGESİ",
            "BÖLME 04-F / DIŞ GÖVDE",
            Icons.warning_amber,
            Colors.orange,
            () => _handleDecision("BREACH_AREA"),
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 50),
            const SizedBox(height: 15),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.rajdhani(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(sub, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 9)),
            const SizedBox(height: 15),
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.2))),
              child: Center(child: Text("HARİTA", style: GoogleFonts.sourceCodePro(color: color, fontSize: 10))),
            ),
          ],
        ),
      ),
    );
  }
}

class WindPainter extends CustomPainter {
  final double progress;
  WindPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      double y = random.nextDouble() * size.height;
      double startX = (random.nextDouble() * size.width + progress * size.width) % size.width;
      canvas.drawLine(Offset(startX, y), Offset(startX + 50, y), paint);
    }
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) => true;
}
