import 'package:en_passant/model/player.dart';
import 'package:flutter/cupertino.dart';

import 'picker.dart';

export 'package:en_passant/model/player.dart' show Player;
class SidePicker extends StatelessWidget {
  final Map<Player, Text> colorOptions = const <Player, Text>{
    Player.player1: Text('White'),
    Player.player2: Text('Black'),
    Player.random: Text('Random')
  };

  final Player playerSide;
  final Function(Player?) setFunc;
  
  SidePicker(this.playerSide, this.setFunc);

  @override
  Widget build(BuildContext context) {
    return Picker<Player>(
      label: 'Side',
      options: colorOptions,
      selection: playerSide,
      setFunc: setFunc,
    );
  }
}
