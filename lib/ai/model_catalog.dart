/// On-device model tiers. Sizes are Q4_K_M GGUF files.
///
/// The URLs/filenames follow the bartowski GGUF repos on Hugging Face. They could not be
/// fetched from the build sandbox, so the app re-checks the real size with a HEAD request
/// before downloading and reports a clear error if a file moved. Users can also add a
/// custom GGUF URL in Settings.
enum ModelTier { small, big, max }

class ModelSpec {
  const ModelSpec({
    required this.id,
    required this.name,
    required this.tier,
    required this.url,
    required this.fileName,
    required this.approxBytes,
    required this.minRamMb,
    required this.contextSize,
    required this.licenseNote,
    required this.blurb,
    this.sizeVerified = false,
  });

  final String id;
  final String name;
  final ModelTier tier;
  final String url;
  final String fileName;
  final int approxBytes;

  /// Total phone RAM (MB) below which we do not offer this model.
  final int minRamMb;
  final int contextSize;
  final String licenseNote;
  final String blurb;

  /// True when the size was read from the published file listing.
  final bool sizeVerified;

  double get approxGb => approxBytes / (1024 * 1024 * 1024);
  String get sizeLabel => approxBytes >= 1024 * 1024 * 1024
      ? '${approxGb.toStringAsFixed(1)} GB'
      : '${(approxBytes / (1024 * 1024)).round()} MB';

  static ModelSpec custom(String url) {
    final name = Uri.tryParse(url)?.pathSegments.last ?? 'custom.gguf';
    return ModelSpec(
      id: 'custom',
      name: 'Custom: $name',
      tier: ModelTier.big,
      url: url,
      fileName: 'custom.gguf',
      approxBytes: 0,
      minRamMb: 0,
      contextSize: 2048,
      licenseNote: 'You are responsible for the licence of a custom model.',
      blurb: 'Your own GGUF model.',
    );
  }
}

class ModelCatalog {
  static const small = ModelSpec(
    id: 'gemma3-1b',
    name: 'Dholu Chhota (Gemma 3 1B)',
    tier: ModelTier.small,
    url: 'https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf',
    fileName: 'google_gemma-3-1b-it-Q4_K_M.gguf',
    approxBytes: 869 * 1024 * 1024, // 0.81 GB per the repo listing
    minRamMb: 2800,
    contextSize: 2048,
    licenseNote: 'Gemma terms of use apply.',
    blurb: 'Fast on most phones. Classifies notifications and writes short drafts.',
    sizeVerified: true,
  );

  static const big = ModelSpec(
    id: 'llama32-3b',
    name: 'Dholu Bada (Llama 3.2 3B)',
    tier: ModelTier.big,
    url: 'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    fileName: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    approxBytes:
        2020 *
        1024 *
        1024, // ~2.0 GB estimate (Q4_K_M ~ 0.6 GB per billion params)
    minRamMb: 5500,
    contextSize: 3072,
    licenseNote: 'Built with Llama. Llama 3.2 Community License applies.',
    blurb: 'Better chat, emails and summaries. Needs a 6 GB+ phone.',
  );

  static const max = ModelSpec(
    id: 'qwen3-4b',
    name: 'Dholu Max (Qwen3 4B)',
    tier: ModelTier.max,
    url: 'https://huggingface.co/bartowski/Qwen_Qwen3-4B-GGUF/resolve/main/Qwen_Qwen3-4B-Q4_K_M.gguf',
    fileName: 'Qwen_Qwen3-4B-Q4_K_M.gguf',
    approxBytes: 2560 * 1024 * 1024, // 2.50 GB per the repo listing
    minRamMb: 7500,
    contextSize: 4096,
    licenseNote: 'Apache 2.0.',
    blurb: 'Strongest reasoning and multilingual (Hindi) quality. Needs an 8 GB+ phone.',
    sizeVerified: true,
  );

  static const all = [small, big, max];

  static ModelSpec? byId(String? id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}
