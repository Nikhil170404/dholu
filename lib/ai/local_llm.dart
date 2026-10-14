import 'dart:math' as math;

import 'package:llamadart/llamadart.dart';

import '../native/native_bridge.dart';
import 'llm.dart';
import 'model_catalog.dart';

/// On-device GGUF inference through llama.cpp (llamadart). CPU only by default:
/// Vulkan on Android is still experimental, and CPU is the safest on cheap phones.
class LocalLlm extends LlmBackend {
  LocalLlm._(this._engine, this.spec);

  final LlamaEngine _engine;
  final ModelSpec spec;

  static Future<LocalLlm> load(
    String path,
    ModelSpec spec, {
    DeviceSpecs? device,
  }) async {
    // big.LITTLE phones: use about half the cores (the fast ones), never fewer than 2.
    final threads = math.max(
      2,
      math.min(6, ((device?.cores ?? 8) / 2).round()),
    );
    final engine = await LlamaEngine.load(
      LlamaModel(ModelSource.path(path)),
      params: ModelParams(
        contextSize: spec.contextSize,
        gpuLayers: 0,
        numberOfThreads: threads,
        numberOfThreadsBatch: threads,
        useMmap: true,
      ),
    );
    return LocalLlm._(engine, spec);
  }

  @override
  String get label => '${spec.name} (on this phone)';
  @override
  bool get isLocal => true;

  List<LlamaChatMessage> _msgs(List<ChatTurn> turns) => [
    for (final t in fitTurns(turns, spec.contextSize - 600))
      LlamaChatMessage.fromText(
        role: switch (t.role) {
          TurnRole.system => LlamaChatRole.system,
          TurnRole.user => LlamaChatRole.user,
          TurnRole.assistant => LlamaChatRole.assistant,
        },
        text: t.text,
      ),
  ];

  @override
  Stream<String> chat(
    List<ChatTurn> turns, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) => _engine
      .create(
        _msgs(turns),
        params: GenerationParams(maxTokens: maxTokens, temp: temperature),
        enableThinking: false,
      )
      .textDeltas();

  @override
  Future<Map<String, dynamic>?> json(
    List<ChatTurn> turns,
    Map<String, dynamic> schema, {
    int maxTokens = 160,
  }) async {
    try {
      final out = LlamaStructuredOutput<Map<String, dynamic>>.jsonSchema(
        schema: schema,
        decoder: (m) => m,
      );
      return await _engine.createStructuredJson<Map<String, dynamic>>(
        _msgs(turns),
        output: out,
        params: GenerationParams(maxTokens: maxTokens, temp: 0.1),
        enableThinking: false,
      );
    } on LlamaException {
      return null;
    }
  }

  void cancel() => _engine.cancelGeneration();

  @override
  Future<void> dispose() => _engine.dispose();
}
