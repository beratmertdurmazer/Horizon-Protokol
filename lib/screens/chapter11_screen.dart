import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'chapter12_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';

class Chapter11Screen extends StatefulWidget {
  const Chapter11Screen({super.key});

  @override
  State<Chapter11Screen> createState() => _Chapter11ScreenState();
}

class _Chapter11ScreenState extends State<Chapter11Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  String? _partnerName;
  String? _partnerImagePath;
  
  late String _dialogue;
  String _displayedDialogue = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;
  Timer? _pulseTimer;
  
  // Timeout & Counter logic
  Timer? _decisionTimer;
  int _secondsElapsed = 0;
  bool _showChoices = false;
  bool _isTimeout = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    PersonaMR().startChapterTimer("Bölüm 11: İlk Tartışma");
    _partnerName = PersonaMR().getPartner() ?? "ELARA";
    _partnerImagePath = _partnerName == "KAEL" ? "assets/images/char_kael.png" : "assets/images/char_elara.png";
    
    _dialogue = "İtiraz ediyorum, Operatör. Bu yol bizi öldürür, oksijen problemini çözdüğüne emin değilim. Başka bir yöntem izleyebiliriz...";
    
    _startTypewriter();
    _startTensePulse();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_charIndex < _dialogue.length) {
        if (mounted) {
          setState(() {
            _displayedDialogue += _dialogue[_charIndex];
            _charIndex++;
          });
          if (_charIndex % 3 == 0) AudioService().playTypingBeep();
        }
      } else {
        timer.cancel();
        setState(() => _showChoices = true);
        _startDecisionTimer();
      }
    });
  }

  void _startTensePulse() {
    _pulseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isTransitioning || !mounted) {
        timer.cancel();
        return;
      }
      AudioService().playTensePulse();
    });
  }

  void _startDecisionTimer() {
    _decisionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTransitioning || !mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsElapsed++);
      if (_secondsElapsed >= 45) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (_isTransitioning) return;
    setState(() {
      _isTimeout = true;
      _isTransitioning = true;
    });
    _finalizeChoice("TIMEOUT");
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _typewriterTimer?.cancel();
    _pulseTimer?.cancel();
    _decisionTimer?.cancel();
    super.dispose();
  }

  void _makeChoice(String style) {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    _finalizeChoice(style);
  }

  void _finalizeChoice(String style) {
    PersonaMR().recordInteraction("Bölüm 11: İlk Tartışma", "CONFLICT_STYLE_SELECTED", metadata: {"style": style, "delay": _secondsElapsed});
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_3",
      chapterId: "Bölüm 11: İlk Tartışma",
      choiceId: style,
      durationMs: totalTime,
      triggers: [style.toLowerCase(), "conflict_resolution"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 11: İlk Tartışma",
      totalTimeMs: totalTime,
      additionalData: {
        'choiceId': style,
        'decisionDelay': _secondsElapsed * 1000,
        'finalAgreement': (style == "COLLABORATIVE" || style == "RATIONAL") ? true : false,
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
            completedChapterTitle: "BÖLÜM 11: İLK TARTIŞMA",
            nextChapterHint: "Çatışma çözüm tarzın kaydedildi. Sektör girişinde alarm sesleri yükseliyor.",
            nextScreen: const Chapter12Screen(),
          )),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              _partnerName == "KAEL" ? "assets/images/chapter11_kael.png" : "assets/images/chapter11_elara.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.95),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildDialogueBox(),
                  const SizedBox(height: 30),
                  if (_showChoices && !_isTransitioning) _buildChoiceMatrix(),
                  if (_isTransitioning) _buildStatusView(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          const DevNav(),
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
            Text("BÖLÜM 11: İLK TARTIŞMA", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            Text("KRİTİK EŞİK - BAKIM TÜNELİ GİRİŞİ", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
          ],
        ),
        if (_showChoices && !_isTransitioning) _buildTimerBadge(),
      ],
    );
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _secondsElapsed > 35 ? Colors.red.withOpacity(0.2) : Colors.black.withOpacity(0.6),
        border: Border.all(color: _secondsElapsed > 35 ? Colors.redAccent : AppTheme.neonCyan.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "SÜRE: $_secondsElapsed S",
        style: GoogleFonts.sourceCodePro(
          color: _secondsElapsed > 35 ? Colors.redAccent : AppTheme.neonCyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDialogueBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(_partnerImagePath!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${_partnerName == "KAEL" ? "DR. KAEL" : "ELARA"} KONUŞUYOR:", 
                  style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(
                  _displayedDialogue,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceMatrix() {
    return Column(
      children: [
        _buildSimplifiedChoice(
          text: "\"NEDEN BÖYLE DÜŞÜNÜYORSUN? TEKRAR KONTROL EDELİM.\"",
          onTap: () => _makeChoice("COLLABORATIVE"),
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 12),
        _buildSimplifiedChoice(
          text: "\"VERİLERE ODAKLAN. SİMÜLASYON YOLU DOĞRULUYOR.\"",
          onTap: () => _makeChoice("RATIONAL"),
          color: Colors.yellowAccent,
        ),
        const SizedBox(height: 12),
        _buildSimplifiedChoice(
          text: "\"EĞER GİRMEZSEN HEPİMİZ HAVASIZLIKTAN ÖLECEĞİZ. SORUMLUSU SEN OLACAKSIN!\"",
          onTap: () => _makeChoice("MANIPULATIVE"),
          color: Colors.orangeAccent,
        ),
        const SizedBox(height: 12),
        _buildSimplifiedChoice(
          text: "\"OKSİJEN SORUNU YOK. YETKİLİ BENİM, DEDİĞİMİ YAP!\"",
          onTap: () => _makeChoice("AUTHORITY"),
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildSimplifiedChoice({
    required String text,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.neonCyan, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(_isTimeout ? "KARAR FELCİ ANALİZ EDİLİYOR..." : "ÜSLUP KAYDI OLUŞTURULUYOR...", 
            style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
