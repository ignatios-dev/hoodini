enum HoodLevel {
  ghost,      // 0 XP
  rookie,     // 10 XP
  explorer,   // 50 XP
  streetwise, // 150 XP
  blockboss,  // 400 XP
  legend,     // 1000 XP
  hoodini,    // 2500 XP
}

extension HoodLevelInfo on HoodLevel {
  String get title => switch (this) {
        HoodLevel.ghost => 'Ghost',
        HoodLevel.rookie => 'Rookie',
        HoodLevel.explorer => 'Explorer',
        HoodLevel.streetwise => 'Street Wise',
        HoodLevel.blockboss => 'Block Boss',
        HoodLevel.legend => 'Hood Legend',
        HoodLevel.hoodini => 'The Hoodini',
      };

  int get minXp => switch (this) {
        HoodLevel.ghost => 0,
        HoodLevel.rookie => 10,
        HoodLevel.explorer => 50,
        HoodLevel.streetwise => 150,
        HoodLevel.blockboss => 400,
        HoodLevel.legend => 1000,
        HoodLevel.hoodini => 2500,
      };

  int get index2 => HoodLevel.values.indexOf(this);
}

class PlayerLevel {
  const PlayerLevel(this.xp);
  final int xp;

  HoodLevel get level {
    for (final lvl in HoodLevel.values.reversed) {
      if (xp >= lvl.minXp) return lvl;
    }
    return HoodLevel.ghost;
  }

  String get title => level.title;
  int get levelIndex => level.index2;

  int get xpForNext {
    final values = HoodLevel.values;
    final current = level;
    final nextIdx = current.index2 + 1;
    if (nextIdx >= values.length) return xp;
    return values[nextIdx].minXp;
  }

  double get progressToNext {
    final values = HoodLevel.values;
    final current = level;
    final nextIdx = current.index2 + 1;
    if (nextIdx >= values.length) return 1.0;
    final currentMin = current.minXp;
    final nextMin = values[nextIdx].minXp;
    return (xp - currentMin) / (nextMin - currentMin);
  }

  static HoodLevel levelFromXp(int xp) => PlayerLevel(xp).level;
}
