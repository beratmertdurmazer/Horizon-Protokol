import 'package:horizon_protocol/models/game_models.dart';

class AssessmentEngine {
  // --- YENİ NESİL ANALİZ MOTORU V3 (TAMAMEN SIFIRDAN) ---
  // Bu motor, bölümler tek tek incelenerek en baştan inşa edilecektir.
  // Mevcut hiçbir matematiksel örüntü veya varsayılan analiz kullanılmamaktadır.

  Map<String, double> calculateScores(List<Decision> decisions, List<ChapterMetric> metrics) {
    return <String, double>{};
  }

  List<String> generateFlags(List<Decision> decisions, List<ChapterMetric> metrics) {
    List<String> allFindings = [];
    
    // Bölüm 1 Analizi
    try {
      final ch1Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 1"));
      allFindings.addAll(_analyzeChapter1(ch1Metric));
    } catch (_) {}

    // Bölüm 2 Analizi (Triage)
    try {
      final ch2Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 2"));
      allFindings.addAll(_analyzeChapter2(ch2Metric));
    } catch (_) {}

    // Bölüm 3 Analizi (Parazitler)
    try {
      final ch3Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 3"));
      allFindings.addAll(_analyzeChapter3(ch3Metric));
    } catch (_) {}

    // Bölüm 4 Analizi (Karanlık Koridorlar)
    try {
      final ch4Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 4"));
      allFindings.addAll(_analyzeChapter4(ch4Metric));
    } catch (_) {}

    // Bölüm 5 Analizi (Reaktör Krizi)
    try {
      final ch5Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 5"));
      allFindings.addAll(_analyzeChapter5(ch5Metric));
    } catch (_) {}

    // Bölüm 6 Analizi (Alarm Yorgunluğu)
    try {
      final ch6Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 6"));
      allFindings.addAll(_analyzeChapter6(ch6Metric));
    } catch (_) {}

    // Bölüm 7 Analizi (Sistemsel Çöküş)
    try {
      final ch7Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 7"));
      allFindings.addAll(_analyzeChapter7(ch7Metric));
    } catch (_) {}

    // Bölüm 8 Analizi (Dış Gövde Çatlağı)
    try {
      final ch8Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 8"));
      allFindings.addAll(_analyzeChapter8(ch8Metric));
    } catch (_) {}

    // Bölüm 9 Analizi (Enkazın Ardından)
    try {
      final ch9Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 9"));
      allFindings.addAll(_analyzeChapter9(ch9Metric));
    } catch (_) {}

    // Bölüm 10 Analizi (Buzdan Çıkan Yüz)
    try {
      final ch10Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 10"));
      allFindings.addAll(_analyzeChapter10(ch10Metric));
    } catch (_) {}

    // Bölüm 11 Analizi (İlk Tartışma)
    try {
      final ch11Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 11"));
      allFindings.addAll(_analyzeChapter11(ch11Metric));
    } catch (_) {}

    // Bölüm 12 Analizi (Partnerin Hatası)
    try {
      final ch12Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 12"));
      allFindings.addAll(_analyzeChapter12(ch12Metric));
    } catch (_) {}

    // Bölüm 13 Analizi (Güven Testi)
    try {
      final ch13Metric = metrics.firstWhere((m) => m.chapterId.contains("Bölüm 13"));
      allFindings.addAll(_analyzeChapter13(ch13Metric));
    } catch (_) {}

    return allFindings;
  }

  List<String> _analyzeChapter1(ChapterMetric metric) {
    List<String> findings = [];
    final timeline = metric.additionalData?['timeline'] as List<dynamic>? ?? [];
    if (timeline.isEmpty) return findings;

    final firstAction = timeline.cast<Map<String, dynamic>?>().firstWhere((a) => a?['a'] == 'WRONG_ANSWER' || a?['a'] == 'CORRECT_ANSWER', orElse: () => null);
    if (firstAction != null && (firstAction['t'] as int) < 3000) findings.add("Dürtüsel Aksiyon");

    final correctActionIndex = timeline.indexWhere((a) => a['a'] == 'CORRECT_ANSWER');
    final bool isSuccess = correctActionIndex != -1;
    final wrongActions = timeline.where((a) => a['a'] == 'WRONG_ANSWER').toList();

    if (isSuccess) {
      final correctAction = timeline[correctActionIndex];
      final num finishTimeNum = correctAction['t'] as num? ?? 0;
      final int finishTime = finishTimeNum.toInt();
      final int trials = correctAction['trials'] as int? ?? 1;

      if (finishTime < 30000) findings.add("Analitik Çeviklik");
      else findings.add("Sistematik Çözümleme");

      bool has98Error = wrongActions.any((a) => a['input']?.toString().toUpperCase().contains("98") ?? false);
      if (trials == 2) findings.add("Adaptif Öğrenme");
      else if (trials >= 3 && !has98Error) findings.add("Rastgele Başarı");
      if (has98Error && trials >= 2 && !findings.contains("Rastgele Başarı")) findings.add("Örüntü Tanıma");
    } else {
      findings.add("Bilişsel Blokaj");
    }
    return findings;
  }

  List<String> _analyzeChapter2(ChapterMetric metric) {
    List<String> findings = [];
    final data = metric.additionalData ?? {};
    final levels = data['final_levels'] as Map<String, dynamic>? ?? {};
    final int reactor = levels['reactor'] ?? 0;
    final int oxygen = levels['oxygen'] ?? 0;
    final int comms = levels['comms'] ?? 0;
    final int switches = data['switch_count'] ?? 0;
    
    // 1. Denge Analizi (Stratejik Orkestrasyon > %50)
    final avg = (reactor + oxygen + comms) / 3;
    final double diff = ( (reactor-avg).abs() + (oxygen-avg).abs() + (comms-avg).abs() ) / 3;
    final bool isBalanced = diff < 15 && reactor > 50 && oxygen > 50 && comms > 50;

    if (isBalanced) {
      findings.add("Stratejik Orkestrasyon");
    }

    // 2. Önceliklendirme Analizi (> %80)
    if (reactor >= 80 && reactor > oxygen && reactor > comms) {
      findings.add("Operasyonel Sürdürülebilirlik");
    }
    if (oxygen >= 80 && oxygen > reactor && oxygen > comms) {
      findings.add("İnsan Sermayesi ve Esenlik");
    }
    if (comms >= 80 && comms > reactor && comms > oxygen) {
      findings.add("Paydaş Yönetimi ve İletişim");
    }

    // 3. Negatif/Riskli Bulgular
    if (switches > 8) {
      findings.add("Reaktif Kriz Tepkisi");
    }
    
    bool hasTunnel = (reactor > 80 && oxygen < 20) || (reactor > 80 && comms < 20) || 
                     (oxygen > 80 && reactor < 20) || (oxygen > 80 && comms < 20) ||
                     (comms > 80 && reactor < 20) || (comms > 80 && oxygen < 20);
    if (hasTunnel) {
      findings.add("Tünel Vizyonu");
    }

    if (avg < 50) {
      findings.add("Karar Paralizi");
    }

    return findings;
  }

