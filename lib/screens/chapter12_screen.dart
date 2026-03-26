import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'chapter13_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';

class Chapter12Screen extends StatefulWidget {
  const Chapter12Screen({super.key});

  @override
  State<Chapter12Screen> createState() => _Chapter12ScreenState();
}

class _Chapter12ScreenState extends State<Chapter12Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  String? _partnerName;
  String? _partnerImagePath;
  
  late String _dialogue;
  String _displayedDialogue = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;
  Timer? _pulseTimer;
  
  late AnimationController _fireController;
  bool _showChoices = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    PersonaMR().startChapterTimer("Bölüm 12: Partnerin Hatası");
    _partnerName = PersonaMR().getPartner() ?? "ELARA";
    
    // Partner mapping
    if (_partnerName == "KAEL") {
      _partnerImagePath = "assets/images/char_kael.png";
    } else if (_partnerName == "ELARA") {
      _partnerImagePath = "assets/images/char_elara.png";
    } else {
      _partnerImagePath = "assets/images/char_elara.png";
    }
    
    _dialogue = "Özür dilerim, Operatör... Sadece yardım etmek istemiştim. Yanlış kabloyu kestim, her yer alev alıyor. Benim suçum, tamamen benim hatam...";
    
    _fireController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    
    _startTypewriter();
    _startTensePulse();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
      AudioService().playFireCrackle();
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
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

  @override
  void dispose() {
    _stopwatch.stop();
    _typewriterTimer?.cancel();
    _pulseTimer?.cancel();
    _fireController.dispose();
    super.dispose();
  }

  void _makeChoice(String style) {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    
    PersonaMR().recordInteraction("Bölüm 12: Partnerin Hatası", "MISTAKE_RESPONSE", metadata: {"style": style});
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_3",
      chapterId: "Bölüm 12: Partnerin Hatası",
      choiceId: style,
      durationMs: totalTime,
      triggers: [style.toLowerCase(), "performance_review"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 12: Partnerin Hatası",
      totalTimeMs: totalTime,
      additionalData: {
        'choiceId': style,
        'forgiveDelay': totalTime,
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
            completedChapterTitle: "BÖLÜM 12: PARTNERİN HATASI",
            nextChapterHint: "Hata toleransın ve adalet anlayışın kaydedildi. İstasyon tahliye protokolü başlıyor.",
            nextScreen: const Chapter13Screen(),
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
              _partnerName == "KAEL" ? "assets/images/chapter12_kael.png" : "assets/images/chapter12_elara.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.95),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          // Fire Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fireController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withOpacity(0.15 * _fireController.value),
                        Colors.transparent,
                      ],
                      center: Alignment.bottomCenter,
                      radius: 1.5,
                    ),
                  ),
                );
              },
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
                  _buildPartnerGuiltCard(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("BÖLÜM 12: PARTNERİN HATASI", style: GoogleFonts.rajdhani(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        const SizedBox(height: 4),
        Text("BAKIM ÜNİTESİ - KRİTİK YANGIN", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 11)),
      ],
    );
  }

  Widget _buildPartnerGuiltCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(_partnerImagePath!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.orangeAccent.withAlpha(50), BlendMode.screen),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${_partnerName == "KAEL" ? "DR. KAEL" : "ELARA"} KONUŞUYOR:", 
                  style: GoogleFonts.rajdhani(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
          text: "\"HATA İNSANA MAHSUSTUR, GEL BERABER DÜZELTELİM.\"",
          onTap: () => _makeChoice("CONSTRUCTIVE"),
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 12),
        _buildSimplifiedChoice(
          text: "\"HATA PROTOKOL İHLALİDİR. YANGINI SÖNDÜR VE RAPORUNA İŞLE.\"",
          onTap: () => _makeChoice("PROCEDURAL"),
          color: Colors.yellowAccent,
        ),
        const SizedBox(height: 12),
        _buildSimplifiedChoice(
          text: "\"BU HATANIN BEDELİ OLACAK. AKŞAMKİ KUMANYANA EL KOYUYORUM.\"",
          onTap: () => _makeChoice("PUNITIVE"),
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
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
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
          const CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2),
          const SizedBox(height: 20),
          Text("ADALET FİLTRESİ ÇIKTILANIYOR...", 
            style: GoogleFonts.sourceCodePro(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
