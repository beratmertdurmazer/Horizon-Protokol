import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/module_completion_screen.dart';

class Chapter13Screen extends StatefulWidget {
  const Chapter13Screen({super.key});

  @override
  State<Chapter13Screen> createState() => _Chapter13ScreenState();
}

class _Chapter13ScreenState extends State<Chapter13Screen> {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  String? _partnerName;
  String? _partnerImagePath;
  
  late String _dialogue;
  String _displayedDialogue = "";
  int _charIndex = 0;
  int? _dialogueFinishTime;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    PersonaMR().startChapterTimer("Bölüm 13: Güven Testi");
    _partnerName = PersonaMR().getPartner() ?? "ELARA";
    _partnerImagePath = _partnerName == "KAEL" ? "assets/images/char_kael.png" : "assets/images/char_elara.png";
    
    _dialogue = "Ana bilgisayarı düzeltmek için havalandırma tünellerine girmeliyim, ama sen beni yukarıdan yönlendirmelisin. Hayatım senin ellerinde...";
    
    _startTypewriter();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
      AudioService().playVentEcho();
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
        _dialogueFinishTime = _stopwatch.elapsedMilliseconds;
      }
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  void _makeFinalChoice(String style) {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);
    PersonaMR().recordInteraction("Bölüm 13: Güven Testi", "FINAL_DECISION", metadata: {"choiceId": style});
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;
    
    // Async logging and finalization
    () async {
      await PersonaMR().logDecision(
        moduleId: "MOD_3",
        chapterId: "Bölüm 13: Güven Testi",
        choiceId: style,
        durationMs: totalTime,
        triggers: [style.toLowerCase(), "module_3_final"],
      );

      await PersonaMR().logChapterMetrics(
        chapterId: "Bölüm 13: Güven Testi",
        totalTimeMs: totalTime,
        additionalData: {
          "delegationRatio": style == "DELEGATE" ? 1.0 : 0.0,
          "finalDecision": style.toLowerCase(),
          "readDuration": (totalTime - (_dialogueFinishTime ?? totalTime)).clamp(0, totalTime),
        },
      );

      await PersonaMR().finalizeCandidateSession();
    }();

    // Final Transition
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ModuleCompletionScreen(moduleTitle: "Modül 3: Yalnız Yıldızlar")),
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
          // Background - Dark Tunnel (0.95 dark as requested)
          Positioned.fill(
            child: Image.asset(
              _partnerName == "KAEL" ? "assets/images/chapter13_kael.png" : "assets/images/chapter11_elara.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.95),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildDialogueBox(),
                  const SizedBox(height: 30),
                  if (!_isTransitioning) _buildChoices(),
                  if (_isTransitioning) _buildModuleEndState(),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("BÖLÜM 13: GÜVEN TESTİ [FİNAL]", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        Text("SERVER ANALİZ / SEKTÖR C", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildDialogueBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: AppTheme.neonCyan),
              const SizedBox(width: 10),
              Text("${_partnerName} BEKLEMEDE", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _displayedDialogue,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildChoices() {
    return Column(
      children: [
        _buildDecisionTile(
          "\"SANA GÜVENİYORUM. TÜNELE GİR, BEN SENİ YÖNLENDİRECEĞİM.\"",
          () => _makeFinalChoice("DELEGATE"),
          AppTheme.neonCyan, // UI: Blue
        ),
        const SizedBox(height: 16),
        _buildDecisionTile(
          "\"SEN BURADA DUR. TÜNELİ BEN DAHA İYİ BİLİYORUM, BEN GİDERİM.\"",
          () => _makeFinalChoice("SELF"),
          Colors.orangeAccent, // UI: Orange
        ),
        const SizedBox(height: 16),
        _buildDecisionTile(
          "\"DEMİN NE YAPTIĞINI GÖRDÜK. BU RİSKİ ALAMAM, TÜNELE BEN GİRECEĞİM.\"",
          () => _makeFinalChoice("DISTRUST"),
          Colors.redAccent, // UI: Red
        ),
      ],
    );
  }

  Widget _buildDecisionTile(String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.rajdhani(color: color, fontSize: 15, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  Widget _buildModuleEndState() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.neonCyan),
          const SizedBox(height: 30),
          Text(
            "MODÜL 3 ANALİZİ TAMAMLANDI",
            style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "PERSONAMR VERİLERİ BULUTA AKTARILIYOR...",
            style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
