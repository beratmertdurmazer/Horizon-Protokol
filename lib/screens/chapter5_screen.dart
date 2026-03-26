import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/module_transition_screen.dart';
import 'package:horizon_protocol/screens/chapter6_screen.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';

class Chapter5Screen extends StatefulWidget {
  const Chapter5Screen({super.key});

  @override
  State<Chapter5Screen> createState() => _Chapter5ScreenState();
}

class _Chapter5ScreenState extends State<Chapter5Screen> with SingleTickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  Timer? _countdownTimer;
  Timer? _heartbeatTimer;
  int _secondsRemaining = 45;
  int _failedAttempts = 0;
  int? _readingTime;
  bool _usedDecoy = false;
  bool _isFinished = false;
  final TextEditingController _pinController = TextEditingController();
  late AnimationController _flickerController;
  
  final String _manualText = "PROXIMA-7 ACİL DURUM PROTOKOLÜ: Reaktör çekirdeği termal stabilizasyonunu kaybetmeye başladığında, soğutma sıvısı basıncı %40 seviyesinin altına inmeden önce manyetik muhafaza kilitlerinin manuel olarak serbest bırakılması birincil önceliktir. Bu işlem sırasında kontrol paneli üzerindeki sinaptik rölelerin aşırı yüklenmesini önlemek için terminal erişim yetkisi doğrulanmalıdır. Yedek kodlar sisteme sadece ana terminal üzerinden değil, acil durum fiziksel arayüzüyle de girilebilir. Aksi takdirde bypass sistemini aktive etmek zorunda kalacaksınız; bu işlem çekirdek bütünlüğünü %60 oranında riske atar ancak saniyeler kazandırır. Elektromanyetik parazitler nedeniyle ekran üzerindeki veriler bozulabilir, bu durumda analog göstergelere güvenmelisiniz. Eğer sistemi manuel olarak kilitleyemezseniz istasyonun tamamen karanlığa gömülmesi kaçınılmaz bir sondur. Bu terminalin erişim anahtarı son cümlededir. Stabilizasyon için giriş yapmanız gereken kod: horizon_omega";

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);
    _startCountdown();
    PersonaMR().startChapterTimer("Bölüm 5: Reaktör Krizi");
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isFinished || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 10 && _heartbeatTimer == null) {
          _startHeartbeat();
        }
        if (_secondsRemaining <= 0) {
          _endChapter("TIMEOUT_FROZEN");
        }
      });
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_isFinished || !mounted) {
        timer.cancel();
        return;
      }
      AudioService().playHeartbeat();
    });
  }

  void _handlePinSubmit() {
    final input = _pinController.text.trim().toLowerCase();
    
    // Tuzak Kontrolü (PROXIMA-7 ACİL DURUM PROTOKOLÜ)
    if (input.contains("proxima") || input.contains("acil")) {
      _usedDecoy = true;
    }

    if (input == "horizon_omega") {
      PersonaMR().recordInteraction("Bölüm 5: Reaktör Krizi", "PIN_SUCCESS");
      _endChapter("SUCCESS_PIN_SOLVED");
    } else {
      _failedAttempts++;
      PersonaMR().recordInteraction("Bölüm 5: Reaktör Krizi", "PIN_ERROR", metadata: {"input": _pinController.text});
      AudioService().playGlitchSound();
      _pinController.clear();
    }
  }

  void _handleBypass() {
    PersonaMR().recordInteraction("Bölüm 5: Reaktör Krizi", "BYPASS_CLICKED");
    _endChapter("SUCCESS_BYPASS_PANIC");
  }

  void _endChapter(String result) {
    if (_isFinished) return;
    setState(() => _isFinished = true);
    _stopwatch.stop();
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    AudioService().stopAll();
    AudioService().playMetalClunk();

    final decisionTime = _stopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 5: Reaktör Krizi",
      choiceId: result,
      durationMs: decisionTime,
      triggers: ["reactor_fix", result.toLowerCase()],
    );

    String simpleResult = "Timeout";
    if (result == "SUCCESS_PIN_SOLVED") simpleResult = "Success";
    if (result == "SUCCESS_BYPASS_PANIC") simpleResult = "Bypass";

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 5: Reaktör Krizi",
      totalTimeMs: decisionTime,
      additionalData: {
        "failedAttempts": _failedAttempts,
        "readingTimeMs": _readingTime ?? decisionTime,
        "usedDecoy": _usedDecoy,
        "result": simpleResult,
      },
    );

    // Final result screen or next module logic
    _showFinalReport(result);
  }

  void _showFinalReport(String result) {
    String title = "";
    String desc = "";
    IconData icon = Icons.info;
    Color color = Colors.white;

    switch (result) {
      case "SUCCESS_PIN_SOLVED":
        title = "REAKTÖR STABİL";
        desc = "Doğru protokolle çekirdek stabilizasyonu sağlandı. Manyetik kilitler devrede.";
        icon = Icons.check_circle_outline;
        color = AppTheme.neonCyan;
        break;
      case "SUCCESS_BYPASS_PANIC":
        title = "BYPASS AKTİF";
        desc = "Acil durum bypass'ı ile reaktör korundu. Çekirdek bütünlüğü kritik seviyede.";
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case "TIMEOUT_FROZEN":
        title = "SİSTEM ÇÖKTÜ";
        desc = "Terminal erişimi sağlanamadı. Reaktör çekirdeği infilak etti.";
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(side: BorderSide(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 60),
                const SizedBox(height: 20),
                Text(title, style: GoogleFonts.rajdhani(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModuleTransitionScreen(
                          moduleTitle: "MODÜL 2",
                          moduleSubtitle: "SESSİZ ÇIĞLIK",
                          objective: "Yüksek stres altında karar verme hızı ve duygusal dayanıklılık analizi.",
                          icon: Icons.graphic_eq_outlined,
                          nextScreen: const Chapter6Screen(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.2), side: BorderSide(color: color)),
                  child: Text("SONRAKİ BÖLÜME GEÇ", style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _flickerController.dispose();
    _pinController.dispose();
    AudioService().stopAll();
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
            child: Image.asset(
              "assets/images/chapter5_background.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.85),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Red Pulse (Intensifies as time runs out)
          AnimatedBuilder(
            animation: _flickerController,
            builder: (context, child) {
              double intensity = (_secondsRemaining <= 10) ? _flickerController.value : 0.05;
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.red.withOpacity(intensity * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox.expand(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 15),
                      _buildManualArea(),
                      const SizedBox(height: 25),
                      _buildDecisionControls(),
                    ],
                  ),
                ),
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
            Text("BÖLÜM 5: SON SANİYELER", style: GoogleFonts.rajdhani(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            Text("KRİTİK TERMİNAL ERİŞİMİ", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
          ],
        ),
        _buildCountdownTimer(),
      ],
    );
  }

  Widget _buildCountdownTimer() {
    Color color = _secondsRemaining <= 10 ? Colors.red : AppTheme.neonCyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "${_secondsRemaining}S",
        style: GoogleFonts.sourceCodePro(color: color, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildManualArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book, color: Colors.white38, size: 16),
              const SizedBox(width: 10),
              Text("REAKTÖR ACİL DURUM KILAVUZU (MANUAL_V4)", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Text(
            _manualText,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionControls() {
    return Column(
      children: [
        // PIN INPUT
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _pinController,
            style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "PIN GİRİN",
              hintStyle: GoogleFonts.sourceCodePro(color: Colors.white12, fontSize: 18),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _handlePinSubmit(),
            onChanged: (val) {
              if (_readingTime == null && val.isNotEmpty) {
                _readingTime = _stopwatch.elapsedMilliseconds;
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _handlePinSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonCyan.withOpacity(0.2),
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: AppTheme.neonCyan),
          ),
          child: Text("SİSTEMİ KİLİTLE (SUBMIT)", style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white10)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text("VEYA RİSK AL", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
            ),
            const Expanded(child: Divider(color: Colors.white10)),
          ],
        ),
        const SizedBox(height: 20),
        // BYPASS BUTTON
        OutlinedButton(
          onPressed: _handleBypass,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            side: const BorderSide(color: Colors.red, width: 2),
            backgroundColor: Colors.red.withOpacity(0.05),
          ),
          child: Column(
            children: [
              Text("EMERGENCY BYPASS", style: GoogleFonts.rajdhani(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
              Text("DİKKAT: ÇEKİRDEK KARARLILIĞI %40 DÜŞECEK", style: GoogleFonts.sourceCodePro(color: Colors.red.withOpacity(0.7), fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }
}
