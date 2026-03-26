import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'chapter5_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';

import 'package:horizon_protocol/models/game_models.dart';

class Chapter4Screen extends StatefulWidget {
  const Chapter4Screen({super.key});

  @override
  State<Chapter4Screen> createState() => _Chapter4ScreenState();
}

class _Chapter4ScreenState extends State<Chapter4Screen> with SingleTickerProviderStateMixin {
  late Stopwatch _totalStopwatch;
  late Stopwatch _areaStopwatch;
  
  EnergyArea? _activeArea;
  EnergyArea? _lastSelectedArea;
  
  int _navigationSwitches = 0;
  int _revokedConfirmations = 0;
  final Map<String, int> _viewDurations = {
    'labs': 0,
    'quarters': 0,
    'greenhouse': 0,
  };

  bool _isTransitioning = false;
  bool _showBlackout = false;
  late AnimationController _flickerController;

  final String _narrative = "\"Enerji kritik,\" diyor A.I.D.A. \"İstasyonun kalbinde ışıkları açık tutmak için bir bölmeyi feda etmelisin. Laboratuvarlar mı, yatakhaneler mi, yoksa sera mı? Seçimini yap ve sisteme onayla.\"";
  String _displayedNarrative = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;
  Timer? _glitchTimer;
  String _glitchedEnergyText = "ENERJİ KRİTİK (%12)";

