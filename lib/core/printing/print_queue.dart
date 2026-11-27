import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrintQueue {
  Future<void> _last = Future<void>.value();

  Future<void> add(Future<void> Function() job) {
    final next = _last.then((_) => job());
    _last = next.then((_) {}, onError: (Object _) {});
    return next;
  }
}

final printQueueProvider = Provider<PrintQueue>((ref) => PrintQueue());
