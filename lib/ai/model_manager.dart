import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../settings/settings.dart';
import 'model_catalog.dart';

enum InstallStatus { none, downloading, paused, verifying, ready, failed }

class ModelInstall {
  const ModelInstall({
    this.status = InstallStatus.none,
    this.progress = 0,
    this.error,
    this.totalBytes,
  });
  final InstallStatus status;
  final double progress;
  final String? error;
  final int? totalBytes;

  ModelInstall copyWith({
    InstallStatus? status,
    double? progress,
    String? error,
    int? totalBytes,
  }) => ModelInstall(
    status: status ?? this.status,
    progress: progress ?? this.progress,
    error: error,
    totalBytes: totalBytes ?? this.totalBytes,
  );
}

enum DlState { running, paused, complete, failed, canceled }

class DlUpdate {
  const DlUpdate(this.taskId, this.state, {this.progress = 0, this.error});
  final String taskId;
  final DlState state;
  final double progress;
  final String? error;
}

/// Transport for big model files. The real one uses WorkManager-backed downloads so a
/// 2 GB file survives the app being backgrounded; tests use a fake.
abstract class ModelDownloader {
  Stream<DlUpdate> get updates;
  Future<Directory> modelsDir();
  Future<void> start(
    String taskId,
    String url,
    String fileName, {
    required bool wifiOnly,
  });
  Future<void> pause(String taskId);
  Future<void> resume(String taskId);
  Future<void> cancel(String taskId);

  /// Size in bytes of the remote file (follows redirects), or null if unreachable.
  Future<int?> remoteSize(String url);
}

class BackgroundModelDownloader implements ModelDownloader {
  BackgroundModelDownloader({http.Client? client})
    : _client = client ?? http.Client() {
    final d = FileDownloader();
    d.configure(androidConfig: [(Config.runInForeground, Config.always)]);
    d.configureNotification(
      running: const TaskNotification('Dholu model', '{filename}  {progress}'),
      complete: const TaskNotification('Dholu model ready', '{filename}'),
      error: const TaskNotification('Download failed', 'Tap to retry in Dholu'),
      paused: const TaskNotification('Download paused', '{filename}'),
      progressBar: true,
    );
    d.registerCallbacks(
      taskStatusCallback: (u) {
        final st = switch (u.status) {
          TaskStatus.complete => DlState.complete,
          TaskStatus.failed || TaskStatus.notFound => DlState.failed,
          TaskStatus.canceled => DlState.canceled,
          TaskStatus.paused => DlState.paused,
          _ => DlState.running,
        };
        _ctrl.add(DlUpdate(u.task.taskId, st, error: u.exception?.description));
      },
      taskProgressCallback: (u) => _ctrl.add(
        DlUpdate(
          u.task.taskId,
          DlState.running,
          progress: u.progress.clamp(0.0, 1.0),
        ),
      ),
    );
    d.trackTasks();
  }

  final http.Client _client;
  final _ctrl = StreamController<DlUpdate>.broadcast();
  final Map<String, DownloadTask> _tasks = {};

  @override
  Stream<DlUpdate> get updates => _ctrl.stream;