  List<String> _analyzeChapter3(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    final totalTime = m.totalTimeMs / 1000.0;
    
    final int actualMemoryErrors = data['actualMemoryErrors'] as int? ?? 0;
    final int missedPopups = data['missedPopups'] as int? ?? 0;
    final int immediateDismissals = data['immediateDismissals'] as int? ?? 0;
    final int recoveryTime = data['avgRecoveryTimeMs'] as int? ?? 0;
    final int exploration8 = data['seenIndicesCount_8'] as int? ?? 0;
    final int readingParalysis = data['readingParalysisCount'] as int? ?? 0;

    // KATEGORİ A: Zaman ve İşlem Kapasitesi
    if (totalTime < 45) {
      flags.add("Hiper-Odak");
    } else if (totalTime >= 45 && totalTime <= 75) {
      flags.add("Dengeli Analizci");
    } else if (totalTime > 75 && totalTime <= 100) {
      flags.add("Bilişsel Efor");
    } else if (totalTime > 100) {
      flags.add("İşlem Ataleti");
    }

    // KATEGORİ B: Davranışsal ve Stratejik Teknik
    if (exploration8 > 6) {
      flags.add("Metodik Haritalama");
    }
    if (missedPopups < 2) {
      flags.add("Bilişsel Filtreleme");
    }
    if (recoveryTime < 1200 && recoveryTime > 0) {
      flags.add("Bilişsel Toparlanma Hızı");
    }
    if (immediateDismissals > 5) {
      flags.add("Dürtüsel Refleks");
    }
    if (readingParalysis > 3 || recoveryTime >= 2500) {
      flags.add("Odak Erozyonu");
    }

    // KATEGORİ C: Doğruluk ve Riskler
    if (actualMemoryErrors <= 2) {
      flags.add("Hafıza Hassasiyeti");
    }
    if (actualMemoryErrors > 6 && missedPopups > 4) {
      flags.add("Multitasking Kaygısı");
    }

    return flags;
  }

  List<String> _analyzeChapter4(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    final totalTime = m.totalTimeMs / 1000.0;
    
    final String selectedArea = data['selectedArea']?.toString().toLowerCase() ?? "";
    final int revokedConfirmations = data['revokedConfirmations'] as int? ?? 0;

    // KATEGORİ A: Değerler Hiyerarşisi (Hangi Alan Korundu?)
    // Not: selectedArea feda edilen (kapatılan) alandır. Korunan alanlar diğer ikisidir.
    if (selectedArea == "greenhouse" || selectedArea == "quarters") {
      if (selectedArea != "labs") flags.add("Ar-Ge Koruyucusu");
    } 
    if (selectedArea == "labs" || selectedArea == "greenhouse") {
      if (selectedArea != "quarters") flags.add("Çalışan Hakları Savunucusu");
    }
    if (selectedArea == "labs" || selectedArea == "quarters") {
      if (selectedArea != "greenhouse") flags.add("ESG / Vizyon Bilinci");
    }
    
    // Basitleştirilmiş mantık: selectedArea dışındakiler korundu kabul edilir ama biz her seçim için tek baskın bulgu verelim.
    // Kullanıcının "korunan alan" vurgusuna sadık kalarak feda edilmeyeni buluyoruz.
    flags.clear(); // Yukardakileri temizleyip daha net set yapalım
    if (selectedArea == "greenhouse" || selectedArea == "quarters") flags.add("Ar-Ge Koruyucusu");
    else if (selectedArea == "labs") flags.add("Çalışan Hakları Savunucusu");
    
    // Daha tutarlı hiyerarşi (Feda edilmeyene göre):
    flags.clear();
    if (selectedArea == "quarters") flags.add("Ar-Ge Koruyucusu");
    if (selectedArea == "labs") flags.add("Çalışan Hakları Savunucusu");
    if (selectedArea == "greenhouse") flags.add("Stratejik Önceliklendirme");

    // Kullanıcının tam istediği isimlendirme:
    flags.clear();
    if (selectedArea == "quarters") flags.add("Ar-Ge Koruyucusu"); 
    if (selectedArea == "labs") flags.add("Çalışan Hakları Savunucusu");
    if (selectedArea == "greenhouse") flags.add("ESG / Vizyon Bilinci"); 

    // KATEGORİ B: Klinik Derinlik (Davranışsal Analiz)
    if (revokedConfirmations == 0) {
      flags.add("Özgüvenli Karar");
    } else {
      flags.add("Bilişsel Çalkantı");
    }

    if (totalTime < 10) {
      flags.add("Yüzeysel Bakış");
    }

    return flags;
  }

  List<String> _analyzeChapter5(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    
    // Güvenli tip dönüşümü (eski vs yeni veri uyumluluğu için readingTime de kontrol edilir)
    final num readingTimeNum = data['readingTimeMs'] as num? ?? data['readingTime'] as num? ?? 0;
    final double readingTimeSec = readingTimeNum.toDouble() / 1000.0;
    final int failedAttempts = data['failedAttempts'] as int? ?? 0;
    final bool usedDecoy = data['usedDecoy'] == true || data['usedDecoy'] == "true";
    final String result = data['result']?.toString() ?? "Timeout";

    // KATEGORİ A: Risk Toleransı ve Stres Yönetimi (Bypass Kullanımı)
    if (result == "Bypass") {
      if (readingTimeSec < 10 && readingTimeSec > 0) {
        flags.add("Kognitif Kaçınma / Protokol İhlali");
      } else {
        flags.add("Stres Bağımlı Kural Esnetme");
      }
    } else if (result == "Success") {
      flags.add("Kognitif Dayanıklılık ve Süreç Sadakati");
    }

    // KATEGORİ B: Okuma-Anlama ve Doğruluk
    if (usedDecoy) {
      flags.add("Dürtüsel Yanılgı");
    } else if (result == "Success" && failedAttempts == 0) {
      flags.add("Metodik Veri Süzme");
    } else if (failedAttempts > 0 && !usedDecoy) {
      // 1 deneme de olsa, 3 deneme de olsa eğer başarısız olunmuşsa
      flags.add("Hevristik Deneme Döngüsü");
    }

    // KATEGORİ C: Eylemsizlik
    if (result == "Timeout" && failedAttempts == 0 && !usedDecoy) {
      flags.add("Akut Karar Paralizisi");
    }

    // Eğer hiç flag atanamadıysa bir fallback verelim
    if (flags.isEmpty) {
      if (result == "Timeout") flags.add("Akut Karar Paralizisi");
      else flags.add("Hevristik Deneme Döngüsü");
    }

    return flags;
  }

