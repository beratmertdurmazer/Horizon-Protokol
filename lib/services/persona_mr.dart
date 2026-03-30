import 'package:horizon_protocol/models/game_models.dart';
import 'package:horizon_protocol/services/database_service.dart';
import 'package:horizon_protocol/services/assessment_engine.dart';

class PersonaMR {
  static final PersonaMR _instance = PersonaMR._internal();
  factory PersonaMR() => _instance;
  PersonaMR._internal();
  
  final DatabaseService _dbService = DatabaseService();

  Candidate? currentCandidate;
  List<Decision> decisions = [];
  final List<ChapterMetric> _chapterMetrics = [];
  final Map<String, List<Map<String, dynamic>>> _interactionTimeline = {};
  final Map<String, Stopwatch> _chapterStopwatches = {};

  Future<void> initSession(String name, String position, String company) async {
    // 1. Önce bu isim ve şirkette bir aday var mı kontrol et
    final existing = await _dbService.findCandidateByNameAndCompany(name, company);
    
    if (existing != null) {
      currentCandidate = existing;
      print("PersonaMR: Mevcut adaya bağlanıldı: ${existing.name} ($company)");
    } else {
      // 2. Yoksa yeni aday oluştur
      currentCandidate = Candidate(
        id: "BC_${DateTime.now().millisecondsSinceEpoch}",
        name: name,
        position: position,
        company: company,
        scores: {},
        behavioralFlags: [],
        createdAt: DateTime.now(),
      );
      await _dbService.insertCandidate(currentCandidate!);
      print("PersonaMR: Yeni aday oluşturuldu: ${currentCandidate!.name} ($company)");
    }
    
    decisions.clear();
    _chapterMetrics.clear();
    _interactionTimeline.clear();
    _chapterStopwatches.clear();
  }

  void startChapterTimer(String chapterId) {
    _chapterStopwatches[chapterId] = Stopwatch()..start();
    _interactionTimeline[chapterId] = [];
    print("PersonaMR: Timer started for $chapterId");
  }

  void recordInteraction(String chapterId, String action, {Map<String, dynamic>? metadata}) {
    if (!_interactionTimeline.containsKey(chapterId)) return;
    
    final elapsed = _chapterStopwatches[chapterId]?.elapsedMilliseconds ?? 0;
    _interactionTimeline[chapterId]!.add({
      't': elapsed,
      'a': action,
      if (metadata != null) ...metadata,
    });
    print("PersonaMR Trace: [$chapterId] @${elapsed}ms -> $action");
  }

  Future<void> finalizeCandidateSession() async {
    if (currentCandidate == null) return;
    
    final engine = AssessmentEngine();
    final finalScores = engine.calculateScores(decisions, _chapterMetrics);
    final finalFlags = engine.generateFlags(decisions, _chapterMetrics);

    await _dbService.updateCandidateScores(currentCandidate!.id, finalScores, finalFlags);
    
    print("PersonaMR: Session finalized for ${currentCandidate!.name}");
  }
 

  String? _chosenPartner;
  void setPartner(String name) => _chosenPartner = name;
  String? getPartner() => _chosenPartner;

  Future<void> logChapterMetrics({
    required String chapterId,
    required int totalTimeMs,
    Map<String, dynamic>? additionalData,
  }) async {
    if (currentCandidate == null) return;

    final metric = ChapterMetric(
      id: "M_${DateTime.now().millisecondsSinceEpoch}_$chapterId",
      candidateId: currentCandidate!.id,
      chapterId: chapterId,
      totalTimeMs: totalTimeMs,
      additionalData: {
        ...?additionalData,
        'timeline': _interactionTimeline[chapterId] ?? [],
      },
      timestamp: DateTime.now(),
    );

    _chapterMetrics.add(metric);
    await _dbService.insertChapterMetric(metric);
    
    // Clear chapter-specific ephemeral data
    _interactionTimeline.remove(chapterId);
    _chapterStopwatches[chapterId]?.stop();
    _chapterStopwatches.remove(chapterId);
    
    print("PersonaMR DB Metric: $chapterId -> ${totalTimeMs}ms kaydedildi. ${(_interactionTimeline[chapterId]?.length ?? 0)} aksiyon loglandı.");
  }

  Future<void> logDecision({
    required String moduleId,
    required String chapterId,
    required String choiceId,
    required int durationMs,
    List<String> triggers = const [],
  }) async {
    if (currentCandidate == null) return;

    final decision = Decision(
      id: "D_${DateTime.now().millisecondsSinceEpoch}_$chapterId",
      candidateId: currentCandidate!.id,
      moduleId: moduleId,
      chapterId: chapterId,
      choiceId: choiceId,
      durationMs: durationMs,
      triggers: triggers,
      timestamp: DateTime.now(),
    );
    
    decisions.add(decision);
    await _dbService.insertDecision(decision);
    print("PersonaMR DB Decision: ${decision.chapterId} -> ${decision.choiceId} kaydedildi.");
  }
  
  // Getters for Assessment Engine
  List<ChapterMetric> get chapterMetrics => _chapterMetrics;
}
