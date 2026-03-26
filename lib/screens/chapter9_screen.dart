import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/module_transition_screen.dart';
import 'package:horizon_protocol/screens/chapter10_screen.dart';

class Chapter9Screen extends StatefulWidget {
  const Chapter9Screen({super.key});

  @override
  State<Chapter9Screen> createState() => _Chapter9ScreenState();
}

class _Chapter9ScreenState extends State<Chapter9Screen> with TickerProviderStateMixin {
  final Stopwatch _reflectionStopwatch = Stopwatch();
  bool _isFinished = false;
  String? _selectedText;
  
  late AnimationController _floatController;
  
  final Map<String, String> _choices = {
    "INTERNAL_SYSTEMIC": "Stratejiyi yanlış kurguladım",
    "INTERNAL_ADAPTIVE": "Daha hızlı adapte olmalıydım",
    "INTERNAL_RUMINATIVE": "Benim yüzümden",
    "INTERNAL_TACTICAL": "Acele etmemeliydim",
    "EXTERNAL_RATIONAL": "Zaman çok kısaydı",
    "EXTERNAL_FATALISTIC": "Zaten kurtulamazdık",
    "EXTERNAL_AGGRESSIVE": "Sistem hatalıydı",
    "EXTERNAL_DENIAL": "Elimden geleni yaptım",
  };

  @override
  void initState() {
    super.initState();
    _reflectionStopwatch.start();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    AudioService().playMelancholicAmbient();
    PersonaMR().recordInteraction("Bölüm 9: Enkazın Ardından", "THE_VOID_STARTED");
  }

  void _handleChoice(String categoryId, String text) {
    if (_isFinished) return;
    setState(() {
      _isFinished = true;
      _selectedText = text;
    });

    _reflectionStopwatch.stop();
    AudioService().playTypingBeep();

    final int reflectionTime = _reflectionStopwatch.elapsedMilliseconds;
    
    PersonaMR().recordInteraction(
      "Bölüm 9: Enkazın Ardından", 
      "REFLECTION_MADE", 
      metadata: {
        "text": text,
        "categoryId": categoryId,
        "reflectionTimeMs": reflectionTime
      }
    );

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 9: Enkazın Ardından",
      choiceId: categoryId,
      durationMs: reflectionTime,
      triggers: ["the_void", "reflection"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 9: Enkazın Ardından",
      totalTimeMs: reflectionTime,
      additionalData: {
        "responseDelay": reflectionTime,
        "finalResult": categoryId,
        "selectedText": text,
      },
    );

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ModuleTransitionScreen(
          moduleTitle: "MODÜL 3",
          moduleSubtitle: "HESAPLAŞMA",
          objective: "Kritik Analiz Bekleniyor...",
          icon: Icons.auto_graph,
          nextScreen: Chapter10Screen(),
        )));
      }
    });
  }

  @override
  void dispose() {
    _reflectionStopwatch.stop();
    _floatController.dispose();
    AudioService().stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fixed Background Image - Darkened further as per request
          Positioned.fill(
            child: Image.asset(
              "assets/images/chapter9_background.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.95), // 15% darker than 0.85 is roughly 0.95-1.0
              colorBlendMode: BlendMode.darken,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFF030305)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 30),
                Expanded(
                  child: _isFinished ? _buildFinalSelectionView() : _buildChoiceView(),
                ),
              ],
            ),
          ),
          
          const DevNav(),
        ],
      ),
    );
  }

  Widget _buildChoiceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
      child: Column(
        children: [
          _buildAIDAMessage(),
          const SizedBox(height: 40),
          _buildChoiceList(),
          const SizedBox(height: 60), // Extra space at bottom for scrollability
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "MODÜL 2: SESSİZ ÇIĞLIK", 
          style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3.0)
        ),
        const SizedBox(height: 4),
        Text(
          "BÖLÜM 9: ENKAZIN ARDINDAN", 
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)
        ),
      ],
    );
  }

  Widget _buildAIDAMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smart_toy_outlined, color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              Text(
                "A.I.D.A SİSTEM MESAJI", 
                style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "\"Laboratuvar modülü artık yok. Emeklerinin yarısı uzay boşluğuna gitti. Neden başaramadık? Vereceğin cevaplar hata analizimiz için kritik.\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.spectral(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceList() {
    final entries = _choices.entries.toList();
    return Column(
      children: List.generate(entries.length, (index) {
        final e = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final offset = math.sin((_floatController.value * 2 * math.pi) + (index * 0.5)) * 4.0;
              return Transform.translate(
                offset: Offset(0, offset),
                child: _buildPillButton(e.key, e.value),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildPillButton(String categoryId, String text) {
    return GestureDetector(
      onTap: () => _handleChoice(categoryId, text),
      child: Container(
        width: 300, // Fixed width for consistent pill shape
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.35), width: 1.2),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(color: AppTheme.neonCyan.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            color: Colors.white.withOpacity(0.9),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFinalSelectionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Push up slightly from bottom
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Seçilen Özeleştiri:",
              style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            Text(
              "\"$_selectedText\"",
              textAlign: TextAlign.center,
              style: GoogleFonts.spectral(
                color: Colors.white,
                fontSize: 28,
                fontStyle: FontStyle.italic,
                shadows: [Shadow(color: AppTheme.neonCyan.withOpacity(0.5), blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: AppTheme.neonCyan, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