  List<String> _analyzeChapter6(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    
    final num decisionTimeMs = data['decisionTimeMs'] as num? ?? 0;
    final int panicClicks = data['panicClicks'] as int? ?? data['panic_clicks'] as int? ?? 0;
    final String finalDecision = data['finalDecision'] as String? ?? "vigilance";

    // KATEGORİ A: Bilişsel Hız ve Acelecilik
    if (decisionTimeMs < 5000) {
      flags.add("Erken Karar / Alarm Yorgunluğu Zafiyeti");
    } else {
      flags.add("Dengeli / Hesaplanmış Reaksiyon");
    }

    // KATEGORİ B: Kriz ve Panik Yönetimi
    if (panicClicks > 3) {
      flags.add("Akut Motor Panik");
    } else if (panicClicks == 0) {
      flags.add("Soğukkanlı Kriz Gözlemcisi");
    }

    // KATEGORİ C: Gözlem vs Konfor
    if (finalDecision == "isolate") {
      flags.add("Bilgi Algısı İptali / Körlük Kararı");
    } else {
      flags.add("Gerçeklik Metaneti / Şeffaflık");
    }

    return flags;
  }

  List<String> _analyzeChapter7(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    
    final num decisionTimeMs = data['decisionTimeMs'] as num? ?? 0;
    final String finalResult = data['finalResult'] as String? ?? "";

    if (finalResult == "BINARY_SOLVED") {
      if (decisionTimeMs >= 10000) {
        flags.add("Derin Analitik Odak");
      } else {
        flags.add("Şanslı Dürtüsellik");
      }
    } else if (finalResult == "FAIL_IMPULSIVE_RANDOM") {
      flags.add("Kör Aksiyon / Dürtüsel Panik");
    } else if (finalResult == "TIMEOUT_SURFACE_THINKER") {
      flags.add("Bilişsel Kilitlenme (Bölüm 7)"); // 'Akut Karar Paralizisi' ile karışmaması için spesifik
    }

    return flags;
  }

  List<String> _analyzeChapter8(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    
    final num reactionTime = data['reactionTimeMs'] as num? ?? 0;
    final String finalResult = data['finalResult'] as String? ?? "";

    if (finalResult == "OXYGEN_MASK") {
      if (reactionTime <= 20000) {
        flags.add("Hesaplanmış Akut Müdahale");
      } else {
        flags.add("Gecikmeli Güvenlik");
      }
    } else if (finalResult == "BREACH_AREA") {
      flags.add("Dürtüsel Kahramanlık / Şehitlik Eğilimi");
    } else if (finalResult == "TIMEOUT") {
      flags.add("Akut Şok Kilitlenmesi");
    }

    return flags;
  }

  List<String> _analyzeChapter9(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    
    final String finalResult = data['finalResult'] as String? ?? "";

    if (finalResult == "INTERNAL_SYSTEMIC") {
      flags.add("Sistemik Öz-Eleştiri");
    } else if (finalResult == "INTERNAL_ADAPTIVE") {
      flags.add("Adaptif Öğrenme Odağı");
    } else if (finalResult == "INTERNAL_RUMINATIVE") {
      flags.add("Aşırı Öz-Yıkım / Suçluluk Melankolisi");
    } else if (finalResult == "INTERNAL_TACTICAL") {
      flags.add("Yüzeysel & Taktiksel Pişmanlık");
    } else if (finalResult == "EXTERNAL_RATIONAL") {
      flags.add("Mazeretçi Rasyonalizasyon");
    } else if (finalResult == "EXTERNAL_FATALISTIC") {
      flags.add("Kaderci Öğrenilmiş Çaresizlik");
    } else if (finalResult == "EXTERNAL_AGGRESSIVE") {
      flags.add("Açık Kurban Psikolojisi");
    } else if (finalResult == "EXTERNAL_DENIAL") {
      flags.add("Sorumluluk Reddi (Narsistik Savunma)");
    }

    return flags;
  }

  List<String> _analyzeChapter10(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    final duration = (m.totalTimeMs != 0) ? m.totalTimeMs : (data['totalTimeMs'] as num? ?? 0).toDouble();
    final choice = data['choiceId'] as String? ?? "";

    if (choice == "ELARA") {
      flags.add("Sosyal Uyum Temelli Liderlik");
    } else if (choice == "KAEL") {
      flags.add("Teknik Yetkinlik Temelli Liderlik");
    }

    if (duration > 15000) {
      flags.add("Metodik Veri İnceleme");
    } else {
      flags.add("Sezgisel Seçim Refleksi");
    }

    return flags;
  }

  List<String> _analyzeChapter11(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    final choice = data['choiceId'] as String? ?? "TIMEOUT";
    final delay = (data['decisionDelay'] as num? ?? 0).toDouble();

    if (choice == "TIMEOUT" || delay >= 45000) {
      flags.add("Pasif-Agresif Karar Felci");
    } else if (choice == "COLLABORATIVE") {
      flags.add("Psikolojik Güvenlik Mimarı");
    } else if (choice == "RATIONAL") {
      flags.add("Duygusuz Rasyonalizasyon");
    } else if (choice == "AUTHORITY") {
      flags.add("Hiyerarşik Komuta ve Karar Keskinliği");
    } else if (choice == "MANIPULATIVE") {
      flags.add("Duygusal Manipülasyon ve Toksik Etki");
    }

    return flags;
  }

  List<String> _analyzeChapter12(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    final choice = data['choiceId'] as String? ?? "";

    if (choice == "CONSTRUCTIVE") {
      flags.add("Gelişimsel Liderlik (Hata Toleransı)");
    } else if (choice == "PROCEDURAL") {
      flags.add("Kuralcı ve Soğuk Adalet");
    } else if (choice == "PUNITIVE") {
      flags.add("Cezalandırıcı Otoriter Yaklaşım");
    }

    return flags;
  }

