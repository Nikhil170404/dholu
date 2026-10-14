import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/ai/model_catalog.dart';
import 'package:dholu/ai/recommender.dart';
import 'package:dholu/native/native_bridge.dart';

DeviceSpecs specs({
  int ram = 8192,
  int storage = 20000,
  int cores = 8,
  List<String> abis = const ['arm64-v8a'],
  int sdk = 34,
  bool low = false,
}) => DeviceSpecs(
  totalRamMb: ram,
  availRamMb: ram ~/ 2,
  freeStorageMb: storage,
  cores: cores,
  abis: abis,
  sdk: sdk,
  lowRam: low,
  soc: 'x',
  model: 'Test Phone',
);

void main() {
  const r = ModelRecommender();
  test('2 GB phone -> rules only', () {
    final rec = r.recommend(specs(ram: 2048, cores: 4));
    expect(rec.best, isNull);
    expect(rec.fits.every((f) => f.fit == Fit.no), isTrue);
  });
  test('4 GB phone -> small only', () {
    final rec = r.recommend(specs(ram: 4096, cores: 8));
    expect(rec.best!.spec.tier, ModelTier.small);
    expect(
      rec.fits.firstWhere((f) => f.spec.tier == ModelTier.big).fit,
      Fit.no,
    );
  });
  test('8 GB phone -> recommends the 2 GB big tier, max also offered', () {
    final rec = r.recommend(specs(ram: 8192));
    expect(rec.best!.spec.tier, ModelTier.big);
    expect(
      rec.fits.firstWhere((f) => f.spec.tier == ModelTier.max).downloadable,
      isTrue,
    );
  });
  test('12 GB phone still defaults to big (max is opt-in)', () {
    expect(r.recommend(specs(ram: 12288)).best!.spec.tier, ModelTier.big);
  });
  test('low storage blocks big but not small', () {
    final rec = r.recommend(specs(ram: 8192, storage: 1500));
    expect(rec.best!.spec.tier, ModelTier.small);
  });
  test('32-bit / x86 / low-RAM flag -> none', () {
    expect(r.recommend(specs(abis: ['armeabi-v7a'])).best, isNull);
    expect(r.recommend(specs(abis: ['x86_64'])).best, isNull);
    expect(r.recommend(specs(low: true)).best, isNull);
  });
  test('no specs -> rules only', () {
    expect(r.recommend(null).best, isNull);
  });
  test('catalog sizes match the requested tiers', () {
    expect(
      ModelCatalog.small.approxBytes,
      inInclusiveRange(500 << 20, 1024 << 20),
    );
    expect(ModelCatalog.big.approxGb, closeTo(2.0, 0.15));
  });
}
