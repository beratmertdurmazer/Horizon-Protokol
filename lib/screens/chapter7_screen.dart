import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/chapter8_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';
import 'package:horizon_protocol/screens/chapter9_screen.dart';

class Chapter7Screen extends StatefulWidget {
  const Chapter7Screen({super.key});

  @override
  State<Chapter7Screen> createState() => _Chapter7ScreenState();
}

class _Chapter7ScreenState extends State<Chapter7Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  late Stopwatch _decisionStopwatch;
  Timer? _countdownTimer;
  Timer? _grindTimer;
  int _secondsRemaining = 180;
  int _bluePressCount = 0;
  int _errorCount = 0;
  bool _isFinished = false;
  
  late AnimationController _binaryScrollController;
  late AnimationController _flickerController;

  // Binary for "mavi butona iki kez bas" (repeating)
  final String _binaryText = "01101101 01100001 01110110 01101001 00100000 01100010 01110101 01110100 01101111 01101110 01100001 00100000 01101001 01101011 01101001 00100000 01101011 01100101 01111010 00100000 01100010 01100001 01110011 ";

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _decisionStopwatch = Stopwatch()..start();
    _binaryScrollController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))..repeat(reverse: true);
    
    _startCountdown();
    _startMetalGrind();
    PersonaMR().startChapterTimer("Bölüm 7: Sistemsel Çöküş");
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
          _endChapter("TIMEOUT_SURFACE_THINKER");
        }
      });
    });
  }

  void _startMetalGrind() {
    _grindTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isFinished || !mounted) {
        timer.cancel();
        return;
      }
      AudioService().playMetalGrind();
    });
  }

  void _handleButtonPress(bool isBlue) {
    if (_isFinished) return;
    AudioService().playTypingBeep();

    if (isBlue) {
      _bluePressCount++;
      PersonaMR().recordInteraction("Bölüm 7: Sistemsel Çöküş", "BLUE_BUTTON_PRESSED", metadata: {"count": _bluePressCount});
      if (_bluePressCount == 2) {
        _endChapter("SUCCESS_ANALYTICAL_DEPTH");
      }
    } else {
      // Red button pressed - failure/impulsive
      _errorCount++;
      PersonaMR().recordInteraction("Bölüm 7: Sistemsel Çöküş", "RED_BUTTON_PRESSED");
      _endChapter("FAIL_IMPULSIVE_RANDOM");
    }
  }

  void _endChapter(String result) {
    if (_isFinished || _isTransitioning) return;
    setState(() {
      _isFinished = true;
      _isTransitioning = true; // Prevent multiple calls during transition
    });
    _decisionStopwatch.stop();
    _stopwatch.stop(); // Stop the overall chapter stopwatch
    _countdownTimer?.cancel();
    _grindTimer?.cancel();
    AudioService().stopAll();
    AudioService().playPowerSurge();

    final totalTime = _stopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 7: Sistemsel Çöküş",
      choiceId: result == "SUCCESS_ANALYTICAL_DEPTH" ? "BINARY_SOLVED" : result, // Log specific choice for success
      durationMs: _decisionStopwatch.elapsedMilliseconds, // Decision specific duration
      triggers: ["binary_puzzle", "stress_30s"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 7: Sistemsel Çöküş",
      totalTimeMs: totalTime,
      additionalData: {
        "errorCount": _errorCount,
        "decisionTimeMs": _decisionStopwatch.elapsedMilliseconds,
        "finalResult": result == "SUCCESS_ANALYTICAL_DEPTH" ? "BINARY_SOLVED" : result,
      },
    );

    _showResult(result);
  }

  void _showResult(String result) {
    bool success = result == "SUCCESS_ANALYTICAL_DEPTH";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: BorderSide(color: success ? AppTheme.neonCyan : Colors.red), borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(success ? Icons.terminal : Icons.report_problem, color: success ? AppTheme.neonCyan : Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                success ? "TERMİNAL ERİŞİMİ ONAYLANDI" : "ERİŞİM REDDEDİLDİ",
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                success 
                  ? "Sinyal karmaşası çözüldü. İşlemci çekirdekleri güvenli modda çalışıyor." 
                  : "Bilinmeyen protokol hatası nedeniyle manuel override başarısız oldu.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
                      completedChapterTitle: "Bölüm 7: Sistemsel Çöküş",
                      nextChapterHint: "Terminal erişimi tamamlandı. Gövde bütünlüğü tehlikede.",
                      nextScreen: Chapter8Screen(),
                    )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (success ? AppTheme.neonCyan : Colors.red).withOpacity(0.2), 
                  side: BorderSide(color: success ? AppTheme.neonCyan : Colors.red)
                ),
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
    _grindTimer?.cancel();
    _binaryScrollController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset("assets/images/chapter7_background.png", fit: BoxFit.cover),
            ),
          ),

          // Binary Matrix Overlay
          Positioned.fill(
            child: _buildBinaryRain(),
          ),

          // Main UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildStatusDisplay(),
                  const Spacer(),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          const DevNav(),
        ],
      ),
    );
  }

  Widget _buildBinaryRain() {
    return AnimatedBuilder(
      animation: _binaryScrollController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.green.withOpacity(0.2), Colors.transparent],
            ).createShader(bounds);
          },
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 20,
            itemBuilder: (context, index) {
              return Text(
                _binaryText * 5,
                style: GoogleFonts.sourceCodePro(color: Colors.green.withOpacity(0.1), fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.clip,
              );
            },
          ),
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
            Text("BÖLÜM 7: SİSTEMSEL ÇÖKÜŞ", style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text("KRİTİK HATA: CPU_OVERHEAT_0x44", style: GoogleFonts.sourceCodePro(color: Colors.red, fontSize: 10)),
          ],
        ),
        _buildTimer(),
      ],
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(4)),
      child: Text("${_secondsRemaining}S", style: GoogleFonts.sourceCodePro(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  Widget _buildStatusDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _flickerController,
            builder: (context, child) {
              return Text(
                "YABANCI SİNYAL TESPİT EDİLDİ",
                style: GoogleFonts.sourceCodePro(color: Colors.green.withOpacity(_flickerController.value), fontSize: 14, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            _binaryText,
            textAlign: TextAlign.center,
            style: GoogleFonts.sourceCodePro(color: Colors.green.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.warning, color: Colors.red, size: 24),
          const SizedBox(height: 10),
          Text("SİSTEM KİLİTLENDİ. MANUEL MÜDAHALE GEREKLİ.", style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildPanicButton("KIRMIZI PROTOKOL", Colors.red, () => _handleButtonPress(false)),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildPanicButton("MAVİ PROTOKOL", Colors.blue, () => _handleButtonPress(true)),
        ),
      ],
    );
  }

  Widget _buildPanicButton(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        side: BorderSide(color: color, width: 2),
        backgroundColor: color.withOpacity(0.05),
      ),
      child: Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