  List<String> _analyzeChapter13(ChapterMetric m) {
    List<String> flags = [];
    final data = m.additionalData ?? {};
    final choice = data['choiceId'] as String? ?? "";

    if (choice == "DELEGATE") {
      flags.add("Güven Odaklı Delegasyon");
    } else if (choice == "SELF") {
      flags.add("Koruyucu Mikro-Yönetim");
    } else if (choice == "DISTRUST") {
      flags.add("Suçlayıcı ve Toksik Güvensizlik");
    }

    return flags;
  }

  String getLeadershipArchetype(double leadershipScore, double strategicScore) {
    return "Analiz Yapılandırılıyor";
  }

  String getExecutiveSummary(Map<String, double> scores, List<String> flags) {
    if (flags.isEmpty) return "Henüz yeterli analiz verisi toplanmadı. Test süreci devam ediyor.";
    
    String summary = "Adayın klinik değerlendirme özeti: ";
    if (flags.contains("Stratejik Orkestrasyon")) summary += "Kriz anında yüksek orkestrasyon kabiliyeti sergiledi. ";
    if (flags.contains("Analitik Çeviklik")) summary += "Bilişsel adaptasyon hızı üst düzeyde. ";
    if (flags.contains("Adaptif Öğrenme")) summary += "Hatalarından anlık ders çıkarabilen bir yapısı var. ";
    if (flags.contains("Operasyonel Sürdürülebilirlik")) summary += "Kurumsal altyapı ve sürdürülebilirlik odaklı. ";
    if (flags.contains("İnsan Sermayesi ve Esenlik")) summary += "İnsan kaynağını ve ekip esenliğini önceliğe alıyor. ";
    if (flags.contains("Paydaş Yönetimi ve İletişim")) summary += "Stratejik koordinasyon ve paydaş iletişimi odaklı. ";
    if (flags.contains("Tünel Vizyonu")) summary += "Baskı altında odağı daralarak feda eylemlerinde bulunabilir. ";
    if (flags.contains("Bilişsel Blokaj") || flags.contains("Karar Paralizi")) summary += "Yoğun stres altında karar verme felci görüldü. ";
    
    // Bölüm 3 (Parazitler) Eklemeleri
    if (flags.contains("Hiper-Odak")) summary += "Çok yüksek işlem hızı ve odaklanma kapasitesine sahip. ";
    if (flags.contains("Metodik Haritalama")) summary += "Kaotik veri setlerini önce analiz edip sonra aksiyona geçiyor. ";
    if (flags.contains("Bilişsel Filtreleme")) summary += "Dış uyaranları (gürültü) süzme yetisi oldukça güçlü. ";
    if (flags.contains("Bilişsel Toparlanma Hızı")) summary += "Kesintilerin ardından işine çok hızlı geri dönebiliyor. ";
    if (flags.contains("Hafıza Hassasiyeti")) summary += "Baskı altında dahi veri ve bilgi güvenilirliği üst düzeyde. ";
    if (flags.contains("Dürtüsel Refleks")) summary += "Hızlı tepki verme güdüsü bazen kontrolsüzlüklere yol açabilir. ";
    if (flags.contains("Odak Erozyonu") || flags.contains("Multitasking Kaygısı")) summary += "Çoklu uyaran ve multitasking durumunda ciddi performans kaybı yaşıyor. ";
    
    // Bölüm 4 (Karanlık Koridorlar) Eklemeleri
    if (flags.contains("Ar-Ge Koruyucusu")) summary += "Gelecek vizyonunu ve inovasyonu bütçe kısıtlamalarına rağmen koruma eğiliminde. ";
    if (flags.contains("Çalışan Hakları Savunucusu")) summary += "Kriz anlarında insan sermayesini ve çalışan esenliğini birincil değer olarak görüyor. ";
    if (flags.contains("ESG / Vizyon Bilinci")) summary += "Kurumsal imajı ve sürdürülebilirliği kriz anında dahi öncelikli kale olarak tutuyor. ";
    if (flags.contains("Özgüvenli Karar")) summary += "Etik sorumluluk alırken sergilediği netlik ve kararlılık üst düzeyde. ";
    if (flags.contains("Bilişsel Çalkantı")) summary += "Zorlu kararlarda yüksek içsel çatışma ve tereddüt yaşıyor. ";
    if (flags.contains("Yüzeysel Bakış")) summary += "Detayları ve paydaş etkilerini tam analiz etmeden dürtüsel kararlar verebilir. ";

    // Bölüm 5 (Reaktör Krizi) Eklemeleri
    if (flags.contains("Kognitif Kaçınma / Protokol İhlali")) summary += "Zorlu görevlerden kaçarak fevri ve kuralsız sonuç alma güdüsüne sahip. ";
    if (flags.contains("Bilgi Boşluğu Doldurma (Hevristik)")) summary += "Bağlamı tam okumadan tahmin yürüterek karar veriyor. ";
    if (flags.contains("Metodik Veri Süzme") || flags.contains("Metodik Regülasyon")) summary += "Büyük veri yığınları arasından en doğru bilgiyi sabırla süzebiliyor. ";
    if (flags.contains("Dürtüsel Yanılgı")) summary += "Odak analiz yapmak yerine ilk dikkat çeken veriye refleksif olarak atlıyor. ";
    if (flags.contains("Hevristik Deneme Döngüsü")) summary += "Sistematik çalışmak yerine kaba kuvvet ve rastgele tahminlerle ilerlemeye yatkın. ";
    if (flags.contains("Akut Karar Paralizisi")) summary += "Kriz anında inisiyatif alamayarak donma tepkisi veriyor. ";

    // Bölüm 6 (Alarm Yorgunluğu) Eklemeleri
    if (flags.contains("Erken Karar / Alarm Yorgunluğu Zafiyeti")) summary += "Yoğun stres karşısında analiz yapmadan, durumdan anında kaçınma refleksi gösteriyor. ";
    if (flags.contains("Dengeli / Hesaplanmış Reaksiyon")) summary += "Korkutucu durumları sindirip veriye dayalı bilinçli reaksiyon üretebiliyor. ";
    if (flags.contains("Akut Motor Panik")) summary += "Duyusal uyaranların aşırılığı karşısında paniğe kapılıp fiziksel dürtüsel davranabiliyor. ";
    if (flags.contains("Soğukkanlı Kriz Gözlemcisi")) summary += "Göz korkutan kaos atmosferlerinde dahi fiziksel sükunetini koruyabiliyor. ";
    if (flags.contains("Bilgi Algısı İptali / Körlük Kararı")) summary += "Rahatsız edici şirket gerçeklerini öğrenmektense duyarsızlaşmayı veya izole olmayı seçebiliyor. ";
    if (flags.contains("Gerçeklik Metaneti / Şeffaflık")) summary += "Kendi konforuna mal olsa dahi, açık şeffaf bilgi erişimini ve gerçekleri izlemeyi savunuyor. ";

    // Bölüm 7 (Sistemsel Çöküş) Eklemeleri
    if (flags.contains("Derin Analitik Odak")) summary += "Son derece yoğun gürültü ve kaos ortamında manipüle olmadan, asıl hedeflenen veriyi analiz edip çekip çıkartabiliyor. ";
    if (flags.contains("Şanslı Dürtüsellik")) summary += "Karmaşık senaryolarda mantıksal analiz yerine şansını deneyerek riskli ve dürtüsel kararlar alabiliyor. ";
    if (flags.contains("Kör Aksiyon / Dürtüsel Panik")) summary += "Problemi okumaktan ve anlamaktan imtina ederek, dürtüsel panikle hızlı ve hatalı çözümlere atlıyor. ";
    if (flags.contains("Bilişsel Kilitlenme (Bölüm 7)")) summary += "Yoğun stres ve kaotik bilgi seli karşısında risk / inisiyatif almaktan korkarak eylemsiz donakalıyor. ";

    // Bölüm 8 (Dış Gövde Çatlağı) Eklemeleri
    if (flags.contains("Hesaplanmış Akut Müdahale")) summary += "Ani krizlerde kahramanlık fantezisine kapılmadan, prosedürel güvenliği sağlayarak soğukkanlı müdahale edebiliyor. ";
    if (flags.contains("Gecikmeli Güvenlik")) summary += "Şok anında tereddüt yaşasa da nihayetinde doğru güvenlik protokolünü işletmeyi başarıyor. ";
    if (flags.contains("Dürtüsel Kahramanlık / Şehitlik Eğilimi")) summary += "Fiziksel yetersizliklerini göz ardı edip, hızlı ama ölümcül bir kurtarıcı sendromuyla kuralları çiğnemektedir. ";
    if (flags.contains("Akut Şok Kilitlenmesi")) summary += "Ani ve devasa acil durum şoklarında tamamen donakalarak inisiyatif ve hayatta kalma refleksini yitirmektedir. ";

    // Bölüm 9 (Enkazın Ardından) Eklemeleri
    if (flags.contains("Sistemik Öz-Eleştiri")) summary += "Başarısızlık sonrası hatayı rasyonel biçimde kabul edip kendi stratejilerini objektif bir dille sorgulayabiliyor. ";
    if (flags.contains("Adaptif Öğrenme Odağı")) summary += "Krizlerden anında ders çıkarıp esneklik (Growth Mindset) gösteriyor ve değişime açık kalabiliyor. ";
    if (flags.contains("Aşırı Öz-Yıkım / Suçluluk Melankolisi")) summary += "Sorumluluğu üzerine alsa da toksik seviyede duygusal acı çekerek kendi özgüvenini kalıcı olarak zedeliyor. ";
    if (flags.contains("Yüzeysel & Taktiksel Pişmanlık")) summary += "Hatanın kök nedenine inmek yerine, başarısızlığını sadece o anki geçici bir taktiksel dikkat kaybıyla sınırlıyor. ";
    if (flags.contains("Mazeretçi Rasyonalizasyon")) summary += "Suçu kibar ve rasyonel bir mantık çerçevesine oturtarak çevresel faktörlere (dışsal) atma çabasında. ";
    if (flags.contains("Kaderci Öğrenilmiş Çaresizlik")) summary += "Başarısızlığın zaten kaçınılmaz olduğunu savunarak çaba göstermenin anlamsızlaştığı bir öğrenilmiş çaresizlik yaşıyor. ";
    if (flags.contains("Açık Kurban Psikolojisi")) summary += "Gelişime tamamen kapalı kalarak toksik bir kurban sendromuyla suçu doğrudan sisteme ve otoriteye atıyor. ";
    if (flags.contains("Sorumluluk Reddi (Narsistik Savunma)")) summary += "Kendi kusursuz vizyonunu koruyabilmek uğruna, hatayla olan bağını oldukça agresif tartışmalarla reddediyor. ";

    // Bölüm 10 (Buzdan Çıkan Yüz) Eklemeleri
    if (flags.contains("Teknik Yetkinlik Temelli Liderlik")) summary += "Ekip seçiminde duygusal uyum yerine teknik uzmanlığı ve performans çıktılarını önceliklendiren rasyonel bir stil sergiliyor. ";
    if (flags.contains("Sosyal Uyum Temelli Liderlik")) summary += "Başarıyı bireysel yetenekten ziyade ekip sinerjisi ve sosyal uyumda arayan, yapıcı ve bütünleştirici bir liderlik tarzına sahip. ";
    if (flags.contains("Metodik Veri İnceleme")) summary += "Gelecek planlamasında aday dosyalarını ve verileri derinlemesine inceleyerek risk analizi yapma eğiliminde. ";
    if (flags.contains("Sezgisel Seçim Refleksi")) summary += "Kritik atamalarda temel arketipleri hızla süzüp seri karar verme ve operasyonel çeviklik noktasında inisiyatif alabiliyor. ";

    // Bölüm 11 (İlk Tartışma) Eklemeleri
    if (flags.contains("Psikolojik Güvenlik Mimarı")) summary += "Çatışma yönetiminde yapıcı bir diyalog zeminini koruyarak takım motivasyonunu yüksek tutuyor. ";
    if (flags.contains("Duygusuz Rasyonalizasyon")) summary += "Fikir ayrılıklarında empatiden ziyade saf mantık ve veri setlerine odaklanan, soğuk ama tutarlı bir iletişim dili kullanıyor. ";
    if (flags.contains("Hiyerarşik Komuta ve Karar Keskinliği")) summary += "Kriz anlarında hiyerarşiyi ve emir-komuta zincirini ön planda tutan otoriter bir liderlik sergiliyor. ";
    if (flags.contains("Duygusal Manipülasyon ve Toksik Etki")) summary += "Hedefe ulaşmak için baskı ve suçluluk duygusunu araç olarak kullanan yüksek riskli iletişim reflekslerine sahip. ";
    if (flags.contains("Pasif-Agresif Karar Felci")) summary += "Bakım tüneli gibi kritik eşiklerde karar vermekte zorlanarak inisiyatifi başkasına devrediyor. ";

    // Bölüm 12 (Partnerin Hatası) Eklemeleri
    if (flags.contains("Gelişimsel Liderlik (Hata Toleransı)")) summary += "Başkalarının hatalarına karşı toleranslı; cezalandırmak yerine geliştirmeye odaklı koçluk vizyonuna sahip. ";
    if (flags.contains("Kuralcı ve Soğuk Adalet")) summary += "Hata durumlarında duyguları dışlayıp adaleti sadece kural ve prosedürler üzerinden işletmeyi seçiyor. ";
    if (flags.contains("Cezalandırıcı Otoriter Yaklaşım")) summary += "Hatalara karşı sıfır toleransı olan ve cezalandırıcı otoriteyi bir disiplin aracı olarak kullanan sert bir yapıda. ";

    // Bölüm 13 (Güven Testi) Eklemeleri
    if (flags.contains("Güven Odaklı Delegasyon")) summary += "Ekibi için risk alabilen ve en kritik anlarda dahi yetki devretme (delegasyon) cesareti gösteren yüksek güvenli bir liderdir. ";
    if (flags.contains("Koruyucu Mikro-Yönetim")) summary += "Ekibini koruma güdüsüyle veya risk kaçınma refleksiyle kritik işleri kendisi üstlenen mikro-yönetimci bir yönetim dili sergiliyor. ";
    if (flags.contains("Suçlayıcı ve Toksik Güvensizlik")) summary += "Geçmiş hataları kriz anında bir silah olarak kullanarak ekibiyle olan güven bağını zedeleyen suçlayıcı bir tutum sergiliyor. ";

    return summary;
  }

