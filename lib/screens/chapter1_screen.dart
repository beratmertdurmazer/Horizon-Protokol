import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/screens/chapter2_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';
import 'package:horizon_protocol/screens/module_transition_screen.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';

class Chapter1Screen extends StatefulWidget {
  const Chapter1Screen({super.key});

  @override
  State<Chapter1Screen> createState() => _Chapter1ScreenState();
}

class _Chapter1ScreenState extends State<Chapter1Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  final List<String> _alphabet = [
    "A", "B", "C", "Ç", "D", "E", "F", "G", "Ğ", "H", "I", "İ", "J", "K", "L", 
    "M", "N", "O", "Ö", "P", "R", "S", "Ş", "T", "U", "Ü", "V", "Y", "Z"
  ];

  late List<String> _sequence;
  late String _correctAnswer;
  late List<String> _options;
  int _errorCount = 0;
  int? _timeToFirstClick;
  bool _isCompleted = false;

  final String _fullNarrative = "\"Göz kapakların yapışmış. Sinirsel sinapslarını yeniden hizalaman gerekiyor. Aşağıdaki alfanümerik dizinin son halkasını bul. Hata payı yoktur.\"";
  String _displayedText = "";
  bool _isTypingNarrative = true;

  Timer? _uiUpdateTimer;
  Timer? _heartbeatTimer;
  Timer? _typewriterTimer;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glitchController;
  late AnimationController _stressController;
  bool _isGlitching = false;

  String _statusText = "SİSTEM BAŞLATILIYOR...";

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch(); // Don't start yet, starts after narrative
    _generateBalancedOptions();
    
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _glitchController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _stressController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..repeat(reverse: true);

    _startNarrativeTyping();
  }

  void _generateBalancedOptions() {
    _options = ["D98", "D100", "F100", "F86", "B86", "B44", "E44", "E110", "G110", "G50", "H50", "H98"];
    _options.shuffle();
    _correctAnswer = "D98";
    _sequence = ["Y5", "B8", "G14", "P26", "L50"];
  }

  void _startNarrativeTyping() {
    int charIndex = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (charIndex < _fullNarrative.length) {
        setState(() { _displayedText += _fullNarrative[charIndex]; charIndex++; });
        if (charIndex % 3 == 0) AudioService().playTypingBeep();
      } else {
        timer.cancel();
        setState(() { _isTypingNarrative = false; _statusText = "SİSTEM HAZIR. DEŞİFRE İÇİN BEKLENİYOR."; });
        PersonaMR().startChapterTimer("Bölüm 1: Soğuk Uyanış");
        _stopwatch.start();
        _startHeartbeat();
        _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (t) => setState(() {}));
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    double seconds = _stopwatch.elapsedMilliseconds / 1000;
    int bpm = (60 + (seconds * 3.5) + (_errorCount * 25)).clamp(60, 210).toInt();
    _stressController.duration = Duration(milliseconds: (30000 / bpm).toInt());
    if (!_stressController.isAnimating) _stressController.repeat(reverse: true);
    int ms = (60000 / bpm).toInt();
    _heartbeatTimer = Timer(Duration(milliseconds: ms), () {
      if (!_isCompleted && !_isTypingNarrative) { AudioService().playHeartbeat(); _startHeartbeat(); }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel(); _heartbeatTimer?.cancel(); _typewriterTimer?.cancel();
    _pulseController.dispose(); _glitchController.dispose(); _stressController.dispose();
    super.dispose();
  }

  void _triggerGlitch() {
    AudioService().playGlitchSound();
    setState(() { _isGlitching = true; _errorCount++; });
    _glitchController.forward(from: 0).then((_) => setState(() => _isGlitching = false));
  }

  void _onOptionTap(String value) {
    if (_isCompleted || _isTypingNarrative) return;
    _timeToFirstClick ??= _stopwatch.elapsedMilliseconds;
    if (value == _correctAnswer) {
      PersonaMR().recordInteraction("Bölüm 1: Soğuk Uyanış", "CORRECT_ANSWER", metadata: {"input": value, "trials": _errorCount + 1});
      AudioService().playTypingBeep();
      setState(() { _isCompleted = true; _statusText = "SİNAPTİK BAĞLANTI KURULDU."; _stopwatch.stop(); _completeChapter(); });
    } else {
      PersonaMR().recordInteraction("Bölüm 1: Soğuk Uyanış", "WRONG_ANSWER", metadata: {"input": value});
      _triggerGlitch();
      setState(() => _statusText = "HATA: HATALI BİLEŞEN ALGILANDI!");
    }
  }

  void _completeChapter() {
    final decisionTime = _stopwatch.elapsedMilliseconds;
    
    PersonaMR().logDecision(
      moduleId: "MOD_1",
      chapterId: "Bölüm 1: Soğuk Uyanış",
      choiceId: "TRANS_MENSA_12_BALANCED",
      durationMs: decisionTime,
      triggers: ["errors_$_errorCount"]
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 1: Soğuk Uyanış",
      totalTimeMs: decisionTime,
      additionalData: {
        "timeToFirstClick": _timeToFirstClick ?? decisionTime,
        "errorCount": _errorCount,
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
        completedChapterTitle: "Bölüm 1: Soğuk Uyanış",
        nextChapterHint: "Sinapslar hizalandı. Sıradaki test: kaynak yönetimi.",
        nextScreen: Chapter2Screen(),
      )));
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_stopwatch.elapsedMilliseconds / 30000).clamp(0, 1);
    Color dynamicColor = Color.lerp(AppTheme.neonCyan, Colors.red, progress)!;
    double xShift = _isGlitching ? (math.Random().nextDouble() * 30 - 15) : 0;
    double yShift = _isGlitching ? (math.Random().nextDouble() * 30 - 15) : 0;
    double stressPulse = (_stopwatch.isRunning && (progress > 0.4 || _errorCount > 0)) ? _stressController.value : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/concept_cyber_noir_cold_awakening_128391231231_1774315250438.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.88),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          SizedBox.expand(
            child: Transform.translate(
              offset: Offset(xShift, yShift),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      dynamicColor.withOpacity(_pulseAnimation.value + (stressPulse * 0.25)),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(dynamicColor),
                          const SizedBox(height: 10),
                          _buildNarrativeWindow(dynamicColor),
                          const SizedBox(height: 25),
                          if (!_isTypingNarrative) ...[
                            _buildAlphanumericSequence(dynamicColor),
                            const SizedBox(height: 20),
                            _buildOptionsGrid(dynamicColor),
                          ],
                          _buildFooterStatus(dynamicColor, stressPulse),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          DevNav(),
          if (_stopwatch.isRunning && (progress > 0.6 || _errorCount > 1))
            IgnorePointer(child: Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Colors.red.withOpacity(0.25 + (stressPulse * 0.35))], stops: const [0.4, 1.0])))),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("BÖLÜM 1: SOĞUK UYANIŞ", style: GoogleFonts.rajdhani(color: color, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
          Text("ULTIMATE DECIPHER | MENSA_V8", style: GoogleFonts.sourceCodePro(color: color.withOpacity(0.6), fontSize: 9)),
        ]),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(4)), child: Text(_stopwatch.isRunning ? "${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s" : "PENDING", style: GoogleFonts.sourceCodePro(color: color, fontSize: 22, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildNarrativeWindow(Color color) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), border: Border.all(color: color.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)), child: Text(_displayedText, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.5)));
  }

  Widget _buildAlphanumericSequence(Color color) {
    return Center(child: Column(children: [
      Text("MENSA ANALİZİ: DİZİNİ TAMAMLA", style: GoogleFonts.rajdhani(color: color.withOpacity(0.7), fontSize: 12, letterSpacing: 3.0)),
      const SizedBox(height: 12),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [..._sequence.map((s) => _buildDataPacket(s, color)).toList(), _buildDataPacket("??", color, isTarget: true)])),
    ]));
  }

  Widget _buildDataPacket(String label, Color color, {bool isTarget = false}) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isTarget ? color.withOpacity(0.15) : Colors.black.withOpacity(0.6), border: Border.all(color: isTarget ? color : color.withOpacity(0.3), width: isTarget ? 2 : 1), borderRadius: BorderRadius.circular(4)), child: Text(label, style: GoogleFonts.sourceCodePro(color: isTarget ? color : Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)));
  }

  Widget _buildOptionsGrid(Color color) {
    return GridView.builder(
      itemCount: 12,
      shrinkWrap: true, // ADDED SHRINKWRAP
      physics: const NeverScrollableScrollPhysics(), // ADDED PHYSICS
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.3),
      itemBuilder: (context, index) {
        String opt = _options[index];
        return InkWell(onTap: () => _onOptionTap(opt), child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border.all(color: color.withOpacity(0.4)), borderRadius: BorderRadius.circular(4)), child: Text(opt, style: GoogleFonts.sourceCodePro(color: color, fontSize: 20, fontWeight: FontWeight.bold))));
      },
    );
  }

  Widget _buildFooterStatus(Color color, double pulse) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
      Icon(_isTypingNarrative ? Icons.keyboard : Icons.biotech, size: 18, color: color.withOpacity(0.6 + (pulse * 0.4))),
      const SizedBox(width: 10),
      Expanded(child: Text(_statusText, style: GoogleFonts.sourceCodePro(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
    ]));
  }
}
