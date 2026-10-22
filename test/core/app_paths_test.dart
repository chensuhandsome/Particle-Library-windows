import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/core/app_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed resolution is not remembered, a successful one is', () async {
    final first = appSupportDirectory();
    Object? failure;
    try {
      await first;
    } catch (error) {
      failure = error;
    }
    if (failure == null) {
      // The platform resolved the directory: it is cached for the process.
      expect(identical(appSupportDirectory(), first), isTrue);
      return;
    }
    // path_provider is not available in this test environment, so the first
    // resolution failed. Retrying must start a new attempt instead of handing
    // back the failed future (the boot screen's Retry depends on it).
    final second = appSupportDirectory();
    expect(identical(second, first), isFalse);
    await second.then<void>((_) {}, onError: (Object _) {});
  });
}