  @override
  Future<Directory> modelsDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'models')).create(recursive: true);
  }

  @override
  Future<void> start(
    String taskId,
    String url,
    String fileName, {
    required bool wifiOnly,
  }) async {
    final task = DownloadTask(
      taskId: taskId,
      url: url,
      filename: '$fileName.part',
      directory: 'models',
      baseDirectory: BaseDirectory.applicationSupport,
      updates: Updates.statusAndProgress,
      requiresWiFi: wifiOnly,
      allowPause: true,
      retries: 5,
      displayName: fileName,
    );
    _tasks[taskId] = task;
    final ok = await FileDownloader().enqueue(task);
    if (!ok) {
      _ctrl.add(
        DlUpdate(taskId, DlState.failed, error: 'Could not start download'),
      );
    }
  }

  @override
  Future<void> pause(String taskId) async {
    final t = await _taskFor(taskId);
    if (t != null) {
      await FileDownloader().pause(t);
    }
  }

  @override
  Future<void> resume(String taskId) async {
    final t = await _taskFor(taskId);
    if (t != null) {
      await FileDownloader().resume(t);
    }
  }

  /// The task from this session, or one recovered from the downloader after an app restart.
  Future<DownloadTask?> _taskFor(String taskId) async {
    final t = _tasks[taskId] ?? await FileDownloader().taskForId(taskId);
    return t is DownloadTask ? t : null;
  }

  @override
  Future<void> cancel(String taskId) async {
    await FileDownloader().cancelTaskWithId(taskId);
  }

  @override
  Future<int?> remoteSize(String url) async {
    try {
      var uri = Uri.parse(url);
      for (var i = 0; i < 6; i++) {
        final req = http.Request('HEAD', uri)..followRedirects = false;
        final res = await _client
            .send(req)
            .timeout(const Duration(seconds: 15));
        if (res.isRedirect && res.headers['location'] != null) {
          uri = uri.resolve(res.headers['location']!);
          continue;
        }
        if (res.statusCode != 200) return null;
        final linked = int.tryParse(res.headers['x-linked-size'] ?? '');
        return linked ?? int.tryParse(res.headers['content-length'] ?? '');
      }
    } on Exception {
      return null;
    }
    return null;
  }
}

/// Install state for every model in the catalogue (+ one custom slot).
class ModelManager extends Notifier<Map<String, ModelInstall>> {
  late final ModelDownloader _dl = ref.read(modelDownloaderProvider);
  StreamSubscription<DlUpdate>? _sub;
  final Map<String, ModelSpec> _specs = {};
  final Map<String, int> _expected = {};

  @override
  Map<String, ModelInstall> build() {
    ref.onDispose(() => _sub?.cancel());
    _sub = _dl.updates.listen(_onUpdate);
    return const {};
  }

  /// Marks models whose files are already on disk as ready.
  Future<void> refresh({List<ModelSpec> specs = ModelCatalog.all}) async {
    final dir = await _dl.modelsDir();
    final next = Map<String, ModelInstall>.from(state);
    for (final s in specs) {
      _specs[s.id] = s;
      final f = File(p.join(dir.path, s.fileName));
      if (f.existsSync() && await isValidGguf(f)) {
        next[s.id] = ModelInstall(
          status: InstallStatus.ready,
          progress: 1,
          totalBytes: f.lengthSync(),
        );
      } else if (next[s.id]?.status == InstallStatus.ready) {
        next.remove(s.id);
      }
    }
    state = next;
  }

  Future<String?> installedPath(ModelSpec s) async {
    final f = File(p.join((await _dl.modelsDir()).path, s.fileName));
    return f.existsSync() && state[s.id]?.status == InstallStatus.ready
        ? f.path
        : null;
  }

  Future<int?> remoteSize(ModelSpec s) => _dl.remoteSize(s.url);

  /// Starts a download after checking the real remote size and free storage.
  Future<void> download(ModelSpec spec, {required int freeStorageMb}) async {
    _specs[spec.id] = spec;
    _set(spec.id, const ModelInstall(status: InstallStatus.downloading));
    final size = await _dl.remoteSize(spec.url);
    if (size == null) {
      return _fail(
        spec.id,
        'Could not reach the model server. Check internet and try again.',
      );
    }
    if (size < 50 * 1024 * 1024) {
      return _fail(
        spec.id,
        'The model file looks wrong (too small). It may have moved.',
      );
    }
    final needMb = (size / (1024 * 1024)).ceil() + 300;
    if (freeStorageMb < needMb) {
      return _fail(
        spec.id,
        'Not enough storage: needs ${(needMb / 1024).toStringAsFixed(1)} GB free.',
      );
    }
    _expected[spec.id] = size;
    _set(
      spec.id,
      ModelInstall(status: InstallStatus.downloading, totalBytes: size),
    );
    final wifi = ref.read(settingsProvider).wifiOnlyDownloads;
    await _dl.start(spec.id, spec.url, spec.fileName, wifiOnly: wifi);
  }

