import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isAvailable = false;
  String _selectedLocaleId = 'es-ES'; // ✅ Locale por defecto

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

      // ✅ Verificar locales disponibles
      if (_isAvailable) {
        final locales = await _speech.locales();
        print(
          '📍 Locales disponibles: ${locales.map((l) => l.localeId).join(", ")}',
        );

        // Buscar español
        final spanishLocale = locales.firstWhere(
          (locale) => locale.localeId.startsWith('es'),
          orElse: () => locales.first,
        );
        _selectedLocaleId = spanishLocale.localeId;
        print('✅ Usando locale: $_selectedLocaleId');
      }

      // Configurar text to speech
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.6); // ✅ Un poco más rápido
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
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎤 [VOZ-SERVICE] INICIANDO ESCUCHA...');
    
    if (!_isAvailable) {
      print('❌ [VOZ-SERVICE] Servicio de voz no disponible');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }

    if (_isListening) {
      print('⚠️ [VOZ-SERVICE] Ya está escuchando');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }

    String? recognizedText;
    String? lastPartialResult;
    bool hasReceivedResult = false;

    try {
      _isListening = true;
      print('📡 [VOZ-SERVICE] Micrófono activado - Locale: $_selectedLocaleId');

      await _speech.listen(
        onResult: (result) {
          hasReceivedResult = true;
          lastPartialResult = result.recognizedWords;

          // ✅ Actualizar con el resultado final cuando esté disponible
          if (result.finalResult) {
            recognizedText = result.recognizedWords;
            print('✅ [VOZ-SERVICE] TEXTO FINAL: "$recognizedText"');
          } else {
            print('⏳ [VOZ-SERVICE] Texto parcial: "$lastPartialResult"');
          }
        },
        listenFor: const Duration(seconds: 8), // ✅ 8 segundos (más realista)
        pauseFor: const Duration(seconds: 2), // ✅ 2 segundos de pausa
        partialResults: true, // ✅ Mostrar resultados parciales
        localeId: _selectedLocaleId, // ✅ Usar locale detectado
        cancelOnError: false, // ✅ No cancelar en errores menores
        listenMode: stt.ListenMode.confirmation, // ✅ Modo confirmación
      );

      // ✅ Esperar hasta que termine o timeout
      int waitCount = 0;
      while (_isListening && waitCount < 90) {
        // 9 segundos max
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
        
        if (waitCount % 10 == 0) {
          print('⏱️ [VOZ-SERVICE] Esperando... ${waitCount / 10}s');
        }
      }

      // ✅ Si no hay resultado final, usar el último parcial
      if (recognizedText == null &&
          lastPartialResult != null &&
          lastPartialResult!.isNotEmpty) {
        recognizedText = lastPartialResult;
        print('⚠️ [VOZ-SERVICE] Usando resultado parcial como final: "$recognizedText"');
      }

      // ✅ Si no recibió nada, informar
      if (!hasReceivedResult ||
          recognizedText == null ||
          recognizedText!.isEmpty) {
        print('❌ [VOZ-SERVICE] No se reconoció ningún texto');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🎯 [VOZ-SERVICE] TEXTO RECONOCIDO: "$recognizedText"');
      print('   Longitud: ${recognizedText!.length} caracteres');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return recognizedText;
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ [VOZ-SERVICE] ERROR: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    } finally {
      _isListening = false;
      await _speech.stop(); // ✅ Asegurar que se detenga
      print('🛑 [VOZ-SERVICE] Micrófono desactivado');
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
