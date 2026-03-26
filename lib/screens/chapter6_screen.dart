import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/module_transition_screen.dart';
import 'package:horizon_protocol/screens/chapter7_screen.dart';

class Chapter6Screen extends StatefulWidget {
  const Chapter6Screen({super.key});

  @override
  State<Chapter6Screen> createState() => _Chapter6ScreenState();
}

class _Chapter6ScreenState extends State<Chapter6Screen> with TickerProviderStateMixin {
  int _panicClicks = 0;
  bool _showChoices = false;
  bool _isFinished = false;
  
  final Stopwatch _decisionStopwatch = Stopwatch();
  final math.Random _random = math.Random();
  
  Timer? _chaosTimer;
  Timer? _sirenTimer;
  
  final List<Widget> _popups = [];
  late AnimationController _bgFlashController;

  @override
  void initState() {
    super.initState();
    PersonaMR().startChapterTimer("Bölüm 6: Alarm Yorgunluğu");
    
    _bgFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startChaos();
    });
  }

  void _startChaos() {
    AudioService().playAmbientLoop();
    
    // Spawn random error popups
    _chaosTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted || _isFinished) return;
      setState(() {
        _popups.add(_buildRandomPopup());
        // Keep screen from overloading too much visually
        if (_popups.length > 25) _popups.removeAt(0);
      });
    });

    // Annoying siren sound equivalent (using existing audio service)
    _sirenTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted || _isFinished) return;
      AudioService().playGlitchSound();
    });

    // Show decision modal after 8 seconds of pure chaos
    Timer(const Duration(seconds: 8), () {
      if (mounted && !_isFinished) {
        setState(() {
          _showChoices = true;
        });
        _decisionStopwatch.start();
        PersonaMR().recordInteraction("Bölüm 6: Alarm Yorgunluğu", "DECISION_MODAL_SHOWN");
      }
    });

    PersonaMR().recordInteraction("Bölüm 6: Alarm Yorgunluğu", "CHAOS_STARTED");
  }

  Widget _buildRandomPopup() {
    final double left = _random.nextDouble() * (MediaQuery.of(context).size.width - 200);
    final double top = _random.nextDouble() * (MediaQuery.of(context).size.height - 100);
    
    final errors = [
      "CRITICAL: HULL BREACH",
      "SYS: OXYGEN DEPLETION",
      "WARN: CORE TEMP OVR",
      "ERR: NETWORK FAIL",
      "FATAL: POWER LOSS",
    ];
    
    return Positioned(
      left: left.clamp(0.0, MediaQuery.of(context).size.width - 200),
      top: top.clamp(0.0, MediaQuery.of(context).size.height - 100),
      child: Container(
        width: 180 + _random.nextDouble() * 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("SYSTEM_ERROR", style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                const Icon(Icons.close, color: Colors.white, size: 12),
              ],
            ),
            const Divider(color: Colors.white, height: 10),
            Text(errors[_random.nextInt(errors.length)], style: GoogleFonts.rajdhani(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
            Text("0x${_random.nextInt(999999).toRadixString(16).toUpperCase()}", style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _handleBackgroundTap() {
    if (_isFinished) return;
    setState(() {
      _panicClicks++;
    });
    PersonaMR().recordInteraction("Bölüm 6: Alarm Yorgunluğu", "PANIC_CLICK", metadata: {"count": _panicClicks});
  }

  void _makeDecision(String decision) {
    if (_isFinished) return;
    
    setState(() {
      _isFinished = true;
      _decisionStopwatch.stop();
      _chaosTimer?.cancel();
      _sirenTimer?.cancel();
    });
    
    PersonaMR().recordInteraction("Bölüm 6: Alarm Yorgunluğu", decision == 'isolate' ? "DECISION_ISOLATE" : "DECISION_VIGILANCE");
    
    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 6: Alarm Yorgunluğu",
      choiceId: decision == 'isolate' ? "ISOLATE" : "VIGILANCE",
      durationMs: 8000 + _decisionStopwatch.elapsedMilliseconds,
      triggers: [decision, "alarm_fatigue"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 6: Alarm Yorgunluğu",
      totalTimeMs: 8000 + _decisionStopwatch.elapsedMilliseconds,
      additionalData: {
        "decisionTimeMs": _decisionStopwatch.elapsedMilliseconds,
        "panic_clicks": _panicClicks,
        "finalDecision": decision,
      },
    );
    
    AudioService().stopAll();
    
    // Kısa bir sükunet anı ve sonraki bölüme geçiş
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ModuleTransitionScreen(
          moduleTitle: "BÖLÜM 7",
          moduleSubtitle: "ÇÖKÜŞ",
          objective: "Analiz Bekleniyor...",
          icon: Icons.warning_rounded,
          nextScreen: Chapter7Screen(),
        )));
      }
    });
  }

  @override
  void dispose() {
    _bgFlashController.dispose();
    _chaosTimer?.cancel();
    _sirenTimer?.cancel();
    AudioService().stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleBackgroundTap,
          child: AnimatedBuilder(
            animation: _bgFlashController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _isFinished ? Colors.black : Colors.redAccent.withOpacity(_bgFlashController.value * 0.1),
                ),
                child: Stack(
                  children: [
                    // Arka plan çizgileri
                    CustomPaint(
                      painter: GridPainter(),
                      size: Size.infinite,
                    ),
                    
                    // Kaos Pop-up'ları
                    if (!_isFinished) ..._popups,
                    
                    // Karar Modalı
                    if (_showChoices && !_isFinished)
                      Center(
                        child: GestureDetector(
                          onTap: () {}, // Prevent taps on the modal from counting as panic clicks
                          child: Container(
                            width: 600,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.95),
                              border: Border.all(color: AppTheme.neonCyan, width: 2),
                              boxShadow: [
                                BoxShadow(color: AppTheme.neonCyan.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                              ]
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 60),
                                const SizedBox(height: 20),
                                Text("SİSTEM İZOLASYON PROTOKOLÜ", 
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text("Aşırı duyusal yükleme saptandı. Tüm sensör telemetrilerini ve alarmları kapatarak sükuneti sağlayabilirsiniz. Ancak bu işlem, dışarıda gerçekleşen olaylara karşı istasyonu KÖR kılacaktır.", 
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 40),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _makeDecision('isolate'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent),
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.volume_off, size: 30),
                                            const SizedBox(height: 10),
                                            Text("SENSÖRLERİ KAPAT", style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold)),
                                            Text("Sükuneti Sağla (Riskli)", style: GoogleFonts.sourceCodePro(fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _makeDecision('vigilance'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.neonCyan.withOpacity(0.2),
                                          foregroundColor: AppTheme.neonCyan,
                                          side: const BorderSide(color: AppTheme.neonCyan),
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.visibility, size: 30),
                                            const SizedBox(height: 10),
                                            Text("CANLI TUT", style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold)),
                                            Text("Gerçekliği Gözlemle", style: GoogleFonts.sourceCodePro(fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                    // Bitiş Ekranı
                    if (_isFinished)
                      Center(
                        child: Text("SİNYAL STABİLİZE EDİLİYOR...", 
                          style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 24, letterSpacing: 5)),
                      ),
                    const DevNav(),
                  ],
                ),
              );
            }
          ),
        ),
      );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool raisedRepaint(covariant CustomPainter oldDelegate) => false;
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
