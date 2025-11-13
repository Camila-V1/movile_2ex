import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/voice_command_processor.dart';

class VoiceButton extends StatefulWidget {
  final VoiceCommandProcessor commandProcessor;
  final Function(VoiceCommandResult) onCommandProcessed;

  const VoiceButton({
    super.key,
    required this.commandProcessor,
    required this.onCommandProcessed,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();

  bool _isInitialized = false;
  bool _isListening = false;
  String _listeningText = 'Escuchando...';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVoice();

    // Animación del botón mientras escucha
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
    });

    if (!initialized) {
      _showError('No se pudo inicializar el reconocimiento de voz');
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      _showError('Servicio de voz no disponible');
      return;
    }

    if (_isListening) return;

    // ✅ Verificar mounted antes de setState
    if (!mounted) return;

    setState(() {
      _isListening = true;
      _listeningText = 'Escuchando...';
    });

    // ✅ Esperar a que termine de hablar ANTES de escuchar
    await _voiceService.speak('¿Qué deseas hacer?');
    await Future.delayed(
      const Duration(milliseconds: 1500),
    ); // ✅ Esperar a que termine TTS

    // ✅ Detener TTS explícitamente antes de escuchar
    await _voiceService.stopSpeaking();

    final command = await _voiceService.listen();

    // ✅ Verificar mounted antes de setState
    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    if (command == null || command.isEmpty) {
      await _voiceService.speak('No escuché nada. Intenta de nuevo.');
      return;
    }

    // ✅ Verificar mounted antes de setState
    if (!mounted) return;

    setState(() {
      _listeningText = 'Procesando: "$command"';
    });

    // Procesar comando
    final result = await widget.commandProcessor.processCommand(command);

    // ✅ Si necesita especificar producto, escuchar de nuevo
    if (result.action == VoiceAction.needsProduct) {
      await _voiceService.speak(result.message);
      await Future.delayed(const Duration(milliseconds: 1500));
      await _voiceService.stopSpeaking();

      // Escuchar el nombre del producto
      final productCommand = await _voiceService.listen();

      if (productCommand != null && productCommand.isNotEmpty) {
        // Construir comando completo
        final fullCommand = 'añadir $productCommand al carrito';
        print('🔄 Reintentando con comando completo: "$fullCommand"');

        // Procesar comando completo
        final newResult = await widget.commandProcessor.processCommand(
          fullCommand,
        );
        await _voiceService.speak(newResult.message);
        widget.onCommandProcessed(newResult);
      } else {
        await _voiceService.speak('No escuché el producto. Intenta de nuevo.');
      }
      return;
    }

    // Dar feedback de voz
    await _voiceService.speak(result.message);

    // Ejecutar callback
    widget.onCommandProcessed(result);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de micrófono
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _scaleAnimation.value : 1.0,
              child: FloatingActionButton(
                onPressed: _isInitialized && !_isListening
                    ? _startListening
                    : null,
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 32,
                ),
              ),
            );
          },
        ),

        // Texto de estado
        if (_isListening)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _listeningText,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
