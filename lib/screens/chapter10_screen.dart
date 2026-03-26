import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'chapter11_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';

class Chapter10Screen extends StatefulWidget {
  const Chapter10Screen({super.key});

  @override
  State<Chapter10Screen> createState() => _Chapter10ScreenState();
}

class _Chapter10ScreenState extends State<Chapter10Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  String? _selectedCharacter;
  
  int _charIndex = 0;
  Timer? _typewriterTimer;
  bool _showBiasHint = false;
  Timer? _hintTimer;
  
  final String _narrative = "Reaktörü tamamen onarmak için fiziksel bir yardımcıya ihtiyacın var. İki cryo-tüpün önündesin. Bir karar vermelisin: Teknik mükemmeliyet mi, sosyal uyum mu?";
  String _displayedNarrative = "";

  late AnimationController _frostController;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _frostController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    PersonaMR().startChapterTimer("Bölüm 10: Buzdan Çıkan Yüz");
    _startTypewriter();

    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isTransitioning) {
        setState(() => _showBiasHint = true);
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_charIndex < _narrative.length) {
        if (mounted) {
          setState(() {
            _displayedNarrative += _narrative[_charIndex];
            _charIndex++;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _typewriterTimer?.cancel();
    _hintTimer?.cancel();
    _frostController.dispose();
    super.dispose();
  }

  void _selectCharacter(String name) {
    if (_isTransitioning) return;

    setState(() {
      _selectedCharacter = name;
      _isTransitioning = true;
    });
    PersonaMR().recordInteraction("Bölüm 10: Buzdan Çıkan Yüz", "CHARACTER_SELECTED", metadata: {"name": name});

    PersonaMR().setPartner(name); // Store for Chapter 11
    AudioService().playFrostCrack();
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;
    final partnerName = name == "KAEL" ? "KAEL" : "ELARA";

    PersonaMR().logDecision(
      moduleId: "MOD_3",
      chapterId: "Bölüm 10: Buzdan Çıkan Yüz",
      choiceId: partnerName,
      durationMs: totalTime,
      triggers: [partnerName.toLowerCase(), "personality_match"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 10: Buzdan Çıkan Yüz",
      totalTimeMs: totalTime,
      additionalData: {
        'choiceId': partnerName,
        'totalTimeMs': totalTime,
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
            completedChapterTitle: "Bölüm 10: Buzdan Çıkan Yüz",
            nextChapterHint: "Partner uyandırıldı. İlk test: çatışma yönetimi.",
            nextScreen: Chapter11Screen(),
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
          // Background - Frozen Lab
          Positioned.fill(
            child: Image.asset(
              "assets/images/chapter10_background.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.95),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          // Frost Mist Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _frostController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.1 + (_frostController.value * 0.1),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                        center: Alignment.center,
                        radius: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  if (!_isTransitioning) _buildNarrativeWindow(),
                  const Spacer(),
                  if (!_isTransitioning) _buildCharacterSelection(),
                  if (_isTransitioning) _buildTransitionState(),
                  const Spacer(),
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
        Text("BÖLÜM 10: BUZDAN ÇIKAN YÜZ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        Text("CRYO-LAB / SEKTÖR 7", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildNarrativeWindow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_displayedNarrative, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.6)),
    );
  }

  Widget _buildCharacterSelection() {
    return Column(
      children: [
        if (_showBiasHint)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: 1.0,
              child: Text(
                "Hımm, cinsiyet veya isim odaklı düşünmemeliyim. Sektör verileri ve dosyalar daha kritik...",
                textAlign: TextAlign.center,
                style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildPodCard(
                "DR. KAEL", 
                "TEKNİK DAHİ", 
                "Teknik Rapor: %99 Başarı.\nEkip Raporu: Geçimsiz, yüksek ego.", 
                "assets/images/char_kael.png", 
                Colors.blueAccent,
                "Seviye S+ Operatör"
              )
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildPodCard(
                "ELARA", 
                "SOSYAL LİDER", 
                "Teknik Rapor: %75 Başarı.\nEkip Raporu: Kusursuz uyum ve motivasyon.", 
                "assets/images/char_elara.png", 
                Colors.cyanAccent,
                "Seviye A+ Koordinatör"
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPodCard(String name, String trait, String desc, String imagePath, Color color, String subtag) {
    return GestureDetector(
      onTap: () => _selectCharacter(name == "DR. KAEL" ? "KAEL" : "ELARA"),
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Column(
          children: [
            const SizedBox(height: 25),
            // Avatar Placeholder / Frame
            Container(
              height: 160,
              width: 130,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: color.withOpacity(0.6), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                   Positioned.fill(
                    child: Opacity(
                      opacity: 0.7,
                      child: Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Icon(Icons.person, color: color, size: 50))),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 30,
                      color: color.withOpacity(0.2),
                      child: Center(child: Text(subtag, style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 8))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(name, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            Text(trait, style: GoogleFonts.sourceCodePro(color: color, fontSize: 10, letterSpacing: 2)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                desc, 
                textAlign: TextAlign.center, 
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, height: 1.4)
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
              ),
              child: Center(
                child: Text(
                  "UYANDIRMAYI ONAYLA", 
                  style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionState() {
    return Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.neonCyan),
        const SizedBox(height: 30),
        Text(
          "${_selectedCharacter == "KAEL" ? "DR. KAEL" : "ELARA"} UYANDIRILIYOR...",
          style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "CRYO-SIVI TAHLİYE EDİLİYOR. BUZ ÇÖZÜLÜYOR.",
          style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10),
        ),
      ],
    );
  }
}
