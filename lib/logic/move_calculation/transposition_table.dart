import 'move_classes/move.dart';

const int TT_SIZE = 1 << 20; // ~1 million entries
const int TT_MASK = TT_SIZE - 1;

// Flag types for transposition table entries
const int TT_EXACT = 0;
const int TT_ALPHA = 1; // Upper bound (failed low)
const int TT_BETA = 2; // Lower bound (failed high)

class TTEntry {
  int key = 0;
  int depth = 0;
  int value = 0;
  int flag = 0;
  Move? bestMove;
}

class TranspositionTable {
  final List<TTEntry?> _table = List.filled(TT_SIZE, null);

  TTEntry? probe(int hash) {
    var entry = _table[hash & TT_MASK];
    if (entry != null && entry.key == hash) {
      return entry;
    }
    return null;
  }

  void store(int hash, int depth, int value, int flag, Move? bestMove) {
    var index = hash & TT_MASK;
    var entry = _table[index];
    
    if (entry == null) {
      entry = TTEntry();
      _table[index] = entry;
    }
    
    // Always replace if new entry is deeper or same position
    if (entry.key != hash || depth >= entry.depth) {
      entry.key = hash;
      entry.depth = depth;
      entry.value = value;
      entry.flag = flag;
      entry.bestMove = bestMove;
    }
  }

  void clear() {
    _table.fillRange(0, TT_SIZE, null);
  }
}
