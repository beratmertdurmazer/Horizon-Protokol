import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:horizon_protocol/models/game_models.dart';
import 'package:web/web.dart' as web;
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  final _random = Random();

  Database? _db;
  final supabase = Supabase.instance.client;

  // Web Fallback Storage
  static List<Candidate> _webCandidates = [];
  static List<Decision> _webDecisions = [];
  static List<ChapterMetric> _webMetrics = [];

  DatabaseService._internal() {
    if (kIsWeb) {
      _loadFromWebStorage();
    }
  }

  void _saveToWebStorage() {
    try {
      final candidatesJson = jsonEncode(_webCandidates.map((c) => {
        'id': c.id,
        'name': c.name,
        'position': c.position,
        'scores': c.scores,
        'behavioralFlags': c.behavioralFlags,
        'createdAt': c.createdAt.toIso8601String(),
      }).toList());
      web.window.localStorage.setItem('horizon_candidates', candidatesJson);

      final decisionsJson = jsonEncode(_webDecisions.map((d) => d.toMap()..['triggers'] = jsonEncode(d.triggers)).toList());
      web.window.localStorage.setItem('horizon_decisions', decisionsJson);

      final metricsJson = jsonEncode(_webMetrics.map((m) => m.toMap()..['additionalData'] = jsonEncode(m.additionalData)).toList());
      web.window.localStorage.setItem('horizon_metrics', metricsJson);
    } catch (e) {
      debugPrint("WebStorage Error: $e");
    }
  }

  void _loadFromWebStorage() {
    try {
      final data = web.window.localStorage.getItem('horizon_candidates');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        _webCandidates = list.map((m) => Candidate(
          id: m['id'],
          name: m['name'],
          position: m['position'],
          scores: Map<String, double>.from(m['scores']),
          behavioralFlags: List<String>.from(m['behavioralFlags']),
          createdAt: DateTime.parse(m['createdAt']),
        )).toList();
      }

      final decisionsData = web.window.localStorage.getItem('horizon_decisions');
      if (decisionsData != null) {
        final List<dynamic> list = jsonDecode(decisionsData);
        _webDecisions = list.map((m) => Decision(
          id: m['id'],
          candidateId: m['candidateId'],
          moduleId: m['moduleId'],
          chapterId: m['chapterId'],
          choiceId: m['choiceId'],
          durationMs: m['durationMs'],
          triggers: List<String>.from(jsonDecode(m['triggers'])),
          timestamp: DateTime.parse(m['timestamp']),
        )).toList();
      }

      final metricsData = web.window.localStorage.getItem('horizon_metrics');
      if (metricsData != null) {
        final List<dynamic> list = jsonDecode(metricsData);
        _webMetrics = list.map((m) => ChapterMetric(
          id: m['id'],
          candidateId: m['candidateId'],
          chapterId: m['chapterId'],
          totalTimeMs: m['totalTimeMs'],
          additionalData: jsonDecode(m['additionalData']),
          timestamp: DateTime.parse(m['timestamp']),
        )).toList();
      }
    } catch (e) {
      debugPrint("WebStorage Load Error: $e");
    }
  }
  Future<Database?> get database async {
    if (kIsWeb) return null;
    _db ??= await _initDb();
    return _db;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'horizon_protocol.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE candidates(
            id TEXT PRIMARY KEY,
            name TEXT,
            position TEXT,
            scores TEXT,
            behavioralFlags TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE decisions(
            id TEXT PRIMARY KEY,
            candidateId TEXT,
            moduleId TEXT,
            chapterId TEXT,
            choiceId TEXT,
            durationMs INTEGER,
            triggers TEXT,
            timestamp TEXT,
            FOREIGN KEY(candidateId) REFERENCES candidates(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE chapter_metrics(
            id TEXT PRIMARY KEY,
            candidateId TEXT,
            chapterId TEXT,
            totalTimeMs INTEGER,
            additionalData TEXT,
            timestamp TEXT,
            FOREIGN KEY(candidateId) REFERENCES candidates(id)
          )
        ''');
      },
    );
  }

  // Candidate Operations
  Future<void> insertCandidate(Candidate candidate) async {
    if (kIsWeb) {
      _webCandidates.removeWhere((c) => c.id == candidate.id);
      _webCandidates.insert(0, candidate);
      _saveToWebStorage();
      
      // Supabase Sync
      await supabase.from('candidates').upsert({
        'id': candidate.id,
        'name': candidate.name,
        'position': candidate.position,
        'scores': candidate.scores,
        'behavioralFlags': candidate.behavioralFlags,
        'createdAt': candidate.createdAt.toIso8601String(),
      });
      return;
    }
    final db = await database;
    await db!.insert(
      'candidates',
      {
        ...candidate.toMap(),
        'scores': jsonEncode(candidate.scores),
        'behavioralFlags': jsonEncode(candidate.behavioralFlags),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCandidateScores(String id, Map<String, double> scores, List<String> flags) async {
    if (kIsWeb) {
      final index = _webCandidates.indexWhere((c) => c.id == id);
      if (index != -1) {
        final old = _webCandidates[index];
        _webCandidates[index] = Candidate(
          id: old.id,
          name: old.name,
          position: old.position,
          scores: scores,
          behavioralFlags: flags,
          createdAt: old.createdAt,
        );
      }
      _saveToWebStorage();

      // Supabase Sync
      await supabase.from('candidates').update({
        'scores': scores,
        'behavioralFlags': flags,
      }).eq('id', id);
      return;
    }
    final db = await database;
    await db!.update(
      'candidates',
      {
        'scores': jsonEncode(scores),
        'behavioralFlags': jsonEncode(flags),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCandidate(String id) async {
    if (kIsWeb) {
      _webCandidates.removeWhere((c) => c.id == id);
      _webDecisions.removeWhere((d) => d.candidateId == id);
      _webMetrics.removeWhere((m) => m.candidateId == id);
      _saveToWebStorage();

      // Supabase Sync
      await supabase.from('candidates').delete().eq('id', id);
      return;
    }
    final db = await database;
    await db!.delete('chapter_metrics', where: 'candidateId = ?', whereArgs: [id]);
    await db.delete('decisions', where: 'candidateId = ?', whereArgs: [id]);
    await db.delete('candidates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDatabase() async {
    if (kIsWeb) {
      _webCandidates.clear();
      _webDecisions.clear();
      _webMetrics.clear();
      _saveToWebStorage();
      return;
    }
    final db = await database;
    await db!.delete('chapter_metrics');
    await db.delete('decisions');
    await db.delete('candidates');
  }

  // Decision Operations
  Future<void> insertDecision(Decision decision) async {
    if (kIsWeb) {
      _webDecisions.add(decision);
      _saveToWebStorage();

      // Supabase Sync
      await supabase.from('decisions').upsert({
        'id': decision.id,
        'candidateId': decision.candidateId,
        'moduleId': decision.moduleId,
        'chapterId': decision.chapterId,
        'choiceId': decision.choiceId,
        'durationMs': decision.durationMs,
        'triggers': decision.triggers,
        'timestamp': decision.timestamp.toIso8601String(),
      });
      return;
    }
    final db = await database;
    await db!.insert(
      'decisions',
      {
        ...decision.toMap(),
        'triggers': jsonEncode(decision.triggers),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Chapter Metric Operations
  Future<void> insertChapterMetric(ChapterMetric metric) async {
    if (kIsWeb) {
      _webMetrics.add(metric);
      _saveToWebStorage();

      // Supabase Sync
      await supabase.from('chapter_metrics').upsert({
        'id': metric.id,
        'candidateId': metric.candidateId,
        'chapterId': metric.chapterId,
        'totalTimeMs': metric.totalTimeMs,
        'additionalData': metric.additionalData,
        'timestamp': metric.timestamp.toIso8601String(),
      });
      return;
    }
    final db = await database;
    await db!.insert(
      'chapter_metrics',
      {
        ...metric.toMap(),
        'additionalData': jsonEncode(metric.additionalData),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Query Operations
  Future<List<Decision>> getDecisionsForCandidate(String candidateId) async {
    if (kIsWeb) {
      try {
        final response = await supabase.from('decisions').select().eq('candidateId', candidateId);
        final cloudDecisions = (response as List).map((m) => Decision(
          id: m['id'],
          candidateId: m['candidateId'],
          moduleId: m['moduleId'],
          chapterId: m['chapterId'],
          choiceId: m['choiceId'],
          durationMs: m['durationMs'],
          triggers: List<String>.from(m['triggers']),
          timestamp: DateTime.parse(m['timestamp']),
        )).toList();
        
        if (cloudDecisions.isNotEmpty) return cloudDecisions;
      } catch (e) {
        debugPrint("Supabase Fetch Error (Decisions): $e");
      }
      return _webDecisions.where((d) => d.candidateId == candidateId).toList();
    }
    final db = await database;
    final maps = await db!.query(
      'decisions',
      where: 'candidateId = ?',
      whereArgs: [candidateId],
    );
    return List.generate(maps.length, (i) {
      return Decision(
        id: maps[i]['id'] as String,
        candidateId: maps[i]['candidateId'] as String,
        moduleId: maps[i]['moduleId'] as String,
        chapterId: maps[i]['chapterId'] as String,
        choiceId: maps[i]['choiceId'] as String,
        durationMs: maps[i]['durationMs'] as int,
        triggers: List<String>.from(jsonDecode(maps[i]['triggers'] as String)),
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
      );
    });
  }

  Future<List<ChapterMetric>> getMetricsForCandidate(String candidateId) async {
    if (kIsWeb) {
      try {
        final response = await supabase.from('chapter_metrics').select().eq('candidateId', candidateId);
        final cloudMetrics = (response as List).map((m) => ChapterMetric(
          id: m['id'],
          candidateId: m['candidateId'],
          chapterId: m['chapterId'],
          totalTimeMs: m['totalTimeMs'],
          additionalData: m['additionalData'],
          timestamp: DateTime.parse(m['timestamp']),
        )).toList();
        if (cloudMetrics.isNotEmpty) return cloudMetrics;
      } catch (e) {
        debugPrint("Supabase Fetch Error (Metrics): $e");
      }
      return _webMetrics.where((m) => m.candidateId == candidateId).toList();
    }
    final db = await database;
    final maps = await db!.query(
      'chapter_metrics',
      where: 'candidateId = ?',
      whereArgs: [candidateId],
    );
    return List.generate(maps.length, (i) {
      return ChapterMetric(
        id: maps[i]['id'] as String,
        candidateId: maps[i]['candidateId'] as String,
        chapterId: maps[i]['chapterId'] as String,
        totalTimeMs: maps[i]['totalTimeMs'] as int,
        additionalData: jsonDecode(maps[i]['additionalData'] as String),
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
      );
    });
  }

  Future<List<Candidate>> getAllCandidates() async {
    if (kIsWeb) {
      try {
        final response = await supabase.from('candidates').select().order('createdAt', ascending: false);
        final cloudCandidates = (response as List).map((m) => Candidate(
          id: m['id'],
          name: m['name'],
          position: m['position'],
          scores: Map<String, double>.from(m['scores']),
          behavioralFlags: List<String>.from(m['behavioralFlags']),
          createdAt: DateTime.parse(m['createdAt']),
        )).toList();
        
        if (cloudCandidates.isNotEmpty) return cloudCandidates;
      } catch (e) {
        debugPrint("Supabase Fetch Error: $e");
      }
      return _webCandidates;
    }
    final db = await database;
    final maps = await db!.query('candidates', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) {
      return Candidate(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        position: maps[i]['position'] as String,
        scores: Map<String, double>.from(jsonDecode(maps[i]['scores'] as String)),
        behavioralFlags: List<String>.from(jsonDecode(maps[i]['behavioralFlags'] as String)),
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
      );
    });
  }

  Future<void> seedMockData() async {
    // 1. İŞBİRLİKÇİ PROFİL (ELARA'S ALLY)
    final mock1 = Candidate(
      id: "DEMO-001",
      name: "Örnek Aday (İşbirlikçi)",
      position: "Senior Project Manager",
      scores: {}, 
      behavioralFlags: [],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await insertCandidate(mock1);
    await _seedCandidateData(mock1, isCollaborative: true);

    // 2. OTORİTER / RİSKLİ PROFİL (THE ENFORCER)
    final mock2 = Candidate(
      id: "DEMO-002",
      name: "Aday 002 (Otoriter)",
      position: "Operations lead",
      scores: {},
      behavioralFlags: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    );
    await insertCandidate(mock2);
    await _seedCandidateData(mock2, isCollaborative: false);

    _saveToWebStorage();
  }

  Future<void> _seedCandidateData(Candidate candidate, {required bool isCollaborative}) async {
    final chapters = [
      "Bölüm 1: Bağlantı", "Bölüm 2: Triage", "Bölüm 3: Parazitler", 
      "Bölüm 4: Kritik Seçim", "Bölüm 5: Erişim", "Bölüm 6: Alarm", 
      "Bölüm 7: Sistemsel Çöküş", "Bölüm 8: Dış Gövde Çatlağı",
      "Bölüm 9: Enkazın Ardından", "Bölüm 10: Buzdan Çıkan Yüz",
      "Bölüm 11: İlk Tartışma",
      "Bölüm 12: Partnerin Hatası",
      "Bölüm 13: Güven Testi"
    ];

    for (int i = 0; i < chapters.length; i++) {
      final chId = chapters[i];
      List<Map<String, dynamic>> timeline = [];
      String choiceId = "";
      int durationMs = 3000;
      List<String> triggers = [];
      Map<String, dynamic>? additionalData;

      switch (i + 1) {
        case 1: // Bağlantı
          choiceId = isCollaborative ? "start_analysis" : "skip_analysis";
          durationMs = isCollaborative ? (8000 + _random.nextInt(5000)) : (25000 + _random.nextInt(15000));
          timeline = [
            {"t": 1000, "a": "STARTED"}, 
            {"t": durationMs, "a": "CORRECT_ANSWER", "trials": isCollaborative ? 1 : 3}
          ];
          additionalData = {
            'errorCount': isCollaborative ? _random.nextInt(2) : (3 + _random.nextInt(5)),
            'timeToFirstClick': isCollaborative ? (800 + _random.nextInt(1000)) : (15000 + _random.nextInt(15000)),
          };
          break;
        case 2: // Triage
          choiceId = isCollaborative ? "quarters" : "reactor";
          durationMs = 25000 + _random.nextInt(10000);
          final switches = isCollaborative ? (4 + _random.nextInt(4)) : (10 + _random.nextInt(10));
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 5000, "a": "FOCUS_ORDER", "system": "reactor"},
            {"t": 8000, "a": "FOCUS_ORDER", "system": "oxygen"},
            {"t": 12000, "a": "CHOICE_MADE", "choice": choiceId},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'switch_count': switches,
            'focus_order': ["reactor", "oxygen", "comms"],
            'final_levels': {'reactor': 45, 'oxygen': 65, 'comms': 80},
          };
          break;
        case 3: // Parazitler
          choiceId = "continue";
          durationMs = 35000 + _random.nextInt(10000);
          final flips = isCollaborative ? (6 + _random.nextInt(4)) : (15 + _random.nextInt(10));
          final memoryErrors = isCollaborative ? _random.nextInt(1) : (2 + _random.nextInt(4));
          final recoveryTime = isCollaborative ? (700 + _random.nextInt(500)) : (2000 + _random.nextInt(2000));
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 3000, "a": "POPUP_SPAWNED"},
            {"t": 4500, "a": "TILE_FLIPPED", "id": 1},
            {"t": 6000, "a": "TILE_FLIPPED", "id": 5},
            {"t": 8000, "a": "SUCCESS_MATCH"},
            {"t": 11000, "a": "POPUP_CLOSED", "reactionTime": recoveryTime},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'missedPopups': isCollaborative ? 0 : 2,
            'symbolMatchErrors': isCollaborative ? 1 : 5,
            'actualMemoryErrors': memoryErrors,
            'avgRecoveryTimeMs': recoveryTime,
            'tile_flips': flips,
          };
          break;
        case 4: // Karanlık Koridorlar
          final areas = [EnergyArea.labs, EnergyArea.quarters, EnergyArea.greenhouse];
          EnergyArea area = isCollaborative ? EnergyArea.greenhouse : EnergyArea.labs;
          choiceId = area.name;
          durationMs = 15000 + _random.nextInt(10000);
          
          final revokes = isCollaborative ? 0 : (_random.nextDouble() > 0.5 ? 2 : 0);
          final switches = isCollaborative ? 1 : (3 + _random.nextInt(3));

          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 3000, "a": "AREA_SELECTED", "area": "labs"},
            if (switches > 1) {"t": 6000, "a": "AREA_SELECTED", "area": area.name},
            if (revokes > 0) {"t": 10000, "a": "CONFIRMATION_REVOKED"},
            {"t": 14000, "a": "FINAL_SACRIFICE_CONFIRMED", "area": area.name},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'selectedArea': area.name,
            'revokedConfirmations': revokes,
            'navigationSwitches': switches,
            'viewDurations': {
              'labs': 4000,
              'quarters': 2000,
              'greenhouse': 2000,
            },
            'totalDurationMs': durationMs,
          };
          break;
        case 5: // Reaktör Krizi
          final isSuccess = isCollaborative;
          final isBypass = !isCollaborative && _random.nextDouble() > 0.3; // %70 ihtimalle Bypass, %30 Timeout veya Failed
          final String result = isSuccess ? "Success" : (isBypass ? "Bypass" : "Timeout");
          
          final readingTime = isSuccess ? (15000 + _random.nextInt(10000)) : (isBypass ? (5000 + _random.nextInt(15000)) : 45000);
          final failedAttempts = isSuccess ? 0 : (_random.nextInt(4));
          final usedDecoy = !isCollaborative && _random.nextBool() && failedAttempts > 0;

          choiceId = result;
          durationMs = readingTime;
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            if (usedDecoy) {"t": readingTime ~/ 2, "a": "PIN_ERROR", "input": "PROXIMA-7"},
            {"t": durationMs, "a": isSuccess ? "PIN_SUCCESS" : (isBypass ? "BYPASS_CLICKED" : "TIMEOUT")}
          ];
          
          additionalData = {
            'failedAttempts': failedAttempts,
            'readingTimeMs': readingTime,
            'usedDecoy': usedDecoy,
            'result': result,
          };
          break;
        case 6: // Alarm Yorgunluğu
          final isSuccess = isCollaborative;
          final result = isSuccess ? "vigilance" : "isolate";
          final panicClicks = isSuccess ? 0 : (2 + _random.nextInt(5));
          final decisionTimeMs = isSuccess ? (6000 + _random.nextInt(8000)) : (2000 + _random.nextInt(2000));
          
          choiceId = result;
          durationMs = 8000 + decisionTimeMs;
          
          timeline = [
            {"t": 1000, "a": "CHAOS_STARTED"},
            {"t": 8000, "a": "DECISION_MODAL_SHOWN"},
            if (panicClicks > 0) {"t": 4000, "a": "PANIC_CLICK", "count": panicClicks},
            {"t": durationMs, "a": isSuccess ? "DECISION_VIGILANCE" : "DECISION_ISOLATE"}
          ];
          
          additionalData = {
            'decisionTimeMs': decisionTimeMs,
            'panicClicks': panicClicks,
            'finalDecision': result,
          };
          break;
        case 7: // Sistemsel Çöküş
          final bool isDeepAnalytical = isCollaborative && _random.nextBool();
          final bool isLucky = isCollaborative && !isDeepAnalytical;
          final bool isFreeze = !isCollaborative && _random.nextBool();
          
          final int decisionTimeMs;
          final String finalResult;
          final int errorCount;

          if (isDeepAnalytical) {
            finalResult = "BINARY_SOLVED";
            decisionTimeMs = 12000 + _random.nextInt(15000); // 12-27 sn
            errorCount = 0;
          } else if (isLucky) {
            finalResult = "BINARY_SOLVED";
            decisionTimeMs = 3000 + _random.nextInt(4000); // 3-7 sn
            errorCount = 0;
          } else if (isFreeze) {
            finalResult = "TIMEOUT_SURFACE_THINKER";
            decisionTimeMs = 180000;
            errorCount = 0;
          } else {
            finalResult = "FAIL_IMPULSIVE_RANDOM";
            decisionTimeMs = 2000 + _random.nextInt(5000); // 2-7 sn
            errorCount = 1;
          }

          choiceId = finalResult;
          durationMs = decisionTimeMs;
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            if (errorCount > 0) {"t": 2000, "a": "RED_BUTTON_PRESSED"},
            {"t": decisionTimeMs, "a": finalResult}
          ];
          
          additionalData = {
            'decisionTimeMs': decisionTimeMs,
            'finalResult': finalResult,
            'errorCount': errorCount,
          };
          break;
        case 8: // Dış Gövde Çatlağı
          final bool isO2Mask = isCollaborative; // Yaşamak isteyenler oksijen takar
          final bool isTimeout = !isCollaborative && _random.nextDouble() > 0.8; 
          
          final String finalResult;
          if (isTimeout) {
            finalResult = "TIMEOUT";
          } else if (isO2Mask) {
            finalResult = "OXYGEN_MASK";
          } else {
            finalResult = "BREACH_AREA";
          }

          int reactionTimeMs;
          if (finalResult == "TIMEOUT") {
            reactionTimeMs = 35000;
          } else if (finalResult == "OXYGEN_MASK") {
            reactionTimeMs = _random.nextBool() ? (5000 + _random.nextInt(10000)) : (22000 + _random.nextInt(5000));
          } else {
            // Breach area is impulsive, very fast
            reactionTimeMs = 1500 + _random.nextInt(3000);
          }

          choiceId = finalResult;
          durationMs = reactionTimeMs;
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": reactionTimeMs, "a": "DECISION_MADE", "choice": finalResult}
          ];
          
          additionalData = {
            'reactionTimeMs': reactionTimeMs,
            'finalResult': finalResult,
          };
          break;
        case 9: // Enkazın Ardından
          final bool isConstructive = isCollaborative; 
          
          List<String> validChoices;
          if (isConstructive) {
            validChoices = ["INTERNAL_SYSTEMIC", "INTERNAL_ADAPTIVE", "INTERNAL_RUMINATIVE", "INTERNAL_TACTICAL"];
          } else {
            validChoices = ["EXTERNAL_RATIONAL", "EXTERNAL_FATALISTIC", "EXTERNAL_AGGRESSIVE", "EXTERNAL_DENIAL"];
          }
          final String selectedCategory = validChoices[_random.nextInt(validChoices.length)];
          final int responseDelay = isConstructive ? (10000 + _random.nextInt(15000)) : (2000 + _random.nextInt(6000));
          
          choiceId = selectedCategory;
          durationMs = responseDelay;
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": responseDelay, "a": "REFLECTION_MADE", "choice": selectedCategory}
          ];

          additionalData = {
            'responseDelay': responseDelay,
            'finalResult': selectedCategory,
            'selectedText': "Demo kelime (" + selectedCategory + ")",
          };
          break;
        case 10: // Partner Seçimi
          choiceId = isCollaborative ? "ELARA" : "KAEL";
          durationMs = isCollaborative ? (18000 + _random.nextInt(10000)) : (4000 + _random.nextInt(4000));
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": durationMs, "a": "CHARACTER_SELECTED", "name": choiceId}
          ];
          additionalData = {
            'choiceId': choiceId,
            'totalTimeMs': durationMs,
          };
          break;
        case 11: // İlk Tartışma
          final bool isPassive = !isCollaborative && _random.nextDouble() > 0.7;
          
          if (isPassive) {
            choiceId = "TIMEOUT";
            durationMs = 45000 + _random.nextInt(10000);
          } else {
            final styles = ["COLLABORATIVE", "RATIONAL", "AUTHORITY", "MANIPULATIVE"];
            choiceId = isCollaborative ? "COLLABORATIVE" : styles[_random.nextInt(styles.length - 1) + 1];
            durationMs = 5000 + _random.nextInt(20000);
          }
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": durationMs, "a": "CONFLICT_RESOLVED", "choice": choiceId}
          ];
          additionalData = {
            'choiceId': choiceId,
            'decisionDelay': durationMs,
          };
          break;
        case 12: // Partnerin Hatası
          final styles = ["CONSTRUCTIVE", "PROCEDURAL", "PUNITIVE"];
          choiceId = isCollaborative ? "CONSTRUCTIVE" : styles[_random.nextInt(styles.length - 1) + 1];
          durationMs = 5000 + _random.nextInt(15000);
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": durationMs, "a": "MISTAKE_HANDLED", "choice": choiceId}
          ];
          additionalData = {
            'choiceId': choiceId,
            'forgiveDelay': durationMs,
          };
          break;
        case 13: // Güven Testi (M-M / Delegation)
          if (isCollaborative) {
            choiceId = "DELEGATE";
          } else {
            choiceId = _random.nextBool() ? "SELF" : "DISTRUST";
          }
          durationMs = 12000 + _random.nextInt(8000);
          
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": durationMs - 5000, "a": "DECISION_MODAL_SHOWN"},
            {"t": durationMs, "a": "FINAL_DECISION", "choiceId": choiceId}
          ];
          additionalData = {
            'choiceId': choiceId,
            'delegationRatio': choiceId == "DELEGATE" ? 1.0 : 0.0,
            'readDuration': durationMs - 5000,
          };
          break;
    }

      await insertChapterMetric(ChapterMetric(
        id: "M_${candidate.id}_$i",
        candidateId: candidate.id,
        chapterId: chId,
        totalTimeMs: durationMs + 2000,
        additionalData: {
          if (timeline.isNotEmpty) 'timeline': timeline,
          if (additionalData != null) ...additionalData!,
        },
        timestamp: DateTime.now().subtract(Duration(minutes: 60 - i)),
      ));

      await insertDecision(Decision(
        id: "D_${candidate.id}_$i",
        candidateId: candidate.id,
        moduleId: "MOD_DEMO",
        chapterId: chId,
        choiceId: choiceId,
        durationMs: durationMs,
        triggers: triggers,
        timestamp: DateTime.now().subtract(Duration(minutes: 60 - i)),
      ));
    }
  }
}