  // ═══════════════════════════════════════════════════════════
  //  BÜTÜNLEŞİK PROFİL MOTORU (Composite Profile Engine)
  // ═══════════════════════════════════════════════════════════

  /// Her flag'in renk/şiddet seviyesi: +2 yeşil, +1 sarı, -1 turuncu, -2 kırmızı, 0 mavi
  static const Map<String, int> _flagSeverity = {
    // B1
    'Analitik Çeviklik': 2,
    'Sistematik Çözümleme': 2,
    'Adaptif Öğrenme': 2,
    'Rastgele Başarı': -1,
    'Örüntü Tanıma': 1,
    'Dürtüsel Aksiyon': -2,
    'Bilişsel Blokaj': -2,
    // B2
    'Stratejik Orkestrasyon': 2,
    'Operasyonel Sürdürülebilirlik': 2,
    'İnsan Sermayesi ve Esenlik': 2,
    'Paydaş Yönetimi ve İletişim': 2,
    'Reaktif Kriz Tepkisi': -2,
    'Tünel Vizyonu': -2,
    'Karar Paralizi': -2,
    // B3
    'Hiper-Odak': 2,
    'Dengeli Analizci': 1,
    'Bilişsel Efor': -1,
    'İşlem Ataleti': -2,
    'Metodik Haritalama': 2,
    'Bilişsel Filtreleme': 2,
    'Bilişsel Toparlanma Hızı': 2,
    'Dürtüsel Refleks': -1,
    'Odak Erozyonu': -2,
    'Hafıza Hassasiyeti': 2,
    'Multitasking Kaygısı': -2,
    // B4
    'Ar-Ge Koruyucusu': 2,
    'Çalışan Hakları Savunucusu': 2,
    'ESG / Vizyon Bilinci': 2,
    'Özgüvenli Karar': 2,
    'Bilişsel Çalkantı': -1,
    'Yüzeysel Bakış': -2,
    // B5
    'Kognitif Dayanıklılık ve Süreç Sadakati': 2,
    'Stres Bağımlı Kural Esnetme': -1,
    'Kognitif Kaçınma / Protokol İhlali': -2,
    'Metodik Veri Süzme': 2,
    'Dürtüsel Yanılgı': -2,
    'Hevristik Deneme Döngüsü': -2,
    'Akut Karar Paralizisi': -2,
    // B6
    'Dengeli / Hesaplanmış Reaksiyon': 2,
    'Erken Karar / Alarm Yorgunluğu Zafiyeti': -2,
    'Soğukkanlı Kriz Gözlemcisi': 2,
    'Akut Motor Panik': -2,
    'Gerçeklik Metaneti / Şeffaflık': 2,
    'Bilgi Algısı İptali / Körlük Kararı': -2,
    // B7
    'Derin Analitik Odak': 2,
    'Şanslı Dürtüsellik': 1,
    'Kör Aksiyon / Dürtüsel Panik': -2,
    'Bilişsel Kilitlenme (Bölüm 7)': -2,
    // B8
    'Hesaplanmış Akut Müdahale': 2,
    'Gecikmeli Güvenlik': 1,
    'Dürtüsel Kahramanlık / Şehitlik Eğilimi': -2,
    'Akut Şok Kilitlenmesi': -2,
    // B9
    'Sistemik Öz-Eleştiri': 2,
    'Adaptif Öğrenme Odağı': 2,
    'Aşırı Öz-Yıkım / Suçluluk Melankolisi': 1,
    'Yüzeysel & Taktiksel Pişmanlık': 1,
    'Mazeretçi Rasyonalizasyon': -1,
    'Kaderci Öğrenilmiş Çaresizlik': -1,
    'Açık Kurban Psikolojisi': -2,
    'Sorumluluk Reddi (Narsistik Savunma)': -2,
    // B10 - MAVİ (stil, puan=0)
    'Teknik Yetkinlik Temelli Liderlik': 0,
    'Sosyal Uyum Temelli Liderlik': 0,
    'Metodik Veri İnceleme': 0,
    'Sezgisel Seçim Refleksi': 0,
    // B11
    'Psikolojik Güvenlik Mimarı': 2,
    'Duygusuz Rasyonalizasyon': 1,
    'Hiyerarşik Komuta ve Karar Keskinliği': -1,
    'Duygusal Manipülasyon ve Toksik Etki': -2,
    'Pasif-Agresif Karar Felci': -2,
    // B12
    'Gelişimsel Liderlik (Hata Toleransı)': 2,
    'Kuralcı ve Soğuk Adalet': -1,
    'Cezalandırıcı Otoriter Yaklaşım': -2,
    // B13
    'Güven Odaklı Delegasyon': 2,
    'Koruyucu Mikro-Yönetim': -1,
    'Suçlayıcı ve Toksik Güvensizlik': -2,
  };

