import '../native/native_bridge.dart';
import 'model_catalog.dart';

enum Fit { good, tight, no }

class ModelFit {
  const ModelFit(this.spec, this.fit, this.reason);
  final ModelSpec spec;
  final Fit fit;

  /// Plain-language reason shown to the user (English; UI may localise).
  final String reason;
  bool get downloadable => fit != Fit.no;
}

class Recommendation {
  const Recommendation({
    required this.fits,
    required this.best,
    required this.summary,
  });
  final List<ModelFit> fits;

  /// null = rules only (phone too small / not 64-bit / no specs).
  final ModelFit? best;
  final String summary;
}

/// Picks a model tier from the phone's real specs (brief section 10: target
/// ~1 GB RAM for the small tier; the big tier is for 6 GB+ phones).
class ModelRecommender {
  const ModelRecommender();

  static const headroomMb = 400; // leave room for Android + Dholu itself

  Recommendation recommend(
    DeviceSpecs? s, {
    List<ModelSpec> catalog = ModelCatalog.all,
  }) {
    if (s == null) {
      return const Recommendation(
        fits: [],
        best: null,
        summary:
            'Could not read phone specs. Rules mode works without a model.',
      );
    }
    final fits = [for (final m in catalog) _fit(m, s)];
    // Prefer the biggest model that fits "good"; otherwise the biggest "tight"; else none.
    ModelFit? best;
    for (final level in [Fit.good, Fit.tight]) {
      final ok = fits.where((f) => f.fit == level).toList()
        ..sort((a, b) => b.spec.approxBytes.compareTo(a.spec.approxBytes));
      if (ok.isNotEmpty) {
        best = level == Fit.good ? _preferBig(ok) : ok.last;
        break;
      }
    }
    final ram = s.totalRamGb.toStringAsFixed(1);
    final summary = best == null
        ? 'Your phone ($ram GB RAM) is best on Rules mode. It is fast and still catches the important ones.'
        : '${s.model.trim()} · $ram GB RAM · ${(s.freeStorageMb / 1024).toStringAsFixed(1)} GB free. Recommended: ${best.spec.name}.';
    return Recommendation(fits: fits, best: best, summary: summary);
  }

  // "max" only when it is clearly comfortable; otherwise the 2 GB "big" tier.
  ModelFit _preferBig(List<ModelFit> goodSortedDesc) {
    final max = goodSortedDesc
        .where((f) => f.spec.tier == ModelTier.max)
        .toList();
    final big = goodSortedDesc
        .where((f) => f.spec.tier == ModelTier.big)
        .toList();
    if (big.isNotEmpty) return big.first;
    if (max.isNotEmpty) return max.first;
    return goodSortedDesc.first;
  }

  ModelFit _fit(ModelSpec m, DeviceSpecs s) {
    if (!s.isArm64) return ModelFit(m, Fit.no, 'Needs a 64-bit ARM phone.');
    if (s.sdk < 26) return ModelFit(m, Fit.no, 'Needs Android 8 or newer.');
    if (s.lowRam) {
      return ModelFit(m, Fit.no, 'Android marks this phone as low-RAM.');
    }
    final needStorage = (m.approxBytes / (1024 * 1024)).ceil() + 300;
    if (s.freeStorageMb < needStorage) {
      return ModelFit(
        m,
        Fit.no,
        'Needs ${(needStorage / 1024).toStringAsFixed(1)} GB free storage.',
      );
    }
    if (s.totalRamMb < m.minRamMb) {
      return ModelFit(
        m,
        Fit.no,
        'Needs about ${(m.minRamMb / 1024).ceil()} GB RAM.',
      );
    }
    // Comfortable if there is plenty of headroom above the minimum.
    final margin = s.totalRamMb - m.minRamMb;
    if (margin < 1000 || s.cores < 6 && m.tier != ModelTier.small) {
      return ModelFit(
        m,
        Fit.tight,
        'Will run, but may be slow or close other apps.',
      );
    }
    return ModelFit(m, Fit.good, 'Good fit for this phone.');
  }
}