  Future<void> pause(String id) async {
    await _dl.pause(id);
    _set(
      id,
      (state[id] ?? const ModelInstall()).copyWith(
        status: InstallStatus.paused,
      ),
    );
  }

  Future<void> resume(String id) async {
    await _dl.resume(id);
    _set(
      id,
      (state[id] ?? const ModelInstall()).copyWith(
        status: InstallStatus.downloading,
      ),
    );
  }

  Future<void> cancel(String id) async {
    await _dl.cancel(id);
    final dir = await _dl.modelsDir();
    final spec = _specs[id];
    if (spec != null) {
      await _tryDelete(File(p.join(dir.path, '${spec.fileName}.part')));
    }
    _set(id, const ModelInstall());
  }

  Future<void> delete(ModelSpec spec) async {
    final dir = await _dl.modelsDir();
    await _tryDelete(File(p.join(dir.path, spec.fileName)));
    await _tryDelete(File(p.join(dir.path, '${spec.fileName}.part')));
    _set(spec.id, const ModelInstall());
  }

  Future<void> _onUpdate(DlUpdate u) async {
    final id = u.taskId;
    // After an app restart a download may still be running with no state in memory: adopt it.
    final cur =
        state[id] ??
        (ModelCatalog.byId(id) != null
            ? const ModelInstall(status: InstallStatus.downloading)
            : null);
    if (cur == null) {
      return;
    }
    switch (u.state) {
      case DlState.running:
        if (cur.status == InstallStatus.paused) return;
        _set(
          id,
          cur.copyWith(
            status: InstallStatus.downloading,
            progress: u.progress > 0 ? u.progress : cur.progress,
          ),
        );
      case DlState.paused:
        _set(id, cur.copyWith(status: InstallStatus.paused));
      case DlState.canceled:
        _set(id, const ModelInstall());
      case DlState.failed:
        _fail(id, u.error ?? 'Download failed. Tap retry.');
      case DlState.complete:
        await _finish(id);
    }
  }

  Future<void> _finish(String id) async {
    final spec = _specs[id] ?? ModelCatalog.byId(id);
    if (spec == null) {
      return;
    }
    _set(
      id,
      (state[id] ?? const ModelInstall()).copyWith(
        status: InstallStatus.verifying,
        progress: 1,
      ),
    );
    final dir = await _dl.modelsDir();
    final part = File(p.join(dir.path, '${spec.fileName}.part'));
    final done = File(p.join(dir.path, spec.fileName));
    if (part.existsSync()) {
      if (done.existsSync()) await done.delete();
      await part.rename(done.path);
    }
    final expected = _expected[id];
    final ok =
        done.existsSync() &&
        await isValidGguf(done) &&
        (expected == null || done.lengthSync() >= expected * 0.99);
    if (!ok) {
      await _tryDelete(done);
      return _fail(
        id,
        'The downloaded file is damaged. Please download again.',
      );
    }
    _set(
      id,
      ModelInstall(
        status: InstallStatus.ready,
        progress: 1,
        totalBytes: done.lengthSync(),
      ),
    );
  }

  void _fail(String id, String msg) =>
      _set(id, ModelInstall(status: InstallStatus.failed, error: msg));

  void _set(String id, ModelInstall v) => state = {...state, id: v};

  Future<void> _tryDelete(File f) async {
    try {
      if (f.existsSync()) await f.delete();
    } on FileSystemException {
      // ignore: nothing useful to do
    }
  }

  /// GGUF files start with the ASCII magic "GGUF".
  static Future<bool> isValidGguf(File f) async {
    try {
      final raf = await f.open();
      final head = await raf.read(4);
      await raf.close();
      return head.length == 4 && String.fromCharCodes(head) == 'GGUF';
    } on FileSystemException {
      return false;
    }
  }
}

final modelDownloaderProvider = Provider<ModelDownloader>(
  (_) => BackgroundModelDownloader(),
);
final modelManagerProvider =
    NotifierProvider<ModelManager, Map<String, ModelInstall>>(ModelManager.new);