  /// 6 yetkinlik ekseninin flag → eksen eşlemesi
  static const Map<String, List<String>> _axisFlags = {
    'cognitive_agility': [
      'Analitik Çeviklik', 'Sistematik Çözümleme', 'Adaptif Öğrenme',
      'Rastgele Başarı', 'Dürtüsel Aksiyon', 'Bilişsel Blokaj',
      'Hiper-Odak', 'Dengeli Analizci', 'Bilişsel Efor', 'İşlem Ataleti',
      'Metodik Veri Süzme', 'Dürtüsel Yanılgı', 'Hevristik Deneme Döngüsü',
      'Derin Analitik Odak', 'Şanslı Dürtüsellik',
      'Kör Aksiyon / Dürtüsel Panik', 'Bilişsel Kilitlenme (Bölüm 7)',
    ],
    'stress_resilience': [
      'Hiper-Odak', 'Bilişsel Filtreleme', 'Bilişsel Toparlanma Hızı',
      'Odak Erozyonu', 'Multitasking Kaygısı',
      'Kognitif Dayanıklılık ve Süreç Sadakati',
      'Kognitif Kaçınma / Protokol İhlali', 'Stres Bağımlı Kural Esnetme',
      'Dengeli / Hesaplanmış Reaksiyon',
      'Erken Karar / Alarm Yorgunluğu Zafiyeti',
      'Soğukkanlı Kriz Gözlemcisi', 'Akut Motor Panik',
      'Hesaplanmış Akut Müdahale', 'Gecikmeli Güvenlik',
      'Dürtüsel Kahramanlık / Şehitlik Eğilimi', 'Akut Şok Kilitlenmesi',
    ],
    'ethical_integrity': [
      'Stratejik Orkestrasyon', 'Tünel Vizyonu', 'Karar Paralizi',
      'Ar-Ge Koruyucusu', 'Çalışan Hakları Savunucusu',
      'ESG / Vizyon Bilinci', 'Özgüvenli Karar',
      'Bilişsel Çalkantı', 'Yüzeysel Bakış',
      'Sistemik Öz-Eleştiri', 'Adaptif Öğrenme Odağı',
      'Mazeretçi Rasyonalizasyon', 'Açık Kurban Psikolojisi',
      'Sorumluluk Reddi (Narsistik Savunma)',
      'Gerçeklik Metaneti / Şeffaflık',
      'Bilgi Algısı İptali / Körlük Kararı',
    ],
    'leadership': [
      'Psikolojik Güvenlik Mimarı', 'Duygusuz Rasyonalizasyon',
      'Hiyerarşik Komuta ve Karar Keskinliği',
      'Duygusal Manipülasyon ve Toksik Etki',
      'Pasif-Agresif Karar Felci',
      'Gelişimsel Liderlik (Hata Toleransı)',
      'Kuralcı ve Soğuk Adalet', 'Cezalandırıcı Otoriter Yaklaşım',
      'Güven Odaklı Delegasyon', 'Koruyucu Mikro-Yönetim',
      'Suçlayıcı ve Toksik Güvensizlik',
    ],
    'decision_quality': [
      'Stratejik Orkestrasyon', 'Operasyonel Sürdürülebilirlik',
      'İnsan Sermayesi ve Esenlik', 'Paydaş Yönetimi ve İletişim',
      'Reaktif Kriz Tepkisi', 'Karar Paralizi',
      'Özgüvenli Karar', 'Bilişsel Çalkantı', 'Yüzeysel Bakış',
      'Akut Karar Paralizisi',
      'Hesaplanmış Akut Müdahale', 'Akut Şok Kilitlenmesi',
    ],
    'adaptability': [
      'Adaptif Öğrenme', 'Örüntü Tanıma', 'Bilişsel Blokaj',
      'Derin Analitik Odak', 'Bilişsel Kilitlenme (Bölüm 7)',
      'Adaptif Öğrenme Odağı',
      'Aşırı Öz-Yıkım / Suçluluk Melankolisi',
      'Yüzeysel & Taktiksel Pişmanlık',
      'Kaderci Öğrenilmiş Çaresizlik',
      'Hafıza Hassasiyeti', 'Metodik Haritalama',
    ],
  };

