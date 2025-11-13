import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _isAvailable = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  /// Inicializar el servicio de voz
  Future<bool> initialize() async {
    try {
      // Solicitar permisos
      final status = await Permission.microphone.request();
      
      if (status != PermissionStatus.granted) {
        print('❌ Permiso de micrófono denegado');
        return false;
      }

      // Inicializar speech to text
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          print('🎤 Estado del reconocimiento: $status');
          _isListening = status == 'listening';
        },
        onError: (error) {
          print('❌ Error de reconocimiento: $error');
          _isListening = false;
        },
      );

      // Configurar text to speech
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      print('✅ Servicio de voz inicializado: $_isAvailable');
      return _isAvailable;
      
    } catch (e) {
      print('❌ Error inicializando voz: $e');
      return false;
    }
  }

  /// Escuchar comando de voz
  Future<String?> listen() async {
    if (!_isAvailable) {
      print('❌ Servicio de voz no disponible');
      return null;
    }

    if (_isListening) {
      print('⚠️ Ya está escuchando');
      return null;
    }

    String? recognizedText;

    try {
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          print('🎤 Reconocido: $recognizedText');
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'es_ES', // Español
      );

      // Esperar a que termine de escuchar
      await Future.delayed(const Duration(seconds: 6));

      return recognizedText;
      
    } catch (e) {
      print('❌ Error escuchando: $e');
      return null;
    } finally {
      _isListening = false;
    }
  }

  /// Detener escucha
  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
  }

  /// Hablar (dar feedback al usuario)
  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ Error hablando: $e');
    }
  }

  /// Cancelar habla
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// Verificar si tiene permisos
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Solicitar permisos
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Limpiar recursos
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
  }
}