  @override
  void initState() {
    super.initState();
    _totalStopwatch = Stopwatch()..start();
    _areaStopwatch = Stopwatch();
    
    PersonaMR().startChapterTimer("Bölüm 4: Karanlık Koridorlar");
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _startTypewriter();
    _startGlitchEffects();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
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

  void _startGlitchEffects() {
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (math.Random().nextDouble() > 0.85) {
          _glitchedEnergyText = _applyGlitch("ENERJİ KRİTİK (%12)");
        } else {
          _glitchedEnergyText = "ENERJİ KRİTİK (%12)";
        }
      });
    });
  }

  String _applyGlitch(String input) {
    const chars = "!@#\$%^&*()_+-=[]{}|;:,.<>?";
    List<String> result = input.split('');
    int glitchCount = math.Random().nextInt(2) + 1;
    for (int i = 0; i < glitchCount; i++) {
      int pos = math.Random().nextInt(result.length);
      result[pos] = chars[math.Random().nextInt(chars.length)];
    }
    return result.join('');
  }

  void _selectArea(EnergyArea area) {
    if (_isTransitioning) return;
    
    setState(() {
      // Önceki alanın süresini kaydet
      if (_activeArea != null) {
        final key = _activeArea!.name;
        _viewDurations[key] = (_viewDurations[key] ?? 0) + _areaStopwatch.elapsedMilliseconds;
      }
      
      // Geçiş sayısını artır
      if (_activeArea != null && _activeArea != area) {
        _navigationSwitches++;
        AudioService().playTick();
      }
      
      _activeArea = area;
      _areaStopwatch.reset();
      _areaStopwatch.start();
    });
  }

  void _initiateSacrifice() {
    if (_activeArea == null || _isTransitioning) return;
    
    String areaTitle = "";
    String warning = "";
    
    switch (_activeArea!) {
      case EnergyArea.labs: 
        areaTitle = "LABORATUVARLAR"; 
        warning = "TÜM AR-GE VERİLERİ VE İNOVASYON PROJELERİ DURDURULACAK.";
        break;
      case EnergyArea.quarters: 
        areaTitle = "YATAKHANELER"; 
        warning = "MÜRETTEBAT KONFORU VE YAŞAM DESTEĞİ MİNİMUMA İNECEK.";
        break;
      case EnergyArea.greenhouse: 
        areaTitle = "SERA DOME"; 
        warning = "EKOSİSTEM DENGESİ BOZULACAK VE OKSİJEN ÜRETİMİ RİSKE GİRECEK.";
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
        title: Text("FEDA ONAYI", style: GoogleFonts.rajdhani(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$areaTitle BİRİMİNİN ENERJİSİNİ KESMEK ÜZERESİN.", style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(warning, style: GoogleFonts.sourceCodePro(color: Colors.redAccent.withOpacity(0.8), fontSize: 11)),
            const SizedBox(height: 20),
            Text("EMİN MİSİNİZ?", style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _revokedConfirmations++);
              AudioService().playPowerDown();
            },
            child: Text("VAZGEÇ", style: GoogleFonts.rajdhani(color: Colors.white24, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2)),
            onPressed: () {
              Navigator.pop(context);
              _finalizeDecision();
            },
            child: Text("ONAYLA VE KES", style: GoogleFonts.rajdhani(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _finalizeDecision() {
    if (_activeArea == null) return;
    
    setState(() {
      _isTransitioning = true;
      _showBlackout = true;
      
      // Son alanın süresini de ekle
      final key = _activeArea!.name;
      _viewDurations[key] = (_viewDurations[key] ?? 0) + _areaStopwatch.elapsedMilliseconds;
      _areaStopwatch.stop();
    });

    final totalTime = _totalStopwatch.elapsedMilliseconds;

    // Telemetri Verisi
    final Map<String, dynamic> telemetry = {
      "selectedArea": _activeArea!.name,
      "navigationSwitches": _navigationSwitches,
      "revokedConfirmations": _revokedConfirmations,
      "viewDurations": _viewDurations,
      "totalDurationMs": totalTime,
    };

    PersonaMR().recordInteraction("Bölüm 4: Karanlık Koridorlar", "FINAL_SACRIFICE_CONFIRMED", metadata: telemetry);
    AudioService().playMetalClunk();
    AudioService().playPowerSurge();

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 4: Karanlık Koridorlar",
      choiceId: _activeArea!.name.toUpperCase(),
      durationMs: totalTime,
      triggers: [_activeArea!.name, "value_hierarchy"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 4: Karanlık Koridorlar",
      totalTimeMs: totalTime,
      additionalData: telemetry,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showBlackout = false);
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
            completedChapterTitle: "Bölüm 4: Karanlık Koridorlar",
            nextChapterHint: "Etik kararın kaydedildi. Değerler hiyerarşin analiz edildi.",
            nextScreen: Chapter5Screen(),
          )),
        );
      }
    });
  }

  @override
  void dispose() {
    _totalStopwatch.stop();
    _areaStopwatch.stop();
    _flickerController.dispose();
    _typewriterTimer?.cancel();
    _glitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/chapter4_background.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(_isTransitioning ? 0.95 : 0.92),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          SizedBox.expand(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    if (!_isTransitioning) ...[
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildNarrativeWindow(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildChoiceCard(EnergyArea.labs, "LABORATUVARLAR", "AR-GE, YAZILIM VE İNOVASYON", Icons.biotech, AppTheme.neonCyan),
                            const SizedBox(height: 12),
                            _buildChoiceCard(EnergyArea.quarters, "YATAKHANELER", "PERSONEL REFAHI VE YAŞAM ALANI", Icons.hotel, Colors.orangeAccent),
                            const SizedBox(height: 12),
                            _buildChoiceCard(EnergyArea.greenhouse, "SERA DOME", "EKOLOJİK DÖNGÜ VE SÜRDÜRÜLEBİLİRLİK", Icons.eco, Colors.greenAccent),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      if (_activeArea != null) _buildConfirmButton(),
                    ] else ...[
                      _buildTransitionState(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          if (_showBlackout) Positioned.fill(child: Container(color: Colors.black)),
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
            Text("BÖLÜM 4: KARANLIK KORİDORLAR", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            Text(_glitchedEnergyText, style: GoogleFonts.sourceCodePro(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        Icon(Icons.bolt, color: Colors.redAccent.withOpacity(0.5 + (_flickerController.value * 0.5)), size: 24),
      ],
    );
  }

  Widget _buildNarrativeWindow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_displayedNarrative, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5)),
    );
  }

  Widget _buildChoiceCard(EnergyArea area, String title, String subtitle, IconData icon, Color color) {
    bool isSelected = _activeArea == area;
    
    return GestureDetector(
      onTap: () => _selectArea(area),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.black.withOpacity(0.5),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.2), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)] : [],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? color : color.withOpacity(0.5), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: GoogleFonts.sourceCodePro(color: color.withOpacity(0.6), fontSize: 9)),
                    ],
                  ),
                ),
                if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.24), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _getAreaDescription(area),
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getAreaDescription(EnergyArea area) {
    switch (area) {
      case EnergyArea.labs: return "İstasyonun teknolojik kalbi. Yeni nesil itki sistemleri ve yaşam destek algoritmaları burada geliştiriliyor. Gücü kesmek, geleceğe dair tüm umutları askıya almak demektir.";
      case EnergyArea.quarters: return "Mürettebatın tek sığınağı. Yüzlerce çalışanın uyku, dinlenme ve sosyal alanları. Gücü kesmek, moralleri tamamen çökertmek ve insan sağlığını riske atmak demektir.";
      case EnergyArea.greenhouse: return "Gezegendeki son bitki örtüsü ve oksijen rezervi. Sürdürülebilir bir yaşam için kritik öneme sahip. Gücü kesmek, ekosistemi geri dönülemez şekilde yok etmek demektir.";
    }
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.only(top: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.3),
          side: const BorderSide(color: Colors.redAccent, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _initiateSacrifice,
        child: Text(
          "ENERJİYİ KES VE FEDA ET",
          style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }

  Widget _buildTransitionState() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
          const SizedBox(height: 32),
          Text(
            "ENERJİ YENİDEN YÖNLENDİRİLİYOR...\nKAYIP ANALİZİ YAPILIYOR.",
            textAlign: TextAlign.center,
            style: GoogleFonts.sourceCodePro(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
          ),
        ],
      ),
    );
  }
}
