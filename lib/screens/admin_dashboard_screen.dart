import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/models/game_models.dart';
import 'package:horizon_protocol/services/database_service.dart';
import 'package:horizon_protocol/services/assessment_engine.dart';
import '../utils/string_extensions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final AssessmentEngine _engine = AssessmentEngine();
  
  List<Candidate> _candidates = [];
  Candidate? _selectedCandidate;
  List<Decision> _selectedDecisions = [];
  List<ChapterMetric> _selectedMetrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final list = await _db.getAllCandidates();
      setState(() {
        _candidates = list;
        // Auto-select removed to keep the dashboard empty initially
        if (list.isEmpty) {
          _selectedCandidate = null;
          _selectedMetrics = [];
          _selectedDecisions = [];
        }
      });
    } catch (e) {
      debugPrint("DB_LOAD_ERROR: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCandidate(Candidate c) async {
    setState(() {
      _selectedCandidate = c;
      _isLoading = true;
    });
    
    try {
      final decisions = await _db.getDecisionsForCandidate(c.id);
      final metrics = await _db.getMetricsForCandidate(c.id);
      
      setState(() {
        _selectedDecisions = decisions..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _selectedMetrics = metrics..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: isMobile ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.neonCyan),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ) : null,
        title: Text(
          "HORIZON PROTOKOLÜ // ANALİZ_MERKEZİ",
          style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
                    IconButton(
            tooltip: "Tüm Verileri Temizle",
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: () => _confirmClearAll(),
          ),
          IconButton(
            tooltip: "Yenile",
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
            onPressed: _loadCandidates,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.neonCyan.withOpacity(0.3), height: 1),
        ),
      ),
      drawer: isMobile ? Drawer(
        backgroundColor: Colors.black,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.neonCyan.withOpacity(0.2)))),
              child: Center(
                child: Text("ADAY LİSTESİ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(child: _buildSidebarContents()),
          ],
        ),
      ) : null,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
        : _candidates.isEmpty 
          ? _buildEmptyState()
          : Row(
              children: [
                if (!isMobile) _buildSidebar(),
                
                Expanded(
                  child: _selectedCandidate == null 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.radar_outlined, color: AppTheme.neonCyan.withOpacity(0.05), size: 100),
                            const SizedBox(height: 20),
                            Text("SİSTEM BEKLEMEDE // ANALİZ İÇİN BİR ADAY SEÇİNİZ", 
                              style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 13, letterSpacing: 2)),
                            const SizedBox(height: 10),
                            Text("PROTOKOL_HAZIR: VERİ OKUMA İZNİ BEKLENİYOR",
                              style: GoogleFonts.sourceCodePro(color: Colors.white12, fontSize: 9)),
                          ],
                        ),
                      )
                    : _buildAnalyticsDashboard(isMobile),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storage_outlined, size: 64, color: Colors.white12),
          const SizedBox(height: 20),
          Text("VERİTABANI BOŞ", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 18)),
          Text("HENÜZ TAMAMLANMIŞ TEST BULUNAMADI", style: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 12)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() => _isLoading = true);
              await _db.seedMockData();
              await _loadCandidates();
            },
            icon: const Icon(Icons.download, color: Colors.black),
            label: Text("DEMO VERİ YÜKLE", style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: _buildSidebarContents(),
    );
  }

  Widget _buildSidebarContents() {
    return ListView.builder(
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final c = _candidates[index];
        final isSelected = _selectedCandidate?.id == c.id;
        return ListTile(
          tileColor: isSelected ? AppTheme.neonCyan.withOpacity(0.05) : Colors.transparent,
          title: Text(c.name.toUpperCase(), style: GoogleFonts.rajdhani(color: isSelected ? AppTheme.neonCyan : Colors.white70, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.position, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
              Text(c.company, style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white24),
            onPressed: () => _confirmDelete(c),
          ),
          onTap: () {
            _selectCandidate(c);
            if (MediaQuery.of(context).size.width < 900) Navigator.pop(context);
          },
        );
      },
    );
  }

  void _confirmDelete(Candidate c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text("ADAYI SİL?", style: GoogleFonts.rajdhani(color: Colors.redAccent)),
        content: Text("${c.name} isimli adayı ve tüm verilerini silmek istediğinize emin misiniz?", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL", style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              await _db.deleteCandidate(c.id);
              Navigator.pop(context);
              _loadCandidates();
              if (_selectedCandidate?.id == c.id) setState(() => _selectedCandidate = null);
            }, 
            child: const Text("SİL", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text("TÜM VERİLERİ TEMİZLE?", style: GoogleFonts.rajdhani(color: Colors.redAccent)),
        content: Text("Tüm aday kayıtları ve test verileri kalıcı olarak silinecektir. Emin misiniz?", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL", style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              await _db.clearDatabase();
              Navigator.pop(context);
              _loadCandidates();
              setState(() => _selectedCandidate = null);
            }, 
            child: const Text("HER ŞEYİ SİL", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsDashboard(bool isMobile) {
    if (_selectedCandidate == null) return const SizedBox();
    
    // Anlık analiz verileri
    final scores = _engine.calculateScores(_selectedDecisions, _selectedMetrics);
    final flags = _engine.generateFlags(_selectedDecisions, _selectedMetrics);
    final archetype = _engine.getLeadershipArchetype(scores['leadership_impact'] ?? 0, scores['strategic_prioritization'] ?? 0);

    // BÜTÜNLEŞİK PROFİL verileri
    final compositeScores = _engine.calculateCompositeScores(flags);
    final styleProfile = _engine.getStyleProfile(flags);
    final crossFlags = _engine.generateCrossChapterFlags(flags, _selectedMetrics);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCandidateHero(isMobile, scores, archetype),
          const SizedBox(height: 25),
          
          _buildExecutiveSummary(scores, flags),
          const SizedBox(height: 25),

          // ═══ YENİ: BÜTÜNLEŞİK PROFİL ═══
          _buildCompositeProfileSection(compositeScores, styleProfile, crossFlags, isMobile),
          const SizedBox(height: 25),
          
          _buildFlagsSection(flags),
          const SizedBox(height: 40),
          
          // BÖLÜM BAZLI ANALİZ RAPORLARI
          _buildChapter1Report(isMobile),
          _buildChapter2Report(isMobile),
          _buildChapter3Report(isMobile),
          _buildChapter4Report(isMobile),
          _buildChapter5Report(isMobile),
          _buildChapter6Report(isMobile),
          _buildChapter7Report(isMobile),
          _buildChapter8Report(isMobile),
          _buildChapter9Report(isMobile),
          _buildChapter10Report(isMobile),
          _buildChapter11Report(isMobile),
          _buildChapter12Report(isMobile),
          _buildChapter13Report(isMobile),
          
          const SizedBox(height: 40),
          _buildDetailedAnalysis(),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Back to left-aligned
      children: [
        Text("DETAYLI BÖLÜM ANALİZİ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedMetrics.length,
          itemBuilder: (context, index) {
            final metric = _selectedMetrics[index];
            final chapterDecisions = _selectedDecisions.where((d) => d.chapterId == metric.chapterId).toList();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                color: Colors.white.withOpacity(0.02),
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(metric.chapterId.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("${(metric.totalTimeMs / 1000).toStringAsFixed(1)} Saniye", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10)),
                  ],
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white10, height: 20),
                          if (chapterDecisions.isNotEmpty) ...[
                            Text("ANA KARARLAR", 
                              textAlign: TextAlign.left,
                              style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            ...chapterDecisions.map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("SEÇİM: ${_translateChoice(d.choiceId).toTurkishUpperCase()}", 
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.start,
                                    spacing: 5,
                                    children: d.triggers.map((t) => Text("#$t", style: GoogleFonts.sourceCodePro(color: Colors.blueAccent.withOpacity(0.5), fontSize: 9))).toList(),
                                  ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 15),
                          ],
                          
                          // KLİNİK ANALİZ METRİKLERİ
                          _buildClinicalMetrics(metric.additionalData),
                          const SizedBox(height: 25),
                          
                          // ETKİLEŞİM ZAMAN ÇİZELGESİ (TIMELINE)
                          Text("ETKİLEŞİM ZAMAN ÇİZELGESİ", 
                            textAlign: TextAlign.left,
                            style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _buildTimeline(metric.additionalData?['timeline'] as List?),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClinicalMetrics(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const SizedBox();
    
    // Summary metrics, excluding timeline
    final metrics = data.entries.where((e) => e.key != 'timeline').toList();
    if (metrics.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("KLİNİK ANALİZ METRİKLERİ", 
          textAlign: TextAlign.left,
          style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 15,
          runSpacing: 10,
          children: metrics.map((e) {
            final value = e.value;
            String displayValue = value.toString();
            
            // Format specific complex types (like maps in Triage levels)
            if (value is Map) {
              displayValue = value.entries.map((v) => "${_translateMetadata(v.key.toString())}: %${v.value}").join(", ");
            } else if (value is List) {
              displayValue = "[${value.map((v) => _translateMetadata(v.toString())).join(", ")}]";
            } else if (value is int && (e.key.toLowerCase().contains("time") || e.key.toLowerCase().contains("duration") || e.key.toLowerCase().contains("speed") || e.key.toLowerCase().contains("delay"))) {
               displayValue = "${(value / 1000).toStringAsFixed(2)}s";
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.white.withOpacity(0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(_translateMetricKey(e.key), style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 8)),
                   const SizedBox(height: 2),
                   Text(displayValue, style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _translateMetricKey(String key) {
    switch (key) {
      case 'errorCount': return 'Hata Sayısı';
      case 'durationMs': return 'Toplam Süre';
      case 'timeToFirstClick': return 'İlk Karar Hızı';
      case 'switch_count': return 'Sistem Geçiş Sayısı';
      case 'final_levels': return 'Final Sistem Seviyeleri';
      case 'focus_order': return 'Öncelik Sıralaması';
      case 'missedPopups': return 'Kaçırılan Uyarılar';
      case 'symbolMatchErrors': return 'Eşleştirme Hataları';
      case 'failedAttempts': return 'Hatalı Denemeler';
      case 'readingTime': return 'Okuma Süresi (Eski)';
      case 'readingTimeMs': return 'İnceleme Süresi';
      case 'usedDecoy': return 'Tuzak Veri Seçildi';
      case 'result': return 'Görev Eylemi';
      case 'actualMemoryErrors': return 'Gerçek Unutma/Hata';
      case 'avgRecoveryTimeMs': return 'Parazit Sonrası Toparlanma';
      case 'seenIndicesCount_8': return 'İlk 8 Hamle Derinliği';
      case 'selectedArea': return 'Feda Edilen Kurumsal Alan';
      case 'revokedConfirmations': return 'Karar Tereddütü (Vazgeçme)';
      case 'navigationSwitches': return 'Alanlar Arası Dağılım';
      case 'viewDurations': return 'Alanlarda Harcanan İnceleme Süreleri';
      case 'totalDurationMs': return 'Kriz Süresi';
      case 'mutingSpeed': return 'Susturma Refleksi';
      case 'reactionTime': return 'Reaksiyon Süresi';
      case 'actionDelay': return 'Eylem Gecikmesi';
      case 'tile_flips': return 'Kutu Çevirme Sayısı';
      case 'box_closing_strategy': return 'Kutu Kapama Stratejisi';
      case 'negotiationSteps': return 'Müzakere Adımı';
      case 'finalAgreement': return 'Uzlaşı Sonucu';
      case 'forgiveDelay': return 'Karar Ağırlığı/Gecikmesi';
      case 'delegationRatio': return 'Yetki Devri Oranı';
      case 'readDuration': return 'Metin İnceleme Süresi';
      case 'finalDecision': return 'Final Kararı';
      default: return key.replaceAll('_', ' ').toTurkishUpperCase();
    }
  }

  Widget _buildCandidateHero(bool isMobile, Map<String, double> scores, String archetype) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        gradient: LinearGradient(colors: [AppTheme.neonCyan.withOpacity(0.05), Colors.transparent]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ADAY_KODU: ${_selectedCandidate!.id}", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10)),
              Text(_selectedCandidate!.name.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text("ARKETİP: $archetype", style: GoogleFonts.sourceCodePro(color: Colors.white30, fontSize: 10)),
                  const SizedBox(width: 20),
                  Text("ŞİRKET: ${_selectedCandidate!.company}", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (!isMobile) 
            Text("${(scores['section1_adaptability'] ?? 0).toInt()}%", 
              style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

    
  

  Widget _buildExecutiveSummary(Map<String, double> scores, List<String> flags) {
    final summary = _engine.getExecutiveSummary(scores, flags);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neonCyan.withOpacity(0.05),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppTheme.neonCyan, size: 18),
              const SizedBox(width: 10),
              Text("YÖNETİCİ ÖZETİ & PSİKOLOJİK PROFİL", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Color _getFlagColor(String flag) {
    final f = flag.toLowerCase();
    
    // YÜKSEK (Kırmızı) Risk Taşıyanlar:
    if (f.contains('uyarı') || f.contains('risk') || f.contains('dürtüsel') || f.contains('reaktif') || f.contains('paralizi') || f.contains('zafiyeti') || f.contains('bariyeri') || f.contains('otoriter') || f.contains('makyavelist') || f.contains('savunmacı') || f.contains('kararsızlığı') || f.contains('deneme_yanılma') || f.contains('kaçınma') || f.contains('cezalandırıcı') || f.contains('blokaj') || f.contains('erozyon') || f.contains('tünel vizyonu') || f.contains('işlem ataleti') || f.contains('kaygısı') || f.contains('yüzeysel') || f.contains('ihlal') || f.contains('yanılgı') || f.contains('döngü')) {
      return Colors.redAccent;
    }
    
    // ORTA (Turuncu/Sarı) Gelişim Alanı Taşıyanlar:
    if (f.contains('rastgele başarı') || f.contains('örüntü') || f.contains('dengeli analizci') || f.contains('bilişsel efor') || f.contains('dürtüsel refleks') || f.contains('çalkantı') || f.contains('kural esnetme')) {
      return Colors.orangeAccent;
    }
    
    // POZİTİF (Yeşil) Yetkinlikler:
    return Colors.greenAccent;
  }

  Widget _buildFlagsSection(List<String> flags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DAVRANIŞSAL BULGULAR", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: flags.map((f) {
            final color = _getFlagColor(f);
            
            return Tooltip(
              message: _getFlagDescription(f),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: color)),
              textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.5)),
                  color: color.withOpacity(0.05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(color == Colors.redAccent ? Icons.warning_amber_rounded : (color == Colors.orangeAccent ? Icons.info_outline : Icons.check_circle_outline), 
                      color: color, size: 12),
                    const SizedBox(width: 8),
                    Text(f.replaceAll('_', ' ').toTurkishUpperCase(), 
                      style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BÜTÜNLEŞİK PROFİL BÖLÜMÜ (Composite Profile Section)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCompositeProfileSection(
    Map<String, double> compositeScores,
    Map<String, String> styleProfile,
    List<Map<String, String>> crossFlags,
    bool isMobile,
  ) {
    // Radar verisi hazırlama
    final axisOrder = ['cognitive_agility', 'stress_resilience', 'ethical_integrity',
                       'leadership', 'decision_quality', 'adaptability'];
    final validScores = axisOrder
        .where((k) => compositeScores[k] != null && compositeScores[k]! >= 0)
        .toList();

    if (validScores.isEmpty && crossFlags.isEmpty) {
      return const SizedBox(); // Veri yoksa gösterme
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.15)),
        gradient: LinearGradient(
          colors: [Colors.cyanAccent.withOpacity(0.03), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: AppTheme.neonCyan, size: 18),
              const SizedBox(width: 10),
              Text("BÜTÜNLEŞİK PROFİL ANALİZİ",
                style: GoogleFonts.rajdhani(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 2,
                )),
            ],
          ),
          const SizedBox(height: 5),
          Text("13 bölümün çapraz korelasyonu ile üretilmiş bileşik yetkinlik haritası",
            style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 9)),
          const SizedBox(height: 25),

          // ─── RADAR CHART + SKOR TABLOSU ───
          if (validScores.isNotEmpty) ...[
            isMobile
              ? Column(children: [
                  _buildRadarChart(compositeScores, styleProfile, axisOrder),
                  const SizedBox(height: 20),
                  _buildScoreTable(compositeScores, axisOrder),
                ])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildRadarChart(compositeScores, styleProfile, axisOrder),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 2,
                      child: _buildScoreTable(compositeScores, axisOrder),
                    ),
                  ],
                ),
            const SizedBox(height: 25),
          ],

          // ─── STİL PROFİLİ ───
          _buildStyleProfileBar(styleProfile),
          const SizedBox(height: 25),

          // ─── ÇAPRAZ KORELASYON ALARMLARI ───
          if (crossFlags.isNotEmpty) ...[
            Text("ÇAPRAZ KORELASYON TESPİTLERİ",
              style: GoogleFonts.rajdhani(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...crossFlags.map((c) => _buildCorrelationCard(c)),
          ],
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<String, double> scores, Map<String, String> style, List<String> axisOrder) {
    // 8 eksen: 6 yetkinlik + 2 stil
    final List<String> allAxes = [...axisOrder, 'team_style', 'decision_method'];
    final List<String> labels = [
      ...axisOrder.map((k) => AssessmentEngine.getAxisLabel(k)),
      'Ekip Stili',
      'Karar Metodu',
    ];

    final List<double> values = [
      ...axisOrder.map((k) => (scores[k] ?? 50).clamp(0, 100).toDouble()),
      double.tryParse(style['team_style_score'] ?? '50') ?? 50,
      double.tryParse(style['decision_method_score'] ?? '50') ?? 50,
    ];

    return SizedBox(
      height: 300,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.white10, width: 0.5),
          gridBorderData: const BorderSide(color: Colors.white10, width: 0.3),
          tickBorderData: const BorderSide(color: Colors.transparent),
          tickCount: 4,
          ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 8),
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: labels[index],
              angle: 0,
            );
          },
          dataSets: [
            // Yetkinlik skorları (ilk 6) - Cyan
            RadarDataSet(
              dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
              borderColor: AppTheme.neonCyan,
              fillColor: AppTheme.neonCyan.withOpacity(0.15),
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTable(Map<String, double> scores, List<String> axisOrder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("YETKİNLİK SKORLARI",
          style: GoogleFonts.rajdhani(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...axisOrder.map((key) {
          final score = scores[key] ?? -1;
          final label = AssessmentEngine.getAxisLabel(key);
          final isNoData = score < 0;
          final color = isNoData ? Colors.white24
              : score >= 70 ? Colors.greenAccent
              : score >= 40 ? Colors.orangeAccent
              : Colors.redAccent;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                      style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 10)),
                    Text(isNoData ? "VERİ YOK" : "${score.toInt()}/100",
                      style: GoogleFonts.sourceCodePro(
                        color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: isNoData ? 0 : (score / 100).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStyleProfileBar(Map<String, String> style) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
        color: Colors.blueAccent.withOpacity(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint, color: Colors.blueAccent, size: 14),
              const SizedBox(width: 8),
              Text("LİDERLİK DNA'SI (STİL PROFİLİ)",
                style: GoogleFonts.rajdhani(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                )),
            ],
          ),
          const SizedBox(height: 15),
          _buildStyleAxis(
            "EKİP KURMA",
            "Teknik Odaklı",
            "Sosyal Uyum Odaklı",
            double.tryParse(style['team_style_score'] ?? '50') ?? 50,
            style['team_style'] ?? 'Veri Yok',
          ),
          const SizedBox(height: 15),
          _buildStyleAxis(
            "KARAR METODU",
            "Sezgisel / Hızlı",
            "Metodik / Analitik",
            double.tryParse(style['decision_method_score'] ?? '50') ?? 50,
            style['decision_method'] ?? 'Veri Yok',
          ),
        ],
      ),
    );
  }

  Widget _buildStyleAxis(String title, String leftLabel, String rightLabel, double score, String currentLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 9)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(currentLabel,
                style: GoogleFonts.sourceCodePro(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.amber.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.3),
                ]),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Positioned(
              left: (score / 100).clamp(0.02, 0.98) * (MediaQuery.of(context).size.width * 0.3),
              child: Container(
                width: 12,
                height: 12,
                transform: Matrix4.translationValues(-6, -3, 0),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 8)),
            Text(rightLabel, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 8)),
          ],
        ),
      ],
    );
  }

  Widget _buildCorrelationCard(Map<String, String> c) {
    final type = c['type'] ?? 'info';
    Color color;
    IconData icon;
    switch (type) {
      case 'success':
        color = Colors.greenAccent;
        icon = Icons.check_circle_outline;
        break;
      case 'warning':
        color = Colors.orangeAccent;
        icon = Icons.warning_amber_rounded;
        break;
      case 'danger':
        color = Colors.redAccent;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.blueAccent;
        icon = Icons.info_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withOpacity(0.03),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['title'] ?? '',
                      style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: color.withOpacity(0.1),
                      child: Text(c['source'] ?? '',
                        style: GoogleFonts.sourceCodePro(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c['detail'] ?? '',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: 30,
          borderRadius: BorderRadius.circular(2),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.white.withOpacity(0.02),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(List? timeline) {
    if (timeline == null || timeline.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text("Detaylı etkileşim verisi bulunamadı.", style: GoogleFonts.sourceCodePro(color: Colors.white12, fontSize: 9)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timeline.map((entry) {
        final time = (entry['t'] as int? ?? 0) / 1000.0;
        final action = entry['a'] as String? ?? "Unknown";
        
        // Human readable mapping and coloring
        final String readableAction = _translateTimelineAction(action, entry);
        Color actionColor = Colors.white60; // Default color
        
        if (action.contains("ERROR") || action.contains("FAIL") || action.contains("PANIC") || action.contains("RED_BUTTON") || action.contains("PIN_ERROR")) actionColor = Colors.redAccent;
        else if (action.contains("SUCCESS") || action.contains("GREEN") || action.contains("CHECK") || action.contains("MATCH_FOUND") || action.contains("PIN_SUCCESS")) actionColor = Colors.greenAccent;
        else if (action.contains("CLICK") || action.contains("SELECTION") || action.contains("CHOICE") || action.contains("DECISION") || action.contains("BLUE_BUTTON") || action.contains("CHARACTER_SELECTED")) actionColor = AppTheme.neonCyan;
        else if (action.contains("WARNING") || action.contains("POPUP_SPAWNED") || action.contains("BYPASS")) actionColor = Colors.orange;
        else if (action.contains("FOCUS") || action.contains("MUTED") || action.contains("DIALOGUE") || action.contains("HANDLED_MISTAKE")) actionColor = Colors.teal;
        else if (action.contains("ANALYSIS") || action.contains("KAOS_ACCEPTED")) actionColor = Colors.blue;
        else if (action.contains("REFLECTION")) actionColor = Colors.white70;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 50,
                child: Text("${time.toStringAsFixed(2)}s", 
                  style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan.withOpacity(0.5), fontSize: 9)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(readableAction, 
                  style: GoogleFonts.sourceCodePro(color: actionColor, fontSize: 10)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _translateTimelineAction(String action, Map<String, dynamic> entry) {
    switch (action) {
      case 'STARTED': return 'Simülasyon başlatıldı';
      case 'COMPLETED': return 'Bölüm tamamlandı';
      case 'POPUP_SPAWNED': return '⚠️ Sistem uyarısı çıktı';
      case 'POPUP_CLOSED': return '✅ Uyarı kapatıldı (${entry['reactionTime']}ms)';
      case 'TILE_FLIPPED': return '🔍 Kutu çevrildi (#${entry['id']})';
      case 'BOX_CLOSED': return '📦 Kutu kapatıldı';
      case 'ERROR_CLICK': return '❌ Hatalı deneme saptandı';
      case 'SUCCESS_MATCH': return '🌟 Başarılı eşleşme';
      case 'FINAL_DECISION': return '🏁 Final kararı verildi';
      case 'BYPASS_CLICKED': return '🚨 Bypass butonu ile kriz geçildi';
      case 'PANIC_CLICK': return '😱 Panik tıklaması (Hata #${entry['count']})';
      case 'ALARMS_MUTED': return '🔇 Alarmlar susturuldu (Refah tercihi)';
      case 'KAOS_ACCEPTED': return '📡 Alarmlar kabul edildi (Dikkat tercihi)';
      case 'BLUE_BUTTON_PRESSED': return '🔵 Analitik butona basıldı (#${entry['count']})';
      case 'RED_BUTTON_PRESSED': return '🔴 Dürtüsel butona basıldı';
      case 'REFLECTION_CHOICE': return '💭 Öz-eleştiri yapıldı: ${_translateMetadata(entry['text'] ?? entry['type'] ?? 'Bilinmiyor')}';
      case 'CHARACTER_SELECTED': return '👤 Partner seçildi: ${entry['name']}';
      case 'DIALOGUE_CHOICE': return '💬 Diyalog tercihi: ${entry['collaborative'] == true ? 'İşbirlikçi' : 'Otoriter'}';
      case 'HANDLED_MISTAKE': return '⚖️ Hata yönetimi: ${entry['punitive'] == true ? 'Cezalandırıcı' : 'Affedici'}';
      case 'PIN_ERROR': return '❌ PIN hatası: ${entry['input']}';
      case 'PIN_SUCCESS': return '✅ PIN kodu doğru girildi';
      default: return action;
    }
  }

  String _translateMetadata(String val) {
    switch (val.toLowerCase()) {
      case 'dormitory': return 'Yatakhane';
      case 'lab': return 'Laboratuvar';
      case 'quarters': return 'Yaşam Alanı';
      case 'strategic': return 'Stratejik Entegrasyon';
      case 'empathetic': return 'Empatik Liderlik';
      case 'reactor': return 'Füzyon Reaktörü';
      case 'oxygen': return 'Oksijen Sistemi';
      case 'comms': return 'İletişim Ünitesi';
      case 'internal': return 'İçsel Sorumluluk';
      case 'external': return 'Dışsal Faktörler';
      case 'tile_flips': return 'Kutu Çevirme Sayısı';
      case 'box_closing_strategy': return 'Kutu Kapama Stratejisi';
      case 'failedattempts': return 'Hatalı Giriş Denemesi';
      case 'readingtime': return 'Okuma ve Analiz Süresi';
      case 'errorcount': return 'Hata Sayısı';
      case 'responsedelay': return 'Yanıt Gecikmesi';
      case 'mutingspeed': return 'Susturma Hızı';
      case 'switch_count': return 'Sistem Değiştirme';
      default: return val.toTurkishUpperCase();
    }
  }

  String _translateChoice(String id) {
    switch (id.toLowerCase()) {
      case 'authority_over_ethics': return 'Otorite Odaklı Yaklaşım';
      case 'ethics_over_authority': return 'Etik ve Değer Odaklı';
      case 'delegate_trust': return 'Güven ve Delegasyon';
      case 'self_reliance_control': return 'Bireysel Kontrol ve Denetim';
      case 'punish_food_ration': return 'Cezalandırıcı Strateji';
      case 'forgive_and_cooperate': return 'Affedici ve İşbirlikçi';
      case 'character_selected': return 'Karakter Seçimi Tamamlandı';
      case 'muted': return 'Alarm Susturuldu';
      case 'success': return 'Erişim Başarılı';
      case 'continue': return 'Devam Etme Kararı';
      case 'lab': return 'Laboratuvar Analizi';
      case 'dorm': return 'Yatakhane Güvenliği';
      case 'elara': return 'Elara (Teknik Odak)';
      case 'kael': return 'Kael (Güvenlik Odak)';
      case 'collaborative': return 'Demokratik/Katılımcı';
      case 'authoritarian': return 'Otoriter/Lider Baskın';
      case 'help_others_unprotected': return 'Fedakar/Başkalarına Yardım';
      case 'mask': return 'Bireyici/Önce Kendi Güvenliği';
      case 'deactivate': return 'Kriz Modülünü Devre Dışı Bırak';
      case 'delegate': return 'Yetki Devri (Güven)';
      case 'self': return 'Bireysel Kontrol / Mikro-Yönetim';
      case 'distrust': return 'Güvensizlik / Suçlayıcı';
      case 'delegate': return 'Yetki Devredildi (Güven)';
      default: return id.replaceAll('_', ' ').toTurkishUpperCase();
    }
  }

  // --- BÖLÜM BAZLI RAPOR WIDGETLARI ---

  Widget _buildChapter1Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 1"));
    } catch (_) {
      return const SizedBox(); // Veri yoksa gösterme
    }

    final flags = _engine.generateFlags([], [metric]);
    if (flags.isEmpty) flags.add("Analitik Gözlem");
    String topFinding = flags.first;
    if (flags.contains("Adaptif Öğrenme")) topFinding = "Adaptif Öğrenme";
    else if (flags.contains("Analitik Çeviklik")) topFinding = "Analitik Çeviklik";

    bool isPositive = topFinding.contains("ADAPTİF") || topFinding.contains("ÇEVİKLİK") || topFinding.contains("SİSTEMATİK") || topFinding.contains("ÖĞRENME");
    Color resultColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    // Detaylar
    final String timeStr = "${(metric.totalTimeMs / 1000).toStringAsFixed(1)} saniye";
    final timeline = List<dynamic>.from(metric.additionalData?['timeline'] ?? []);
    final correctAction = timeline.cast<Map<String, dynamic>?>().firstWhere((a) => a?['a'] == 'CORRECT_ANSWER', orElse: () => null);
    final int trials = timeline.where((a) => a['a'] == 'WRONG_ANSWER').length + (correctAction != null ? 1 : 0);
    final String status = correctAction != null ? "BAŞARIYLA TAMAMLANDI" : "BİLEMEDEN BİTTİ";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 1: SOĞUK UYANIŞ",
      testType: "🔬 BİLİŞSEL ADAPTASYON TESTİ",
      status: status,
      isSuccess: correctAction != null,
      resultColor: resultColor,
      metric1Label: "Süre",
      metric1Value: timeStr,
      metric2Label: "Performans",
      metric2Value: "$trials hamle",
      findings: flags,
      clinicalNote: "Akıcı zeka, kriz anında bilişsel kaynakları aktive edebilme, örüntü yakalama ve hata sonrası toparlanma hızı.",
      footer: "Bu rapor, adayın kriz anındaki analitik şemaları ve hata sonrası reaksiyon telemetrisi üzerinden üretilmiştir.",
    );
  }

  Widget _buildChapter2Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 2"));
    } catch (_) {
      return const SizedBox();
    }

    final flags = _engine.generateFlags([], [metric]);
    if (flags.isEmpty) return const SizedBox();

    bool isNegative = flags.any((f) => f.contains("Kaygı") || f.contains("Tünel") || f.contains("Paralizi"));
    Color resultColor = isNegative ? Colors.redAccent : AppTheme.neonCyan;

    final data = metric.additionalData ?? {};
    final levels = data['final_levels'] as Map? ?? {};
    final String levelsStr = "R:%${levels['reactor'] ?? 0} | O:%${levels['oxygen'] ?? 0} | İ:%${levels['comms'] ?? 0}";
    final String switches = "${data['switch_count'] ?? 0} geçiş";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 2: İLK TRİAJ",
      testType: "⚖️ ÖNCELİKLENDİRME VE KAYNAK YÖNETİMİ",
      status: "TAMAMLANDI",
      isSuccess: true,
      resultColor: resultColor,
      metric1Label: "Sistem Sağlığı",
      metric1Value: levelsStr,
      metric2Label: "Stres Reaksiyonu",
      metric2Value: switches,
      findings: flags,
      clinicalNote: "Adayın kaos altında Kurum (Reaktör) / İnsan (Oksijen) / Koordinasyon (İletişim) üçgeninde yaptığı stratejik seçimler ve odak kapasitesi.",
      footer: "Bu rapor, adayın kriz anındaki önceliklendirme hiyerarşisi ve kaynak dağıtım telemetrisi üzerinden üretilmiştir.",
    );
  }

  Widget _buildReportContainer({
    required bool isMobile,
    required String chapterTitle,
    required String testType,
    required String status,
    required bool isSuccess,
    required Color resultColor,
    required String metric1Label,
    required String metric1Value,
    required String metric2Label,
    required String metric2Value,
    required List<String> findings,
    required String clinicalNote,
    required String footer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.neonCyan, size: 18),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chapterTitle, style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  Text(testType, style: GoogleFonts.sourceCodePro(color: Colors.purpleAccent.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isSuccess ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
                  border: Border.all(color: (isSuccess ? Colors.greenAccent : Colors.redAccent).withOpacity(0.3))
                ),
                child: Text(status, style: GoogleFonts.sourceCodePro(color: isSuccess ? Colors.greenAccent : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportLine(metric1Label, metric1Value),
                    const SizedBox(height: 12),
                    _buildReportLine(metric2Label, metric2Value),
                  ],
                ),
              ),
              if (!isMobile) const SizedBox(width: 40),
              if (!isMobile)
                Expanded(
                  flex: 3,
                  child: _buildFindingsList(findings, clinicalNote),
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 25),
            _buildFindingsList(findings, clinicalNote),
          ],
          const SizedBox(height: 25),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Text("// $footer", style: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildFindingsList(List<String> findings, String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("🧪 KLİNİK BULGU ANALİZİ:", style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...findings.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSingleFinding(f),
        )).toList(),
        const SizedBox(height: 5),
        const Divider(color: Colors.white10),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: "Bu ölçümleme; ", style: GoogleFonts.inter(color: Colors.white30, fontSize: 10)),
              TextSpan(text: "$note gibi yetkinlikleri değerlendirmeyi amaçlar.", style: GoogleFonts.inter(color: Colors.white30, fontSize: 10, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleFinding(String flag) {
    final bool isNegative = flag.contains("Kaygı") || flag.contains("Tünel") || flag.contains("Paralizi") || flag.contains("Blokaj") || flag.contains("Dürtüsel") || flag.contains("Tepki") || flag.contains("Erozyonu") || flag.contains("Ataleti") || flag.contains("Yüzeysel");
    final bool isNeutral = flag.contains("Rastgele") || flag.contains("Örüntü") || flag.contains("Efor") || flag.contains("Refleks") || flag.contains("Analizci") || flag.contains("Çalkantı");
    
    final Color color = isNegative 
      ? Colors.redAccent 
      : (isNeutral ? (flag.contains("Analizci") ? Colors.yellowAccent : Colors.orangeAccent) : (flag.contains("Orkestrasyon") || flag.contains("Özgüvenli") ? AppTheme.neonCyan : Colors.greenAccent));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border(left: BorderSide(color: color, width: 2))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(flag.toTurkishUpperCase(), style: GoogleFonts.rajdhani(color: color, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(_getFlagDescription(flag), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildReportLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toTurkishUpperCase(), style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 9)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChapter3Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 3"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    // Klinik Başarı Rengi
    bool isNegative = flags.any((f) => f.contains("Kaygı") || f.contains("Zafiyeti") || f.contains("Dürtüsel"));
    Color resultColor = isNegative ? Colors.orangeAccent : Colors.greenAccent;

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 3: PARAZİTLER",
      testType: "🧠 DİKKAT FİLTRELEME VE HAFIZA DUYARLILIĞI",
      status: "TAMAMLANDI",
      isSuccess: true,
      resultColor: resultColor,
      metric1Label: "Hafıza Hataları",
      metric1Value: "${data['actualMemoryErrors'] ?? 0} Kayıp",
      metric2Label: "Toparlanma Hızı",
      metric2Value: "${((data['avgRecoveryTimeMs'] ?? 0) / 1000).toStringAsFixed(1)}sn",
      findings: flags,
      clinicalNote: "Adayın bilişsel yük altında veri bütünlüğünü koruma kapasitesi ve dış parazitlere (pop-up) karşı reaksiyon hızı.",
      footer: "Bu rapor, adayın multitasking performansı ve gerçek unutma (actual memory error) telemetrisi baz alınarak üretilmiştir.",
    );
  }

  Widget _buildChapter4Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 4"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    // Karar Kalitesi Rengi
    bool isNegative = flags.any((f) => f.contains("Çalkantı") || f.contains("Yüzeysel"));
    Color resultColor = isNegative ? Colors.orangeAccent : AppTheme.neonCyan;

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 4: KARANLIK KORİDORLAR",
      testType: "⚖️ ETİK KARAR VERME VE DEĞER HİYERARŞİSİ",
      status: "KARAR KAYDEDİLDİ",
      isSuccess: true,
      resultColor: resultColor,
      metric1Label: "Feda Edilen",
      metric1Value: _translateMetadata(data['selectedArea'] ?? 'Belirsiz'),
      metric2Label: "Karar Kararlılığı",
      metric2Value: "${data['revokedConfirmations'] ?? 0} Vazgeçme",
      findings: flags,
      clinicalNote: "Adayın kriz anında hangi kurumsal değeri (Ar-Ge, İnsan, ESG) önceliklendirdiği ve kararının arkasında durma kapasitesi.",
      footer: "Bu rapor, adayın 2-aşamalı onay sürecindeki tereddütleri ve alanlar arası geçiş analitiği baz alınarak üretilmiştir.",
    );
  }

  Widget _buildChapter5Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 5"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    bool isNegative = flags.any((f) => f.contains("İhlal") || f.contains("Esnetme") || f.contains("Yanılgı") || f.contains("Döngüsü") || f.contains("Paralizi"));
    Color resultColor = isNegative ? Colors.orangeAccent : AppTheme.neonCyan;

    final resultStr = data['result'] ?? 'Timeout';
    final resultTranslated = resultStr == 'Success' ? 'Aksiyon: Doğru Şifre' : (resultStr == 'Bypass' ? 'Aksiyon: Manuel Bypass' : 'Aksiyon: Donma (Zaman Aşımı)');

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 5: REAKTÖR KRİZİ",
      testType: "☢️ BİLGİ SÜZME VE RİSK YÖNETİMİ",
      status: "TAMAMLANDI",
      isSuccess: true,
      resultColor: resultColor,
      metric1Label: "Okuma & Kavrama Süresi",
      metric1Value: "${(((data['readingTimeMs'] as num?) ?? (data['readingTime'] as num?) ?? 0).toDouble() / 1000).toStringAsFixed(1)}sn",
      metric2Label: "Karar Tipi",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Adayın kriz anında, hata yapmadan uzun bir metinden güvenilir veriyi çekme veya kestirme yolu (bypass) tercih etme kognitif süreçleri.",
      footer: "Bu rapor, adayın zaman baskısı altındaki dürtüselliği ve sahte bayraklara (fake flag) düşme oranı baz alınarak üretilmiştir.",
    );
  }

  Widget _buildChapter6Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 6"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    // Negatif bulguları tespit et
    bool isNegative = flags.any((f) => f.contains("İptali") || f.contains("Zafiyeti") || f.contains("Panik"));
    Color resultColor = isNegative ? Colors.orangeAccent : AppTheme.neonCyan;

    final resultStr = data['finalDecision'] ?? 'isolate';
    final resultTranslated = resultStr == 'vigilance' ? 'Gerçeklik (Sistemleri Açık Tut)' : 'İzolasyon (Sensörleri Kör Et)';

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 6: ALARM YORGUNLUĞU",
      testType: "🔊 DUYUSAL TOLERANS VE KRİZ REAKSİYONU",
      status: "TAMAMLANDI",
      isSuccess: true,
      resultColor: resultColor,
      metric1Label: "Motor Panik",
      metric1Value: "${data['panicClicks'] ?? 0} Hatalı İtki",
      metric2Label: "Sistematik Tercih",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Adayın şiddetli duyusal uyaran (sensory overload) altında gösterdiği fiziksel panik seviyesi ve konfor/gözlem ikileminde aldığı stratejik konum.",
      footer: "Bu rapor, adayın kriz anındaki karar hızı (acelecilik) ve rastgele tıklama oranları baz alınarak üretilmiştir.",
    );
  }

  Widget _buildChapter7Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 7"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    // Negatif bulguları tespit et (İçinde "Dürtüsel", "Panik", "Kilitlenme" geçenler)
    bool isNegative = flags.any((f) => f.contains("Kör Aksiyon") || f.contains("Dürtüsel Panik") || f.contains("Kilitlenme"));
    Color resultColor = isNegative ? Colors.orangeAccent : AppTheme.neonCyan;

    final resultStr = data['finalResult'] ?? 'TIMEOUT';
    String resultTranslated = "Zaman Aşımı";
    if (resultStr == "BINARY_SOLVED") resultTranslated = "Kod Deşifre Edildi";
    if (resultStr == "FAIL_IMPULSIVE_RANDOM") resultTranslated = "Hatalı Acil Durum Butonu";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 7: SİSTEMSEL ÇÖKÜŞ",
      testType: "💥 SİNYAL-GÜRÜLTÜ AYRIŞTIRMA VE PANİK",
      status: "TAMAMLANDI",
      isSuccess: !isNegative,
      resultColor: resultColor,
      metric1Label: "Aksiyon Süresi",
      metric1Value: "${(data['decisionTimeMs'] ?? 0) / 1000} Sn",
      metric2Label: "Sistem Sonucu",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Adayın aşırı görsel gürültü ve yüksek stres altında paniğe kapılıp kapılmadığı; problemi okuyup deşifre etmek ile ezbere inisiyatif almak arasındaki seçimi.",
      footer: "Bu rapor, ekrandaki yoğun kaos altındayken adayın dürtüsel kararlar alıp almadığı ölçülerek oluşturulmuştur.",
    );
  }

  Widget _buildChapter8Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 8"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    // Negatif bulguları tespit et
    bool isNegative = flags.any((f) => f.contains("Dürtüsel Kahramanlık") || f.contains("Akut Şok Kilitlenmesi"));
    Color resultColor = isNegative ? Colors.orangeAccent : AppTheme.neonCyan;

    final resultStr = data['finalResult'] ?? 'TIMEOUT';
    String resultTranslated = "Zaman Aşımı";
    if (resultStr == "OXYGEN_MASK") resultTranslated = "Protokol / Oksijen Maskesi";
    if (resultStr == "BREACH_AREA") resultTranslated = "Kahramanlık / Sızıntıya Hücum";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 8: DIŞ GÖVDE ÇATLAĞI",
      testType: "🛡️ ACİL DURUM VE ŞOK YÖNETİMİ",
      status: "TAMAMLANDI",
      isSuccess: !isNegative,
      resultColor: resultColor,
      metric1Label: "Aksiyon Süresi",
      metric1Value: "${(data['reactionTimeMs'] ?? 0) / 1000} Sn",
      metric2Label: "Müdahale Stratejisi",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Ani ve şiddetli kriz ("+"Dış Gövde Çatlağı"+") anlarında kahramanlık sendromuna kapılmadan ilk güvenlik prosedürlerini işletip işletemediği.",
      footer: "Bu rapor, şok anında adayın önce kendi güvenliğini mi sağladığını yoksa fevri bir şekilde soruna mı atladığını ölçer.",
    );
  }

  Widget _buildChapter9Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 9"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    // Negatif bulguları tespit et (Orange veya Red profiller)
    bool isNegative = flags.any((f) => f.contains("Mazeretçi") || f.contains("Kaderci") || f.contains("Kurban") || f.contains("Sorumluluk Reddi"));
    Color resultColor = isNegative ? Colors.orangeAccent : AppTheme.neonCyan;

    final String selectedText = data['selectedText'] ?? "-";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 9: ENKAZIN ARDINDAN",
      testType: "🤔 İÇ/DIŞ DENETİM ODAĞI VE SAVUNMA MEKANİZMASI",
      status: "TAMAMLANDI",
      isSuccess: !isNegative,
      resultColor: resultColor,
      metric1Label: "Karar (Yanıt) Süresi",
      metric1Value: "${(data['responseDelay'] ?? 0) / 1000} Sn",
      metric2Label: "Seçilen Özeleştiri",
      metric2Value: "\"$selectedText\"",
      findings: flags,
      clinicalNote: "Adayın başarısızlık konseptinde hatanın sorumluluğunu (Internal) kendine mi, yoksa (External) çevresel şartlara mı atfettiğinin tespiti.",
      footer: "Bu rapor, adayın seçtiği kelime ve düşünme süresi baz alınarak psikolojik Denetim Odağını (Locus of Control) yansıtır.",
    );
  }

  Widget _buildChapter10Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 10"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    final String choice = data['choiceId'] ?? 'KAEL';
    bool isNegative = false;
    
    Color resultColor = choice == "ELARA" ? Colors.cyanAccent : Colors.blueAccent;

    String resultTranslated = choice == "ELARA" ? "Elara (Sosyal Lider)" : "Dr. Kael (Teknik Dahi)";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 10: BUZDAN ÇIKAN YÜZ",
      testType: "👥 PARTNER SEÇİMİ VE KRİTER ANALİZİ",
      status: "TAMAMLANDI",
      isSuccess: !isNegative,
      resultColor: resultColor,
      metric1Label: "İnceleme Süresi",
      metric1Value: "${(metric.totalTimeMs != 0 ? metric.totalTimeMs : (data['totalTimeMs'] ?? 0)) / 1000} Sn",
      metric2Label: "Seçilen Partner",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Adayın liderlik ekibi oluşturma vizyonu: Teknik mükemmeliyet odağı mı (Mavi - Kael), yoksa sosyal uyum ve ekip sinerjisi mi (Cyan - Elara)?",
      footer: "Bu rapor, adayın partner seçimindeki önceliklerini ve dosyaları inceleme titizliğini (bias kontrolü ile) ölçer.",
    );
  }

  Widget _buildChapter11Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 11"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    final String choice = data['choiceId'] ?? 'TIMEOUT';
    bool isNegative = choice == "MANIPULATIVE" || choice == "TIMEOUT";
    Color resultColor = isNegative ? Colors.redAccent : (choice == "COLLABORATIVE" ? Colors.greenAccent : AppTheme.neonCyan);

    String resultTranslated = "Karar Felci (Zaman Aşımı)";
    if (choice == "COLLABORATIVE") resultTranslated = "İşbirlikçi / Diyalog";
    if (choice == "RATIONAL") resultTranslated = "Rasyonel / Mantık";
    if (choice == "AUTHORITY") resultTranslated = "Otoriter / Emir";
    if (choice == "MANIPULATIVE") resultTranslated = "Manipülatif / Baskı";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 11: İLK TARTIŞMA",
      testType: "🤝 ÇATIŞMA YÖNETİMİ VE İKNA STİLİ",
      status: "TAMAMLANDI",
      isSuccess: !isNegative,
      resultColor: resultColor,
      metric1Label: "Yanıt Gecikmesi",
      metric1Value: "${(data['decisionDelay'] ?? 0) / 1000} Sn",
      metric2Label: "Seçilen Üslup",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Adayın kriz ve itiraz anlarında kullandığı iletişim dili; otorite kullanımı, manipülasyon eğilimi veya işbirlikçi tutumu.",
      footer: "Bu rapor, partner itirazı sonrası adayın verdiği tepkiyi ve karar verme hızını (45sn limitli) ölçer.",
    );
  }

  Widget _buildChapter12Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 12"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    final String choice = data['choiceId'] ?? 'CONSTRUCTIVE';
    bool isNegative = choice == "PUNITIVE";
    Color resultColor = choice == "CONSTRUCTIVE" ? Colors.greenAccent : (choice == "PROCEDURAL" ? Colors.yellowAccent : Colors.redAccent);

    String resultTranslated = "Gelişimsel / Affedici";
    if (choice == "PROCEDURAL") resultTranslated = "Prosedürel / Kuralcı";
    if (choice == "PUNITIVE") resultTranslated = "Cezalandırıcı / Sert";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 12: PARTNERİN HATASI",
      testType: "⚖️ HATA TOLERANSI VE SOSYAL UYALIM",
      status: "TAMAMLANDI",
      isSuccess: !isNegative,
      resultColor: resultColor,
      metric1Label: "Karar Süresi",
      metric1Value: "${metric.totalTimeMs / 1000} Sn",
      metric2Label: "Tepki Stili",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Adayın hata karşısındaki tutumu. Seçeneklerin renkli (G/S/K) sunulmasıyla adayın 'doğru olanı seçme' (Sosyal Arzu Edilebilirlik) eğilimi test edilmiştir.",
      footer: "Bu rapor, partnerin hatası sonrası adayın adalet duygusunu ve koçluk potansiyelini ölçer.",
    );
  }

  Widget _buildChapter13Report(bool isMobile) {
    ChapterMetric? metric;
    try {
      metric = _selectedMetrics.firstWhere((m) => m.chapterId.contains("Bölüm 13"));
    } catch (_) { return const SizedBox(); }

    final data = metric.additionalData ?? {};
    final flags = _engine.generateFlags([], [metric]);
    
    final String choice = data['choiceId'] ?? 'DISTRUST';
    bool isNegative = choice == "DISTRUST";
    Color resultColor = choice == "DELEGATE" ? Colors.greenAccent : (choice == "SELF" ? Colors.orangeAccent : Colors.redAccent);

    String resultTranslated = "Suçlayıcı / Güvensiz";
    if (choice == "DELEGATE") resultTranslated = "Güven Odaklı Delegasyon";
    if (choice == "SELF") resultTranslated = "Koruyucu / Mikro-Yönetim";

    return _buildReportContainer(
      isMobile: isMobile,
      chapterTitle: "BÖLÜM 13: GÜVEN TESTİ [FİNAL]",
      testType: "🤝 RADİKAL GÜVEN VE DELEGASYON",
      status: "TAMAMLANDI",
      isSuccess: !isNegative,
      resultColor: resultColor,
      metric1Label: "İnceleme Süresi",
      metric1Value: "${(data['readDuration'] ?? 0) / 1000} Sn",
      metric2Label: "Final Kararı",
      metric2Value: resultTranslated,
      findings: flags,
      clinicalNote: "Adayın en kritik (ölümcül risk) anında partnerine güvenip güvenmediği; yetkiyi kendisinde mi topladığı yoksa paylaşıp paylaşmadığı.",
      footer: "Bu rapor, Modül 3'ün final kararındaki delegasyon oranı ve geçmişe dönük (Bölüm 12) suçlama eğilimi baz alınarak üretilmiştir.",
    );
  }

  String _getFlagDescription(String flag) {
    // BÖLÜM 1 (V3) TANIMLARI
    if (flag.contains('Dürtüsel Aksiyon')) return "Veriyi tam analiz etmeden aksiyon alma eğilimi. Kriz anlarında planlı hareket etmek yerine hızlı denemelere başvurabilir.";
    if (flag.contains('Analitik Çeviklik')) return "Karmaşık veriler arasındaki ilişkiyi saniyeler içinde fark edebilme. Yeni bir problemi öğrenme hızı üst düzeydir.";
    if (flag.contains('Sistematik Çözümleme')) return "Baskı altında bile doğruluğu hıza tercih etme. Metodik, güvenilir ve adım adım ilerleyen problem çözme yaklaşımı.";
    if (flag.contains('Adaptif Öğrenme')) return "Hatalarından anında ders çıkarıp stratejisini revize edebilen, bilişsel esnekliği yüksek profil.";
    if (flag.contains('Rastgele Başarı')) return "Sistematik mantık yerine deneme-yanılma ile hedefe ulaşma. Sürdürülebilir başarı için yöntem desteği gerekebilir.";
    if (flag.contains('Örüntü Tanıma')) return "Kaotik veri içindeki ana yapıyı hızlıca fark etme. Detaylara hakimdir ancak bütünü tamamlamak için desteğe ihtiyaç duyabilir.";
    if (flag.contains('Bilişsel Blokaj')) return "Beklenmedik kriz anında karar mekanizmalarının anlık durması. Aşırı analiz (analysis paralysis) eğilimi.";

    // BÖLÜM 2 (V3) TANIMLARI
    if (flag.contains('Stratejik Orkestrasyon')) return "Tüm sistemleri denge eşiği olan %50'nin üzerinde tutmayı başaran, kısıtlı kaynağı mükemmel yöneten bütünsel liderlik profili.";
    if (flag.contains('Operasyonel Sürdürülebilirlik')) return "Kurumun ana motorunu (Reaktörü) her şeyin önüne koyan, operasyonel altyapı ve süreklilik odaklı yapı.";
    if (flag.contains('İnsan Sermayesi ve Esenlik')) return "Krizde bile en büyük değerin insan olduğunu unutmayan, ekip sağlığını ve esenliğini stratejik öncelik gören profil.";
    if (flag.contains('Paydaş Yönetimi ve İletişim')) return "Dış koordinasyonu ve paydaş iletişimi korumayı, krizi yönetmenin anahtarı gören stratejik yaklaşım.";
    if (flag.contains('Reaktif Kriz Tepkisi')) return "Baskı altında çok sık odak değiştiren; butonlar arasında panik belirtisi gösteren ve stres toleransı desteklenmesi gereken yapı.";
    if (flag.contains('Tünel Vizyonu')) return "Bir alana aşırı odaklanıp (%80+) diğer kritik alanların (%20 altı) çökmesine izin veren, dar bakış açısıyla feda eylemi yapan profil.";
    if (flag.contains('Karar Paralizi')) return "Süre dolmasına rağmen sistemleri kurtaramayan, baskı altında eylemsizliğe ve karar verme felcine düşen yapı.";

    // BÖLÜM 3 (V3) PARAZİTLER TANIMLARI
    if (flag.contains('Hiper-Odak')) return "En üst seviye işlem hızı ve odak kapasitesi; gürültü (pop-up) altında dahi elit seviyede bilişsel performans.";
    if (flag.contains('Dengeli Analizci')) return "Profesyonel standartlarda, sürdürülebilir ve güvenilir çalışma hızı; verimlilik ve dikkat dengesi yerinde.";
    if (flag.contains('Bilişsel Efor')) return "Dış uyaranlar (parazitler) nedeniyle işlem hızı yavaşlayan, odaklanmak için ekstra efor sarf eden profil.";
    if (flag.contains('İşlem Ataleti')) return "Baskı ve gürültü altında işlem hızı ciddi oranda düşen; zaman yönetimi ve odaklanma konusunda desteklenmesi gereken yapı.";
    if (flag.contains('Metodik Haritalama')) return "Önce veriyi toplayıp (şablonu çıkarıp) sonra aksiyona geçen, planlı ve sistematik çalışma disiplinine sahip profil.";
    if (flag.contains('Bilişsel Filtreleme')) return "Gereksiz uyaranları (parazitleri) başarıyla süzüp ana odağı koruma yetisi; gürültüden etkilenmez.";
    if (flag.contains('Bilişsel Toparlanma Hızı')) return "Kesinti (pop-up) sonrası ana işine saniyeler içinde geri dönebilen, bilişsel esnekliği yüksek çevik profil.";
    if (flag.contains('Dürtüsel Refleks')) return "Parazitleri ne olduğuna bakmadan kapatan; hızlı ama kriz anında kritik veriyi okumadan geçme riski taşıyan yapı.";
    if (flag.contains('Odak Erozyonu')) return "Gereksiz bilgiye takılıp asıl işini saniyelerce unutma eğilimi; çevresel gürültüye karşı hassas duyarlılık.";
    if (flag.contains('Hafıza Hassasiyeti')) return "Veri bütünlüğünü kriz anında bile koruyan; görülen bilgiyi unutma (Actual Memory Error) payı en düşük profil.";
    if (flag.contains('Multitasking Kaygısı')) return "Hem hafıza hem gürültü (pop-up) temizleme işini aynı anda yönetemeyen ve sistemleri multitasking altında çöken yapı.";

    // BÖLÜM 4: KARANLIK KORİDORLAR TANIMLARI
    if (flag.contains('Ar-Ge Koruyucusu')) return "Ciro kaybına (enerji) rağmen inovasyonu ve geleceği (Laboratuvar) savunan, Ar-Ge odaklı vizyoner liderlik profili.";
    if (flag.contains('Çalışan Hakları Savunucusu')) return "Ekonomik daralma anında en büyük kalem olarak çalışan mutluluğunu (Yatakhane) ve esenliğini kalkan yapan profil.";
    if (flag.contains('ESG / Vizyon Bilinci')) return "Kurumsal imajı, dış dünya duyarlılığını ve sürdürülebilirliği (Sera) kriz anında dahi öncelikli kale olarak tutan yapı.";
    if (flag.contains('Özgüvenli Karar')) return "Etik sorumluluk alırken sergilediği netlik ve kararlılık üst düzeyde; kararının arkasında duran güvenilir profil.";
    if (flag.contains('Bilişsel Çalkantı')) return "Onay aşamasında tereddüt yaşayan; etik yük altında içsel çatışması yükselen ve karar istikrarı desteklenmesi gereken yapı.";
    if (flag.contains('Yüzeysel Bakış')) return "Diğer birimlerin (paydaşların) uğrayacağı zararı tam analiz etmeden (10 saniye altı) dürtüsel feda etme eğilimi gösteren yapı.";

    // BÖLÜM 5: REAKTÖR KRİZİ TANIMLARI
    if (flag.contains('Kognitif Kaçınma / Protokol İhlali')) return "Zorlu görevlerden ve belirsizlikten anında kaçarak, kestirme ve riskli yolları tercih etme eğilimi.";
    if (flag.contains('Stres Bağımlı Kural Esnetme')) return "Artan strese (zaman kaygısına) dayanamayıp pes eden; zorlandığında doğruluğu feda edip risk alan profil.";
    if (flag.contains('Kognitif Dayanıklılık ve Süreç Sadakati')) return "Zaman daralsa ve stres artsa dahi onaylanmamış yollara sığınmadan, protokole son ana kadar bağlı kalan yapı.";
    if (flag.contains('Dürtüsel Yanılgı')) return "Analiz etmek yerine, ilk gözüne çarpan büyük işaretçiye refleksif olarak atlayan; bağlamı değerlendirmeyen profil.";
    if (flag.contains('Metodik Veri Süzme')) return "Tuzağa düşmeyen, yoğun bilgi yığılması içinden kritik ve doğru veriyi sabırla süzebilen yüksek dikkat yetkinliği.";
    if (flag.contains('Hevristik Deneme Döngüsü')) return "Sistematik çalışmak (okumak) yerine, kaba kuvvet ve tahmin yardımıyla rastgele denemeler yapan kaotik profil.";
    
    // BÖLÜM 6: ALARM YORGUNLUĞU TANIMLARI
    if (flag.contains('Erken Karar / Alarm Yorgunluğu Zafiyeti')) return "Strese (siren ve kaos) dayanamayıp saniyeler içinde refleksif karar alarak anksiyeteden kaçınma çabası.";
    if (flag.contains('Dengeli / Hesaplanmış Reaksiyon')) return "Kaosu belli bir süre analiz etme ve gözlemleme sabrını gösterdikten sonra hesaplanmış kararı veren yapı.";
    if (flag.contains('Akut Motor Panik')) return "Şiddetli kaos altında kontrolünü fareye yansıtıp ekranın rastgele yerlerine yüksek tıklama yapan reaktif kriz profili.";
    if (flag.contains('Soğukkanlı Kriz Gözlemcisi')) return "Ne derece sert bir kaos olursa olsun anlamsız fiziksel hareket göstermeyen, dürtüselliğine yenilmeyen sakin yapı.";
    if (flag.contains('Bilgi Algısı İptali / Körlük Kararı')) return "Stres seviyesini sonlandırmak için bilgi akışını kesmeyi seçen, konfor alanını şirketin gözlerine tercih eden profil.";
    if (flag.contains('Gerçeklik Metaneti / Şeffaflık')) return "Gerçekten kopmamak adına kendi kişisel rahatını (siren sesini) feda eden, adanmışlık düzeyi yüksek şeffaf karar.";

    // BÖLÜM 7: SİSTEMSEL ÇÖKÜŞ TANIMLARI
    if (flag.contains('Derin Analitik Odak')) return "Yoğun stres ve göz korkutucu kaos altında manipüle olmadan, problemin kökündeki veriyi sakince deşifre edebilen elit analitik beceri.";
    if (flag.contains('Şanslı Dürtüsellik')) return "Problemi veya bağlamı bilerek değil, tamamen şans eseri rastgele butonlara basarak kurtulan; kararları rasyonel bir temele dayanmayan profil.";
    if (flag.contains('Kör Aksiyon / Dürtüsel Panik')) return "Gürültüyü veya metni analiz edemeyip artan panikle 'bir şeyler yapmalıyım' diyerek hatalı butonlara saldıran tahripkâr dürtüsel yapı.";
    if (flag.contains('Bilişsel Kilitlenme (Bölüm 7)')) return "Karmaşık veri yığını karşısında sorumluluktan ve hata yapmaktan korkarak sürenin bitmesini izleyen felç olmuş (Freeze) karar mekanizması.";

    // BÖLÜM 8: DIŞ GÖVDE ÇATLAĞI TANIMLARI
    if (flag.contains('Hesaplanmış Akut Müdahale')) return "Şiddetli kriz anında şoka girmeyen ve 'kahramanlık' kompleksine düşmeden asgari güvenlik kuralını saniyeler içinde uygulayan lider donanımı.";
    if (flag.contains('Gecikmeli Güvenlik')) return "Şok uyaran karşısında anlık tereddüt yaşasa da nihayetinde doğru protokole dönmeyi başaran ve yıkıcı etkiyi sindirebilen yapı.";
    if (flag.contains('Dürtüsel Kahramanlık / Şehitlik Eğilimi')) return "Altyapıyı veya güvenliği sağlamadan (körü körüne) asıl soruna saldıran, kahramanlık sendromuyla sistemi daha çok riske atan dürtüsel profil.";
    if (flag.contains('Akut Şok Kilitlenmesi')) return "Beklenmeyen şiddetli şok krizlerinde karar alma/eylem kapasitesi (Freeze) tamamen sıfırlanan ve sorumluluk alamayan eylemsiz profil.";

    // BÖLÜM 9: ENKAZIN ARDINDAN TANIMLARI
    if (flag.contains('Sistemik Öz-Eleştiri')) return "Hatayı dışarıya atmadan rasyonel biçimde kabul edip kendi stratejisini sorgulayan en olgun lider profilidir (Growth Mindset).";
    if (flag.contains('Adaptif Öğrenme Odağı')) return "Başarısızlığı yapısal eksiklik değil bir gelişim fırsatı gibi okur. Çevresel yetersizlikleri suçlamadan kendi öğrenim kapasitesiyle ilgilenir.";
    if (flag.contains('Aşırı Öz-Yıkım')) return "Sorumluluğu tamamen alır ancak bu acıyı hissetmeye odaklanıp yıkıcı bir melankoliye (Rumination) kapılır. Krizlerde özgüven kırılması yaşar.";
    if (flag.contains('Yüzeysel & Taktiksel Pişmanlık')) return "Hatanın kök neden sistematiğine inmez. O anki anlık dikkatsizliğine (taktiksel bir yalpalama) 'panikledim' diyerek mazeret uydurur.";
    if (flag.contains('Mazeretçi Rasyonalizasyon')) return "Kibarca ve rasyonel maskeler ('Zaman yetmedi') üreterek hatayı çevresel şartlara bağlayan Dışsal Denetim Odağı yapısıdır.";
    if (flag.contains('Kaderci Öğrenilmiş Çaresizlik')) return "Suçlamaz ancak tamamen vazgeçer ('Kaçınılmaz son'). Mücadele etmeyi anlamsız bulan, zorlu hedeflerde kolay pes edecek konformist yapıdır.";
    if (flag.contains('Açık Kurban Psikolojisi')) return "Şirket kurallarını veya sistemi agresif şekilde suçlayan (Aggressive Projection). Takımda şikayet kültürü yayan toksik kurban psikolojisi.";
    if (flag.contains('Sorumluluk Reddi')) return "Hatayla olan en ufak bağını dahi defansif şekilde reddeden ('Benim suçum değil'). Narsistik bir savunmayla gelişime kapalı kalan yapı.";

    // BÖLÜM 10: BUZDAN ÇIKAN YÜZ TANIMLARI
    if (flag.contains('Sosyal Uyum Temelli Liderlik')) return "Başarıyı bireysel yetenekten ziyade ekip sinerjisi ve sosyal uyumda arayan, yapıcı ve bütünleştirici liderlik tarzı.";
    if (flag.contains('Teknik Yetkinlik Temelli Liderlik')) return "Duygusal uyum yerine teknik uzmanlığı ve performans çıktılarını önceliklendiren, rasyonel ve sonuç odaklı liderlik stili.";
    if (flag.contains('Metodik Veri İnceleme')) return "Kritik atamalarda aday dosyalarını ve verileri derinlemesine inceleyerek risk analizi yapan, titiz ve veriye dayalı karar mekanizması.";
    if (flag.contains('Sezgisel Seçim Refleksi')) return "Aday arketiplerini hızla süzüp seri karar veren, operasyonel çevikliği ve inisiyatif hızı yüksek liderlik refleksi.";

    // BÖLÜM 11: İLK TARTIŞMA TANIMLARI
    if (flag.contains('Psikolojik Güvenlik Mimarı')) return "Çatışma anında diyaloğu seçerek karşı tarafı dinleyen ve ortak zeminde buluşturan, yüksek EQ'lu liderlik profili.";
    if (flag.contains('Duygusuz Rasyonalizasyon')) return "İnsan faktörünü ve duyguları yok sayıp sadece mantık ve verilere dayalı soğuk ama rasyonel bir iletişim dili kullanan yapı.";
    if (flag.contains('Hiyerarşik Komuta ve Karar Keskinliği')) return "İtirazları zaman kaybı görüp 'Ben liderim' diyerek otoriteye ve emir-komuta zincirine sığınan, katı yönetici tarzı.";
    if (flag.contains('Duygusal Manipülasyon ve Toksik Etki')) return "Hedefe ulaşmak için suçluluk duygusu yaratmayı ve baskı kurmayı araç olarak kullanan, takım güvenini sarsabilecek manipülatif yapı.";
    if (flag.contains('Pasif-Agresif Karar Felci')) return "Baskı altında karar veremeyip 45 saniyelik kritik eşikte inisiyatifi başkasına devreden, kriz yönetiminde pasif kalan profil.";

    // BÖLÜM 12: PARTNERİN HATASI TANIMLARI
    if (flag.contains('Gelişimsel Liderlik (Hata Toleransı)')) return "Hatayı bir yıkım değil gelişim fırsatı olarak gören, ekibini cezalandırmak yerine kazanmaya odaklanan koçluk vizyonu.";
    if (flag.contains('Kuralcı ve Soğuk Adalet')) return "Duyguları (üzüntü, pişmanlık) yok sayıp adaleti sadece kural ve prosedürler üzerinden işleten, disiplin odaklı liderlik tarzı.";
    if (flag.contains('Cezalandırıcı Otoriter Yaklaşım')) return "Hatalara karşı sıfır toleransı olan, yaptırım ve ceza (kumanya kısıtlaması vb.) kullanarak otorite kuran sert yönetici profili.";

    // BÖLÜM 13: GÜVEN TESTİ TANIMLARI
    if (flag.contains('Güven Odaklı Delegasyon')) return "En kritik (hayat-memat) anında yetki devri yapabilen, partnerine inanan ve psikolojik güven inşası sağlayan liderlik tarzı.";
    if (flag.contains('Koruyucu Mikro-Yönetim')) return "Ekibi korumak veya risk almamak için her şeyi kendisi yapmaya çalışan, yetki devretmekte zorlanan mikro-yönetici.";
    if (flag.contains('Suçlayıcı ve Toksik Güvensizlik')) return "Ekibin geçmişteki hatalarını yüze vurarak güven bağını koparan ve krizde iletişimi reddeden toksik yönetim dili.";

    if (flag.contains('Akut Karar Paralizisi')) return "Zaman baskısı ve bilgi yoğunluğu altında 'Donma' (Freeze) tepkisi veren; kriz anlarında sorumluluk almaktan kaçınan profil.";

    return "Bilimsel telemetriye dayalı davranışsal gözlem saptanmıştır.";
  }
}
