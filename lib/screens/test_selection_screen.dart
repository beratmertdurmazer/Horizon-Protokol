import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/screens/intro_screen.dart';
import 'package:horizon_protocol/screens/user_entry_screen.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/database_service.dart';

class TestSelectionScreen extends StatefulWidget {
  final String userName;
  final String position;
  final String company;

  const TestSelectionScreen({
    super.key,
    required this.userName,
    required this.position,
    required this.company,
  });

  @override
  State<TestSelectionScreen> createState() => _TestSelectionScreenState();
}

class _TestSelectionScreenState extends State<TestSelectionScreen> {
  String? _hoveredId;
  bool _isGenesisCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTestStatus();
  }

  Future<void> _checkTestStatus() async {
    final candidate = PersonaMR().currentCandidate;
    if (candidate != null) {
      // Hem metrics'e hem de adayın kendisine bak
      final metrics = await DatabaseService().getMetricsForCandidate(candidate.id);
      
      if (mounted) {
        setState(() {
          // Çok katmanlı bitirme kontrolü:
          // 1. Bölüm 13 verisi var mı? 
          // 2. Adayın daha önceden hesaplanmış skorları/bulguları var mı?
          final hasFinalMetric = metrics.any((m) => m.chapterId.toLowerCase().contains("bölüm 13"));
          final hasPreviousScores = candidate.scores.isNotEmpty || candidate.behavioralFlags.isNotEmpty;
          
          _isGenesisCompleted = hasFinalMetric || hasPreviousScores;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arkaplan Izgarası
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Üst Bar - Daraltılmış ve Taşma Korumalı
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 40, vertical: 20),
                  child: _buildTopBar(isMobile),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          "ERİŞİLEBİLİR PROTOKOLLER // SELECT ASSESSMENT",
                          style: GoogleFonts.sourceCodePro(
                            color: AppTheme.neonCyan.withOpacity(0.5),
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 25),
                        
                        // Kartlar - GRID yerine esnek WRAP veya dinamik GRID
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double cardWidth = isMobile 
                                ? constraints.maxWidth 
                                : (constraints.maxWidth - 40) / 2;
                            if (constraints.maxWidth > 1200) {
                              cardWidth = (constraints.maxWidth - 60) / 3;
                            }

                            return Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                _buildProtocolCard(
                                  id: "genesis_demo",
                                  title: "PROTOCOL: GENESIS PRIME (DEMO)",
                                  description: _isGenesisCompleted 
                                    ? "Bu protokol sizin için başarıyla tamamlandı. Verileriniz analiz merkezine iletildi."
                                    : "13 bölümlük klinik analiz prototipi. Bilişsel adaptasyon ve kriz yönetim telemetri ölçümü.",
                                  isLocked: _isGenesisCompleted,
                                  tag: _isGenesisCompleted ? "TAMAMLANDI" : "SİMÜLASYON ALPHA",
                                  icon: _isGenesisCompleted ? Icons.check_circle_outline : Icons.psychology_outlined,
                                  width: cardWidth,
                                  isCompleted: _isGenesisCompleted,
                                ),
                                _buildProtocolCard(
                                  id: "genesis_full",
                                  title: "PROTOCOL: GENESIS PRIME (FULL CORE)",
                                  description: "Genişletilmiş karar ağacı ve çapraz korelasyon matrisi. Henüz erişime açılmadı.",
                                  isLocked: true,
                                  tag: "YÜKLENİYOR...",
                                  icon: Icons.hub_outlined,
                                  width: cardWidth,
                                ),
                                _buildProtocolCard(
                                  id: "neural_matrix",
                                  title: "NEURAL INTEGRITY MATRIX // V2",
                                  description: "Zihinsel dayanıklılık, stres toleransı ve nörotik stabilite ölçümü. Yakında.",
                                  isLocked: true,
                                  tag: "ERİŞİM ENGELLENDİ",
                                  icon: Icons.dataset_outlined,
                                  width: cardWidth,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Alt Bilgi
                _buildFooter(isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Sol Başlık
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: AppTheme.neonCyan, size: 20),
                onPressed: () {
                  // Tüm sayfaları sil ve en başa dön
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const UserEntryScreen()),
                    (route) => false,
                  );
                },
                tooltip: "OTURUMU KAPAT",
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "HORIZON PROTOKOLÜ",
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 20,
                        letterSpacing: 2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "SİSTEM_HAZIR",
                      style: GoogleFonts.sourceCodePro(
                        color: AppTheme.neonCyan.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),

        // Sağ Kullanıcı Paneli - Taşıyıcı
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
              color: Colors.white.withOpacity(0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: isMobile ? 12 : 14
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.company.toUpperCase(),
                  style: GoogleFonts.sourceCodePro(
                    color: AppTheme.neonCyan.withOpacity(0.7), 
                    fontSize: 8
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolCard({
    required String id,
    required String title,
    required String description,
    required bool isLocked,
    required String tag,
    required IconData icon,
    required double width,
    bool isCompleted = false,
  }) {
    final bool isHovered = _hoveredId == id;
    final Color mainColor = isCompleted ? Colors.greenAccent : (isLocked ? Colors.white10 : AppTheme.neonCyan);

    return InkWell(
      onTap: isLocked ? null : () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const IntroScreen()));
      },
      onHover: (hovering) => setState(() => _hoveredId = hovering ? id : null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isHovered && !isLocked ? mainColor.withOpacity(0.08) : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: isHovered && !isLocked ? mainColor : mainColor.withOpacity(0.15),
            width: isHovered && !isLocked ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ÖNEMLİ: Kendi içeriği kadar yükselir
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: mainColor, size: 28),
                if (isLocked && !isCompleted) 
                  const Icon(Icons.lock_outline, color: Colors.white12, size: 14),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
              ],
            ),
            const SizedBox(height: 25), // İKON VE METİN ARASI SABİT MESAFE
            Text(
              title,
              style: GoogleFonts.rajdhani(
                color: isLocked && !isCompleted ? Colors.white24 : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLocked && !isCompleted ? Colors.transparent : mainColor.withOpacity(0.1),
                border: Border.all(color: (isLocked && !isCompleted) ? Colors.white10 : mainColor.withOpacity(0.3)),
              ),
              child: Text(
                tag,
                style: GoogleFonts.sourceCodePro(
                  color: isLocked && !isCompleted ? Colors.white12 : mainColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "© 2026 HORIZON ENGINE",
            style: GoogleFonts.sourceCodePro(color: Colors.white12, fontSize: 8),
          ),
          if (!isMobile)
            Text(
              "KLİNİK VERİ ANALİZİ MODU AKTİF",
              style: GoogleFonts.sourceCodePro(color: Colors.white12, fontSize: 8),
            ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.15)
      ..strokeWidth = 0.3;

    const double step = 50.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
