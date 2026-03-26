import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/chapter4_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';

class Chapter3Screen extends StatefulWidget {
  const Chapter3Screen({super.key});

  @override
  State<Chapter3Screen> createState() => _Chapter3ScreenState();
}

class _Chapter3ScreenState extends State<Chapter3Screen> with TickerProviderStateMixin {
  late List<String> _symbols;
  late List<bool> _isRevealed;
  late List<bool> _isMatched;
  int? _firstSelectedIndex;
  bool _isProcessing = false;
  int _matchesFound = 0;
  
  List<Widget> _popups = [];
  Timer? _popupTimer;
  Timer? _uiTimer;
  late Stopwatch _stopwatch;
  bool _isCompleted = false;
  bool _isTransitioning = false;

  // Telemetry Variables (V3 Assessment)
  int _distractionClicks = 0;
  int _gameClicks = 0;
  final Map<Key, DateTime> _popupSpawnTimes = {};
  int _immediateDismissals = 0;
  int _readingParalysisCount = 0;
  int _spamClicks = 0;
  int _matchErrors = 0;
  int _actualMemoryErrors = 0; // NEW: Memory fail on seen items
  final Set<int> _seenIndices = {}; // NEW: Track exploration
  final List<int> _recoveryTimes = []; // NEW: Recovery agile tracking
  int? _seenIndicesAtMove8; // NEW: Strategic mapping snapshot
  
