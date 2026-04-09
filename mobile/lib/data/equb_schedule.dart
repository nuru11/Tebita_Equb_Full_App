/// Parsed from GET /equbs/:id/rounds (member-safe: winner uses phoneMasked).
class EqubWinnerItem {
  const EqubWinnerItem({
    required this.roundNumber,
    required this.name,
    this.phoneMasked,
  });

  final int roundNumber;
  final String name;
  final String? phoneMasked;

  String get displayLine {
    final m = phoneMasked;
    if (m != null && m.isNotEmpty) {
      return '$name · $m';
    }
    return name;
  }
}

int _roundNum(Map<String, dynamic> r) => r['roundNumber'] as int? ?? 0;

/// Earliest active round due date (PENDING or COLLECTING), by round number order.
DateTime? parseNextRoundDueDate(List<Map<String, dynamic>> rounds) {
  final sorted = [...rounds]..sort((a, b) => _roundNum(a).compareTo(_roundNum(b)));
  for (final r in sorted) {
    final s = r['status'] as String?;
    if (s != 'PENDING' && s != 'COLLECTING') continue;
    final d = r['dueDate'];
    if (d == null) continue;
    final parsed = DateTime.tryParse(d.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

/// Completed / drawn rounds with a winner, sorted by round number ascending.
List<EqubWinnerItem> parseWinnersFromRounds(List<Map<String, dynamic>> rounds) {
  final sorted = [...rounds]..sort((a, b) => _roundNum(a).compareTo(_roundNum(b)));
  final out = <EqubWinnerItem>[];
  for (final r in sorted) {
    final s = r['status'] as String?;
    if (s != 'DRAWN' && s != 'COMPLETED') continue;
    final w = r['winner'] as Map<String, dynamic>?;
    if (w == null) continue;
    final u = w['user'] as Map<String, dynamic>?;
    final name = (u?['fullName'] as String?)?.trim();
    final masked = u?['phoneMasked'] as String?;
    out.add(
      EqubWinnerItem(
        roundNumber: _roundNum(r),
        name: (name != null && name.isNotEmpty) ? name : 'Winner',
        phoneMasked: masked,
      ),
    );
  }
  return out;
}

String formatScheduleDate(DateTime d) {
  final local = d.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// One-line summary: latest round winner (highest round number).
String? lastWinnerSummaryLine(List<Map<String, dynamic>> rounds) {
  final items = parseWinnersFromRounds(rounds);
  if (items.isEmpty) return null;
  final last = items.last;
  return 'Round ${last.roundNumber} · ${last.displayLine}';
}
