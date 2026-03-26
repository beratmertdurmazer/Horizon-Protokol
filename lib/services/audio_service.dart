import 'dart:js_interop';
import 'package:web/web.dart' as web;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  web.AudioContext? _ctx;
  web.OscillatorNode? _ambientOsc;
  web.GainNode? _ambientGain;

  web.AudioContext _getContext() {
    _ctx ??= web.AudioContext();
    return _ctx!;
  }

  void playTypingBeep() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.value = 850;
      gain.gain.value = 0.03;
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.02);
    } catch (e) {}
  }

  void playGlitchSound() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.value = 120;
      gain.gain.value = 0.06;
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.2);
    } catch (e) {}
  }

  /// Kalp atışı (Heartbeat) sesi - Programatik Thump
  void playHeartbeat() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      
      // Alçak frekanslı vuruş
      osc.type = 'sine';
      osc.frequency.setValueAtTime(60, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(30, ctx.currentTime + 0.1);
      
      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.15);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.15);
    } catch (e) {}
  }

  web.OscillatorNode? _sirenOsc;
  web.GainNode? _sirenGain;

  void playAmbientLoop() {
    try {
      if (_ambientOsc != null) return;
      final ctx = _getContext();
      _ambientOsc = ctx.createOscillator();
      _ambientGain = ctx.createGain();
      _ambientOsc!.type = 'sine';
      _ambientOsc!.frequency.value = 45; // Deeper hum
      _ambientGain!.gain.value = 0.08;
      _ambientOsc!.connect(_ambientGain!);
      _ambientGain!.connect(ctx.destination);
      _ambientOsc!.start();
    } catch (e) {}
  }

  /// Sürekli çalan siren sesi (Urgent Siren)
  void playUrgentSiren() {
    try {
      if (_sirenOsc != null) return;
      final ctx = _getContext();
      _sirenOsc = ctx.createOscillator();
      _sirenGain = ctx.createGain();
      
      _sirenOsc!.type = 'triangle';
      _sirenGain!.gain.value = 0.04;
      
      // Siren efekti: Frekans 400-600 arasında gidip gelsin
      final now = ctx.currentTime;
      _sirenOsc!.frequency.setValueAtTime(400, now);
      for(int i = 0; i < 60; i++) {
        _sirenOsc!.frequency.linearRampToValueAtTime(600, now + (i * 1.0) + 0.5);
        _sirenOsc!.frequency.linearRampToValueAtTime(400, now + (i * 1.0) + 1.0);
      }

      _sirenOsc!.connect(_sirenGain!);
      _sirenGain!.connect(ctx.destination);
      _sirenOsc!.start();
    } catch (e) {}
  }

  void stopSiren() {
    try { 
      _sirenOsc?.stop(); 
      _sirenOsc = null; 
    } catch (e) {}
  }

  /// Devasa metal şalter sesi (Metal Clunk)
  void playMetalClunk() {
    try {
      final ctx = _getContext();
      
      // Low impact
      final osc1 = ctx.createOscillator();
      final gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(40, ctx.currentTime);
      osc1.frequency.exponentialRampToValueAtTime(10, ctx.currentTime + 0.5);
      gain1.gain.setValueAtTime(0.4, ctx.currentTime);
      gain1.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.5);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start();
      osc1.stop(ctx.currentTime + 0.5);

      // Mid metallic ring
      final osc2 = ctx.createOscillator();
      final gain2 = ctx.createGain();
      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(120, ctx.currentTime);
      gain2.gain.setValueAtTime(0.1, ctx.currentTime);
      gain2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.3);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start();
      osc2.stop(ctx.currentTime + 0.3);
    } catch (e) {}
  }

  /// Enerji patlaması/sıçraması (Power Surge)
  void playPowerSurge() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(50, ctx.currentTime);
      osc.frequency.linearRampToValueAtTime(400, ctx.currentTime + 0.1);
      gain.gain.setValueAtTime(0.1, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.1);
    } catch (e) {}
  }

  /// Metal gıcırtı sesi (Metal Grind)
  void playMetalGrind() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      
      osc.type = 'sawtooth';
      // Low frequency rumble with modulation
      osc.frequency.setValueAtTime(30, ctx.currentTime);
      osc.frequency.linearRampToValueAtTime(60, ctx.currentTime + 2.0);
      
      gain.gain.setValueAtTime(0.05, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 2.0);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 2.0);
    } catch (e) {}
  }

  /// Vakum ve hava sızıntısı sesi (Vacuum Hiss)
  void playVacuumHiss() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      
      osc.type = 'sawtooth'; // Rough air sound
      osc.frequency.setValueAtTime(800, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1200, ctx.currentTime + 3.0);
      
      gain.gain.setValueAtTime(0.08, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 3.0);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 3.0);
    } catch (e) {}
  }

  /// Sarsıntı ve darbe sesi (Structural Shake)
  void playStructuralShake() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(40, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(20, ctx.currentTime + 1.5);
      
      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 1.5);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 1.5);
    } catch (e) {}
  }

  web.OscillatorNode? _melancholicOsc;
  web.GainNode? _melancholicGain;

  /// Hüzünlü ve derin atmosfer sesi (Melancholic Ambient)
  void playMelancholicAmbient() {
    try {
      if (_melancholicOsc != null) return;
      final ctx = _getContext();
      _melancholicOsc = ctx.createOscillator();
      _melancholicGain = ctx.createGain();
      
      _melancholicOsc!.type = 'sine';
      _melancholicOsc!.frequency.value = 55; // Low bass
      _melancholicGain!.gain.value = 0.05;
      
      _melancholicOsc!.connect(_melancholicGain!);
      _melancholicGain!.connect(ctx.destination);
      _melancholicOsc!.start();
    } catch (e) {}
  }

  void stopMelancholic() {
    try { 
      _melancholicOsc?.stop(); 
      _melancholicOsc = null; 
    } catch (e) {}
  }

  web.OscillatorNode? _frostOsc;
  web.GainNode? _frostGain;

  /// Buz kırılma sesi (Frost Crack)
  void playFrostCrack() {
    try {
      final ctx = _getContext();
      _frostOsc = ctx.createOscillator();
      _frostGain = ctx.createGain();
      
      _frostOsc!.type = 'square';
      _frostOsc!.frequency.setValueAtTime(100, ctx.currentTime);
      _frostOsc!.frequency.exponentialRampToValueAtTime(10, ctx.currentTime + 0.5);
      
      _frostGain!.gain.setValueAtTime(0.05, ctx.currentTime);
      _frostGain!.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.5);
      
      _frostOsc!.connect(_frostGain!);
      _frostGain!.connect(ctx.destination);
      _frostOsc!.start();
      _frostOsc!.stop(ctx.currentTime + 0.5);
    } catch (e) {}
  }

  void playVentEcho() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final g = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(60, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(30, ctx.currentTime + 1.0);
      g.gain.setValueAtTime(0.03, ctx.currentTime);
      g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.0);
      osc.connect(g);
      g.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 1.0);
    } catch (e) {}
  }

  void playFireCrackle() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final g = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(50, ctx.currentTime);
      g.gain.setValueAtTime(0.04, ctx.currentTime);
      // Random volume fluctuations for fire effect
      osc.connect(g);
      g.connect(ctx.destination);
      osc.start();
      _sirenOsc = osc; // reuse siren slot or create separate one
    } catch (e) {}
  }

  void playTensePulse() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final g = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(50, ctx.currentTime);
      g.gain.setValueAtTime(0.08, ctx.currentTime);
      g.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.4);
      osc.connect(g);
      g.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.4);
    } catch (e) {}
  }

  void playPowerOn() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(40, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(400, ctx.currentTime + 1.0);
      gain.gain.setValueAtTime(0.08, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 1.5);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 1.5);
    } catch (e) {}
  }

  void playStaticBurst() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(100, ctx.currentTime);
      // Frequency jitter
      for (int i = 0; i < 5; i++) {
        osc.frequency.setValueAtTime(100 + (i * 50), ctx.currentTime + (i * 0.05));
      }
      gain.gain.setValueAtTime(0.1, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.3);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.3);
    } catch (e) {}
  }

  void playTick() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final g = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1400, ctx.currentTime);
      g.gain.setValueAtTime(0.02, ctx.currentTime);
      g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.05);
      osc.connect(g);
      g.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.05);
    } catch (e) {}
  }

  void playPowerDown() {
    try {
      final ctx = _getContext();
      final osc = ctx.createOscillator();
      final g = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(120, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(10, ctx.currentTime + 0.8);
      g.gain.setValueAtTime(0.1, ctx.currentTime);
      g.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.8);
      osc.connect(g);
      g.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.8);
    } catch (e) {}
  }

  void stopAll() {
    try { _ambientOsc?.stop(); _ambientOsc = null; } catch (e) {}
    try { _sirenOsc?.stop(); _sirenOsc = null; } catch (e) {}
    try { _melancholicOsc?.stop(); _melancholicOsc = null; } catch (e) {}
    try { _frostOsc?.stop(); _frostOsc = null; } catch (e) {}
  }
}
