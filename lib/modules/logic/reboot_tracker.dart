/// ADB identity is only accepted when explicitly known before reboot.
class RebootTracker {
  final Set<String> _expected = {};
  final Set<String> _seenAbsent = {};
  bool hasUnknown = false;

  void expect(String serial, Set<String> currentlyOnline) {
    if (serial.isEmpty) {
      hasUnknown = true;
      return;
    }
    _expected.add(serial);
    if (!currentlyOnline.contains(serial)) _seenAbsent.add(serial);
  }

  Set<String> observe(Set<String> online) {
    _seenAbsent.addAll(_expected.difference(online));
    final confirmed = _expected.intersection(_seenAbsent).intersection(online);
    _expected.removeAll(confirmed);
    _seenAbsent.removeAll(confirmed);
    return confirmed;
  }

  void clear() {
    _expected.clear();
    _seenAbsent.clear();
    hasUnknown = false;
  }
}