  /// Bileşik skorları hesapla (0-100 normalize)
  Map<String, double> calculateCompositeScores(List<String> flags) {
    final Map<String, double> result = {};
    for (final axis in _axisFlags.entries) {
      final relevant = axis.value.where((f) => flags.contains(f)).toList();
      if (relevant.isEmpty) {
        result[axis.key] = -1; // Veri yok
        continue;
      }
      double sum = 0;
      for (final f in relevant) {
        sum += (_flagSeverity[f] ?? 0);
      }
      // Normalize: max possible = relevant.length * 2, min = relevant.length * -2
      final maxPossible = axis.value.length * 2.0;
      final minPossible = axis.value.length * -2.0;
      final normalized = ((sum - minPossible) / (maxPossible - minPossible)) * 100;
      result[axis.key] = normalized.clamp(0, 100);
    }
    return result;
  }

  /// Stil profili (Mavi flag'ler)
  Map<String, String> getStyleProfile(List<String> flags) {
    final Map<String, String> style = {};
    // Ekip Stili
    if (flags.contains('Sosyal Uyum Temelli Liderlik')) {
      style['team_style'] = 'Sosyal Uyum Odaklı';
    } else if (flags.contains('Teknik Yetkinlik Temelli Liderlik')) {
      style['team_style'] = 'Teknik Yetkinlik Odaklı';
    } else {
      style['team_style'] = 'Veri Yok';
    }
    // Karar Metodu
    if (flags.contains('Metodik Veri İnceleme')) {
      style['decision_method'] = 'Metodik / Analitik';
    } else if (flags.contains('Sezgisel Seçim Refleksi')) {
      style['decision_method'] = 'Sezgisel / Hızlı';
    } else {
      style['decision_method'] = 'Veri Yok';
    }
    // Stil skor (0-100 arası, 0=sol uç, 100=sağ uç)
    style['team_style_score'] = flags.contains('Sosyal Uyum Temelli Liderlik') ? '80'
        : flags.contains('Teknik Yetkinlik Temelli Liderlik') ? '20' : '50';
    style['decision_method_score'] = flags.contains('Metodik Veri İnceleme') ? '80'
        : flags.contains('Sezgisel Seçim Refleksi') ? '20' : '50';
    return style;
  }

