part of game;

class GameObjectFactory {
  GameObjectFactory(this.sheet, this.sounds, this.level, this.playerState);

  SpriteSheet sheet;
  SoundAssets sounds;
  Level level;
  PlayerState playerState;

  void addAsteroids(int level, double yPos) {
    int numAsteroids = 10 + level * 4;
    double distribution = (level * 0.2).clamp(0.0, 0.8);

    for (int i = 0; i < numAsteroids; i++) {
      GameObject obj;
      if (i == 0)
        obj = new AsteroidPowerUp(this);
      else if (randomDouble() < distribution)
        obj = new AsteroidBig(this);
      else
        obj = new AsteroidSmall(this);

      Point pos = new Point(randomSignedDouble() * 160.0,
                            yPos + _chunkSpacing * randomDouble());
      addGameObject(obj, pos);
    }
  }

  void addEnemyScoutSwarm(int level, double yPos) {
    int numEnemies = (3 + level * 3).clamp(0, 12);
    List<int> types;
    if (level == 0) types = [0, 0, 0];
    else if (level == 1) types = [0, 1, 0];
    else if (level == 2) types = [1, 0, 1];
    else if (level == 3) types = [1, 1, 1];
    else if (level == 4) types = [0, 1, 2];
    else if (level == 5) types = [1, 2, 1];
    else if (level == 6) types = [2, 1, 2];
    else if (level == 7) types = [2, 1, 2];
    else if (level == 8) types = [2, 2, 2];

    for (int i = 0; i < numEnemies; i++) {
      int type = types[i % 3];
      double spacing = math.max(_chunkSpacing / (numEnemies + 1.0), 80.0);
      double y = yPos + _chunkSpacing / 2.0 - (numEnemies - 1) * spacing / 2.0 + i * spacing;
      addGameObject(new EnemyScout(this, type), new Point(0.0, y));
    }
  }

  void addEnemyDestroyerSwarm(int level, double yPos) {
    int numEnemies = (2 + level).clamp(2, 10);
    List<int> types;
    if (level == 0) types = [0, 0, 0];
    else if (level == 1) types = [0, 1, 0];
    else if (level == 2) types = [1, 0, 1];
    else if (level == 3) types = [1, 1, 1];
    else if (level == 4) types = [0, 1, 2];
    else if (level == 5) types = [1, 2, 1];
    else if (level == 6) types = [2, 1, 2];
    else if (level == 7) types = [2, 1, 2];
    else if (level == 8) types = [2, 2, 2];

    for (int i = 0; i < numEnemies; i++) {
      int type = types[i % 3];
      addGameObject(new EnemyDestroyer(this, type), new Point(randomSignedDouble() * 120.0 , yPos + _chunkSpacing * randomDouble()));
    }
  }

  void addGameObject(GameObject obj, Point pos) {
    obj.position = pos;
    obj.setupActions();

    level.addChild(obj);
  }

  void addBossFight(int l, double yPos) {
    // Add boss
    EnemyBoss boss = new EnemyBoss(this, l);
    Point pos = new Point(0.0, yPos + _chunkSpacing / 2.0);

    addGameObject(boss, pos);

    playerState.boss = boss;

    int destroyerLevel = (l - 1 ~/ 3).clamp(0, 2);

    // Add boss's helpers
    if (l >= 1) {
      EnemyDestroyer destroyer0 = new EnemyDestroyer(this, destroyerLevel);
      addGameObject(destroyer0, new Point(-80.0, yPos + _chunkSpacing / 2.0 + 70.0));

      EnemyDestroyer destroyer1 = new EnemyDestroyer(this, destroyerLevel);
      addGameObject(destroyer1, new Point(80.0, yPos + _chunkSpacing / 2.0 + 70.0));

      if (l >= 2) {
        EnemyDestroyer destroyer0 = new EnemyDestroyer(this, destroyerLevel);
        addGameObject(destroyer0, new Point(-80.0, yPos + _chunkSpacing / 2.0 - 70.0));

        EnemyDestroyer destroyer1 = new EnemyDestroyer(this, destroyerLevel);
        addGameObject(destroyer1, new Point(80.0, yPos + _chunkSpacing / 2.0 - 70.0));
      }
    }
  }
}

final List<Color> laserColors = <Color>[
  new Color(0xff95f4fb),
  new Color(0xff5bff35),
  new Color(0xffff886c),
  new Color(0xffffd012),
  new Color(0xfffd7fff)
];

void addLaserSprites(Node node, int level, double r, SpriteSheet sheet) {
  int numLasers = level % 3 + 1;
  Color laserColor = laserColors[(level ~/ 3) % laserColors.length];

  // Add sprites
  List<Sprite> sprites = <Sprite>[];
  for (int i = 0; i < numLasers; i++) {
    Sprite sprite = new Sprite(sheet["explosion_particle.png"]);
    sprite.scale = 0.5;
    sprite.colorOverlay = laserColor;
    sprite.transferMode = ui.TransferMode.plus;
    node.addChild(sprite);
    sprites.add(sprite);
  }

  // Position the individual sprites
  if (numLasers == 2) {
    sprites[0].position = new Point(-3.0, 0.0);
    sprites[1].position = new Point(3.0, 0.0);
  } else if (numLasers == 3) {
    sprites[0].position = new Point(-4.0, 0.0);
    sprites[1].position = new Point(4.0, 0.0);
    sprites[2].position = new Point(0.0, -2.0);
  }
}
