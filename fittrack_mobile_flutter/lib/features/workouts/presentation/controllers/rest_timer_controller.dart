import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerController extends Notifier<Duration> {
  Timer? _timer;
  @override
  Duration build() {
    ref.onDispose(() => _timer?.cancel());
    return Duration.zero;
  }

  void start(Duration duration) {
    _timer?.cancel();
    state = duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == Duration.zero) {
        timer.cancel();
      } else {
        state -= const Duration(seconds: 1);
      }
    });
  }

  void pause() => _timer?.cancel();
  void adjust(int seconds) =>
      state = Duration(seconds: (state.inSeconds + seconds).clamp(0, 3600));
}

final restTimerProvider =
    NotifierProvider<RestTimerController, Duration>(RestTimerController.new);