  /// Çapraz korelasyon flag'leri
  List<Map<String, String>> generateCrossChapterFlags(
      List<String> flags, List<ChapterMetric> metrics) {
    final List<Map<String, String>> correlations = [];

    // --- Korelasyon 1: Söylem-Eylem Tutarlılığı (B2 ↔ B4) ---
    try {
      final b2 = metrics.firstWhere((m) => m.chapterId.contains('Bölüm 2'));
      final b4 = metrics.firstWhere((m) => m.chapterId.contains('Bölüm 4'));
      final b2Levels = b2.additionalData?['final_levels'] as Map<String, dynamic>? ?? {};
      final b2Oxygen = b2Levels['oxygen'] ?? 0;
      final b2Reactor = b2Levels['reactor'] ?? 0;
      final b4Selected = b4.additionalData?['selectedArea']?.toString().toLowerCase() ?? '';

      if (b2Oxygen > b2Reactor && b4Selected == 'quarters') {
        correlations.add({
          'type': 'warning',
          'title': 'Değer-Eylem Çelişkisi',
          'detail': 'B2\'de insanı (Oksijen) önceledi, B4\'te çalışan alanını (Yatakhane) feda etti.',
          'source': 'B2 ↔ B4',
        });
      } else if (b2Oxygen > b2Reactor && b4Selected != 'quarters') {
        correlations.add({
          'type': 'success',
          'title': 'Tutarlı İnsancıl Değer Profili',
          'detail': 'Hem kaynak dağılımında hem feda kararında insan odağı tutarlı.',
          'source': 'B2 ↔ B4',
        });
      }
    } catch (_) {}

    // --- Korelasyon 2: Liderlik Tutarlılığı (B11 ↔ B12 ↔ B13) ---
    try {
      final b11 = metrics.firstWhere((m) => m.chapterId.contains('Bölüm 11'));
      final b12 = metrics.firstWhere((m) => m.chapterId.contains('Bölüm 12'));
      final b13 = metrics.firstWhere((m) => m.chapterId.contains('Bölüm 13'));
      final c11 = b11.additionalData?['choiceId'] ?? '';
      final c12 = b12.additionalData?['choiceId'] ?? '';
      final c13 = b13.additionalData?['choiceId'] ?? '';

      if (c11 == 'COLLABORATIVE' && c12 == 'CONSTRUCTIVE' && c13 == 'DELEGATE') {
        correlations.add({
          'type': 'success',
          'title': 'Tam Demokratik Lider Profili',
          'detail': 'Çatışmada uzlaşmacı, hatada yapıcı, finalde güven veriyor.',
          'source': 'B11 ↔ B12 ↔ B13',
        });
      } else if (c11 == 'COLLABORATIVE' && c12 == 'PUNITIVE') {
        correlations.add({
          'type': 'warning',
          'title': 'Yüzeysel Empati Maskesi',
          'detail': 'Rahat ortamda uzlaşmacı, kriz anında cezalandırıcı.',
          'source': 'B11 ↔ B12',
        });
      }
      if (c12 == 'PUNITIVE' && c13 == 'DISTRUST') {
        correlations.add({
          'type': 'danger',
          'title': 'Toksik Otorite Zinciri',
          'detail': 'Cezalandırıcı tutum + güvensizlik → ekip yıkıcı.',
          'source': 'B12 ↔ B13',
        });
      }
    } catch (_) {}

    // --- Korelasyon 3: Stres Kırılma Noktası (B1→B3→B5→B6→B8) ---
    final stressChapters = ['Bölüm 1', 'Bölüm 3', 'Bölüm 5', 'Bölüm 6', 'Bölüm 8'];
    int breakIndex = -1;
    for (int i = 0; i < stressChapters.length; i++) {
      final chFlags = _getChapterFlags(stressChapters[i], flags, metrics);
      final hasNegative = chFlags.any((f) => (_flagSeverity[f] ?? 0) < 0);
      if (hasNegative && breakIndex == -1) breakIndex = i;
    }
    if (breakIndex >= 0) {
      correlations.add({
        'type': 'info',
        'title': 'Stres Kırılma Noktası: ${stressChapters[breakIndex]}',
        'detail': 'Artan baskı altında ilk negatif davranış bu noktada ortaya çıktı.',
        'source': 'B1→B3→B5→B6→B8',
      });
    }

    // --- Korelasyon 4: Sorumluluk Zinciri (B8 ↔ B9) ---
    if (flags.contains('Dürtüsel Kahramanlık / Şehitlik Eğilimi') &&
        (flags.contains('Sorumluluk Reddi (Narsistik Savunma)') ||
         flags.contains('Açık Kurban Psikolojisi'))) {
      correlations.add({
        'type': 'danger',
        'title': 'Kör Nokta: Hatasını Görmeyip Tekrarlama Riski',
        'detail': 'Dürtüsel aksiyon + sorumluluk reddi → aynı hatayı tekrarlama.',
        'source': 'B8 ↔ B9',
      });
    }

    // --- Korelasyon 5: Delegasyon Paradoksu (B10 ↔ B13) ---
    if (flags.contains('Sosyal Uyum Temelli Liderlik') &&
        flags.contains('Koruyucu Mikro-Yönetim')) {
      correlations.add({
        'type': 'warning',
        'title': 'Söylemde Ekipçi, Eylemde Bireyci',
        'detail': 'Ekip odaklı partner seçimi ama kritik anda yetki devretmeme.',
        'source': 'B10 ↔ B13',
      });
    }

    return correlations;
  }

  /// Hangi bölümden hangi flag'ler geldi
  List<String> _getChapterFlags(String chapterId, List<String> allFlags, List<ChapterMetric> metrics) {
    try {
      final m = metrics.firstWhere((m) => m.chapterId.contains(chapterId));
      if (chapterId.contains('1')) return _analyzeChapter1(m);
      if (chapterId.contains('3')) return _analyzeChapter3(m);
      if (chapterId.contains('5')) return _analyzeChapter5(m);
      if (chapterId.contains('6')) return _analyzeChapter6(m);
      if (chapterId.contains('8')) return _analyzeChapter8(m);
    } catch (_) {}
    return [];
  }

  /// Eksen etiketleri (Türkçe)
  static String getAxisLabel(String key) {
    switch (key) {
      case 'cognitive_agility': return 'Bilişsel Çeviklik';
      case 'stress_resilience': return 'Stres Dayanıklılığı';
      case 'ethical_integrity': return 'Etik Tutarlılık';
      case 'leadership': return 'Liderlik & İletişim';
      case 'decision_quality': return 'Karar Kalitesi';
      case 'adaptability': return 'Adaptasyon & Öğrenme';
      default: return key;
    }
  }

  /// Flag'in şiddet seviyesini döndürür
  static int getFlagSeverity(String flag) => _flagSeverity[flag] ?? 0;
}