  DateTime? _lastTileClickTime;
  DateTime? _lastPopupClosedTime;
  int _maxRecoveryTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _setupGame();
    PersonaMR().startChapterTimer("Bölüm 3: Parazitler");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPopupRain();
      _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (t) => setState(() {}));
    });
  }

  void _setupGame() {
    List<String> baseSymbols = ['#', '%', '&', '@', '\$', '*', '?', '!'];
    _symbols = [...baseSymbols, ...baseSymbols]..shuffle();
    _isRevealed = List.filled(16, false);
    _isMatched = List.filled(16, false);
  }

  void _startPopupRain() {
    _popupTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isCompleted) return;
      if (_popups.length < 5) {
        _addRandomPopup();
      }
    });
  }

  void _addRandomPopup() {
    final random = math.Random();
    final type = random.nextInt(3);
    final top = 50.0 + random.nextDouble() * (MediaQuery.of(context).size.height - 300);
    final left = 20.0 + random.nextDouble() * (MediaQuery.of(context).size.width - 250);

    final key = UniqueKey();
    _popupSpawnTimes[key] = DateTime.now(); // Record exact spawn time

    setState(() {
      _popups.add(
        Positioned(
          top: top,
          left: left,
          key: key,
          child: _buildDistractionPopup(type, key),
        ),
      );
      PersonaMR().recordInteraction("Bölüm 3: Parazitler", "POPUP_SPAWNED", metadata: {"type": type});
      AudioService().playGlitchSound();
    });
  }

  Widget _buildDistractionPopup(int type, Key key) {
    String title = "";
    String content = "";
    Color color = AppTheme.neonCyan;

    switch (type) {
      case 0:
        title = "SİSTEM GÜNCELLEMESİ [v9.3]";
        content = "Kritik güvenlik yamaları indiriliyor... Yüklemek için onayla.";
        color = Colors.orange;
        break;
      case 1:
        title = "KANTİN MENÜSÜ [GÜNCELLENDİ]";
        content = "Günün Menüsü: Sentetik Protein Bloğu (Limon Aromalı).";
        color = Colors.green;
        break;
      case 2:
        title = "ARŞİV MESAJI [GİZLİ]";
        content = "Gönderen: [BİLİNMEYEN]. Mesaj: 'Işıkları asla kapatma...'";
        color = Colors.purpleAccent;
        break;
    }

    return GestureDetector(
      onTap: () {
        // V3 Telemetry Analizi
        if (_popupSpawnTimes.containsKey(key)) {
          int reactionTime = DateTime.now().difference(_popupSpawnTimes[key]!).inMilliseconds;
          if (reactionTime < 500) _immediateDismissals++; // Dürtüsel
          if (reactionTime > 3000) _readingParalysisCount++; // Odak erozyonu
          PersonaMR().recordInteraction("Bölüm 3: Parazitler", "POPUP_CLOSED", metadata: {"reactionTime": reactionTime});
          _lastPopupClosedTime = DateTime.now();
        }

        setState(() => _distractionClicks++);
        _removePopup(key);
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                Icon(Icons.close, color: color, size: 14),
              ],
            ),
            const Divider(color: Colors.white24),
            Text(
              content,
              style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: color)),
                child: Text("KAPAT", style: GoogleFonts.rajdhani(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removePopup(Key key) {
    setState(() {
      _popups.removeWhere((p) => p.key == key);
    });
  }

  void _onTileTap(int index) {
    if (_isCompleted || _isProcessing || _isRevealed[index] || _isMatched[index]) return;

    // V3 Telemetry (Spam / Recovery / Memory tracking)
    DateTime now = DateTime.now();
    if (_lastTileClickTime != null && now.difference(_lastTileClickTime!).inMilliseconds < 300) {
      _spamClicks++; 
    }
    if (_lastPopupClosedTime != null) {
      int recoveryTime = now.difference(_lastPopupClosedTime!).inMilliseconds;
      _recoveryTimes.add(recoveryTime); // For avg calculation
      if (recoveryTime > _maxRecoveryTimeMs) _maxRecoveryTimeMs = recoveryTime;
      _lastPopupClosedTime = null;
    }
    _lastTileClickTime = now;

    _gameClicks++;
    
    // Snap seenIndices for Metodik Analysis at move 8
    if (_gameClicks == 8) {
      _seenIndicesAtMove8 = _seenIndices.length;
    }

    setState(() {
      _isRevealed[index] = true;
      AudioService().playTypingBeep();
    });
    PersonaMR().recordInteraction("Bölüm 3: Parazitler", "TILE_FLIPPED", metadata: {"index": index, "symbol": _symbols[index]});

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      _isProcessing = true;
      if (_symbols[_firstSelectedIndex!] == _symbols[index]) {
        // MATCH!
        _matchesFound++;
        _isMatched[_firstSelectedIndex!] = true;
        _isMatched[index] = true;
        
        // Mark as seen
        _seenIndices.add(_firstSelectedIndex!);
        _seenIndices.add(index);
        
        PersonaMR().recordInteraction("Bölüm 3: Parazitler", "MATCH_FOUND", metadata: {"symbol": _symbols[index]});
        _firstSelectedIndex = null;
        _isProcessing = false;
        if (_matchesFound == 8) _completeChapter();
      } else {
        // NO MATCH (Potential Actual Memory Error)
        _matchErrors++;
        
        // IF we've seen at least one of these before and it's not a match, it's a Memory Fail
        if (_seenIndices.contains(_firstSelectedIndex!) || _seenIndices.contains(index)) {
          _actualMemoryErrors++;
        }
        
        // Add to seen indices after reveal
        _seenIndices.add(_firstSelectedIndex!);
        _seenIndices.add(index);

        PersonaMR().recordInteraction("Bölüm 3: Parazitler", "MATCH_FAIL", metadata: {"s1": _symbols[_firstSelectedIndex!], "s2": _symbols[index]});
        Timer(const Duration(milliseconds: 600), () {
          setState(() {
            _isRevealed[_firstSelectedIndex!] = false;
            _isRevealed[index] = false;
            _firstSelectedIndex = null;
            _isProcessing = false;
          });
        });
      }
    }
  }

  void _completeChapter() {
    _isCompleted = true;
    _stopwatch.stop();
    final decisionTime = _stopwatch.elapsedMilliseconds;
    
    double avgRecovery = _recoveryTimes.isEmpty 
        ? 0 
        : _recoveryTimes.reduce((a, b) => a + b) / _recoveryTimes.length;

    List<String> collectedTriggers = [
      "distraction_clicks_$_distractionClicks",
      "game_clicks_$_gameClicks",
      "focus_ratio_${_gameClicks / (_gameClicks + _distractionClicks + 1)}"
    ];

    // V3 Analitik Sinyaller
    if (_immediateDismissals > 5) collectedTriggers.add("immediate_dismissal");
    if (_readingParalysisCount > 3) collectedTriggers.add("reading_paralysis");
    if (_actualMemoryErrors > 6) collectedTriggers.add("heavy_memory_fail");
    if (avgRecovery > 2500) collectedTriggers.add("slow_recovery");

    PersonaMR().logDecision(
      moduleId: "MOD_1",
      chapterId: "Bölüm 3: Parazitler",
      choiceId: "MATCHING_COMPLETE", 
      durationMs: decisionTime,
      triggers: collectedTriggers,
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 3: Parazitler",
      totalTimeMs: decisionTime,
      additionalData: {
        "missedPopups": _popups.length,
        "symbolMatchErrors": _matchErrors,
        "actualMemoryErrors": _actualMemoryErrors,
        "seenIndicesCount_8": _seenIndicesAtMove8 ?? _seenIndices.length,
        "avgRecoveryTimeMs": avgRecovery.toInt(),
        "immediateDismissals": _immediateDismissals,
        "readingParalysisCount": _readingParalysisCount,
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
          completedChapterTitle: "Bölüm 3: Parazitler",
          nextChapterHint: "Sinaptik eşleştirme başarılı. Sıradaki: karanlık koridorlar.",
          nextScreen: Chapter4Screen(),
        )));
      }
    });
  }

  @override
  void dispose() {
    _popupTimer?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Concept Visual
          Positioned.fill(child: Image.asset("assets/images/chapter3_background.png", fit: BoxFit.cover, color: Colors.black.withOpacity(0.8), colorBlendMode: BlendMode.darken)),
          // Background Reactor Core Visual
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.red.withOpacity(0.15),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          SizedBox.expand(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 10),
                      _buildNarrativeWindow(),
                      const SizedBox(height: 30),
                      _buildMatchingGrid(),
                      const SizedBox(height: 30),
                      _buildProgressStatus(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const DevNav(), // Geliştirici Navigasyonu

          // POPUPS on top
          ..._popups,
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
            Text("BÖLÜM 3: PARAZİTLER", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            Text("HEDEF: SİNAPTİK EŞLEŞTİRME", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 9)),
          ],
        ),
        Text("${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNarrativeWindow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(4)),
      child: Text(
        "\"Gürültüyü görmezden gel. Sadece reaktörün sinapslarına odaklan. Bir hata, tüm sistemi karanlığa gömer.\"",
        style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildMatchingGrid() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2))),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: 16,
        itemBuilder: (context, index) {
          bool revealed = _isRevealed[index] || _isMatched[index];
          return GestureDetector(
            onTap: () => _onTileTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: revealed ? AppTheme.neonCyan.withOpacity(0.1) : Colors.black,
                border: Border.all(color: revealed ? AppTheme.neonCyan : Colors.white10, width: revealed ? 2 : 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                revealed ? _symbols[index] : "",
                style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressStatus() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("BİRLEŞİK SİNAPS DURUMU:", style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10)),
            Text("${(_matchesFound / 8 * 100).toInt()}%", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _matchesFound / 8, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan)),
      ],
    );
  }
}
