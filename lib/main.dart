// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

import 'game_demo.dart';

final Color _darkTextColor = new Color(0xff3c3f4a);

typedef void SelectTabCallback(int index);
typedef void UpgradePowerUpCallback(PowerUpType type);

AssetBundle _initBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(new Uri.directory(Uri.base.origin));
}

final AssetBundle _bundle = _initBundle();

ImageMap _imageMap;
SpriteSheet _spriteSheet;
SpriteSheet _spriteSheetUI;
Map<String, SoundEffect> _sounds = <String, SoundEffect>{};

main() async {
  activity.setSystemUiVisibility(SystemUiVisibility.IMMERSIVE);

  _imageMap = new ImageMap(_bundle);

  // Use a list to wait on all loads in parallel just before starting the app.
  List loads = [];

  loads.add(_imageMap.load(<String>[
    'assets/nebula.png',
    'assets/sprites.png',
    'assets/starfield.png',
    'assets/game_ui.png',
    'assets/ui_bg_top.png',
    'assets/ui_bg_bottom.png',
    'assets/ui_popup.png',
  ]));

  // TODO(eseidel): SoundEffect doesn't really do anything except hold a future.
  _sounds['explosion_0'] = new SoundEffect(_bundle.load('assets/explosion_0.wav'));
  _sounds['explosion_1'] = new SoundEffect(_bundle.load('assets/explosion_1.wav'));
  _sounds['explosion_2'] = new SoundEffect(_bundle.load('assets/explosion_2.wav'));
  _sounds['explosion_boss'] = new SoundEffect(_bundle.load('assets/explosion_boss.wav'));
  _sounds['explosion_player'] = new SoundEffect(_bundle.load('assets/explosion_player.wav'));
  _sounds['laser'] = new SoundEffect(_bundle.load('assets/laser.wav'));
  _sounds['hit'] = new SoundEffect(_bundle.load('assets/hit.wav'));
  _sounds['levelup'] = new SoundEffect(_bundle.load('assets/levelup.wav'));
  _sounds['pickup_0'] = new SoundEffect(_bundle.load('assets/pickup_0.wav'));
  _sounds['pickup_1'] = new SoundEffect(_bundle.load('assets/pickup_1.wav'));
  _sounds['pickup_2'] = new SoundEffect(_bundle.load('assets/pickup_2.wav'));
  _sounds['pickup_powerup'] = new SoundEffect(_bundle.load('assets/pickup_powerup.wav'));
  _sounds['click'] = new SoundEffect(_bundle.load('assets/click.wav'));
  _sounds['buy_upgrade'] = new SoundEffect(_bundle.load('assets/buy_upgrade.wav'));

  loads.addAll([
    _sounds['explosion_0'].load(),
    _sounds['explosion_1'].load(),
    _sounds['explosion_2'].load(),
    _sounds['explosion_boss'].load(),
    _sounds['explosion_player'].load(),
    _sounds['laser'].load(),
    _sounds['hit'].load(),
    _sounds['levelup'].load(),
    _sounds['pickup_0'].load(),
    _sounds['pickup_1'].load(),
    _sounds['pickup_2'].load(),
    _sounds['pickup_powerup'].load(),
    _sounds['click'].load(),
    _sounds['buy_upgrade'].load(),
  ]);

  await Future.wait(loads);

  // TODO(eseidel): These load in serial which is bad for startup!
  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_imageMap['assets/sprites.png'], json);

  json = await _bundle.loadString('assets/game_ui.json');
  _spriteSheetUI = new SpriteSheet(_imageMap['assets/game_ui.png'], json);

  assert(_spriteSheet.image != null);

  SoundTrackPlayer stPlayer = SoundTrackPlayer.sharedInstance();
  SoundTrack music = await stPlayer.load(_bundle.load('assets/music_game.mp3'));
  stPlayer.play(music);

  runApp(new GameDemo());
}

class GameRoute extends PageRoute {
  GameRoute(this.builder);
  final WidgetBuilder builder;
  Duration get transitionDuration => const Duration(milliseconds: 1000);
  Color get barrierColor => null;
  Widget buildPage(BuildContext context, PerformanceView performance, PerformanceView forwardPerformance) {
    return builder(context);
  }
  Widget buildTransition(BuildContext context, PerformanceView performance, Widget child) {
    return new FadeTransition(
      performance: performance,
      opacity: new AnimatedValue<double>(
        0.0,
        end: 1.0,
        curve: new Interval(0.5, 1.0, curve: Curves.ease)
      ),
      child: child
    );
  }
  Widget buildForwardTransition(BuildContext context, PerformanceView performance, Widget child) {
    return new FadeTransition(
      performance: performance,
      opacity: new AnimatedValue<double>(
        1.0,
        end: 0.0,
        curve: new Interval(0.0, 0.5, curve: Curves.ease)
      ),
      child: child
    );
  }
}

class GameDemo extends StatefulComponent {
  GameDemoState createState() => new GameDemoState();
}

class GameDemoState extends State<GameDemo> {
  PersistantGameState _gameState;

  void initState() {
    super.initState();

    _gameState = new PersistantGameState();
  }

  Widget build(BuildContext context) {
    return new Title(
      title: 'Asteroids',
      color: const Color(0xFF9900FF),
      child: new Navigator(
        onGenerateRoute: (NamedRouteSettings settings) {
          switch (settings.name) {
            case '/game': return _buildGameSceneRoute();
            default: return _buildMainSceneRoute();
          }
        }
      )
    );
  }

  GameRoute _buildGameSceneRoute() {
    return new GameRoute((BuildContext context) {
      return new GameScene(
        onGameOver: (int lastScore, int coins) {
          setState(() {
            _gameState.lastScore = lastScore;
            _gameState.coins += coins;
          });
        },
        gameState: _gameState
      );
    });
  }

  GameRoute _buildMainSceneRoute() {
    return new GameRoute((BuildContext context) {
      return new MainScene(
        gameState: _gameState,
        onUpgradePowerUp: (PowerUpType type) {
          setState(() {
            _gameState.upgradePowerUp(type);
          });
        },
        onUpgradeLaser: () {
          setState(() {
            _gameState.upgradeLaser();
          });
        },
        onStartLevelUp: () {
          setState(() {
            _gameState.currentStartingLevel++;
          });
        },
        onStartLevelDown: () {
          setState(() {
            _gameState.currentStartingLevel--;
          });
        }
      );
    });
  }
}

class GameScene extends StatefulComponent {
  GameScene({this.onGameOver, this.gameState});

  final GameOverCallback onGameOver;
  final PersistantGameState gameState;

  State<GameScene> createState() => new GameSceneState();
}

class GameSceneState extends State<GameScene> {
  NodeWithSize _game;

  void initState() {
    super.initState();

    _game = new GameDemoNode(
      _imageMap,
      _spriteSheet,
      _spriteSheetUI,
      _sounds,
      config.gameState,
      (int score, int coins) {
        Navigator.pop(context);
        config.onGameOver(score, coins);
      }
    );
  }

  Widget build(BuildContext context) {
    return new SpriteWidget(_game, SpriteBoxTransformMode.fixedWidth);
  }
}

class MainScene extends StatefulComponent {
  MainScene({
    this.gameState,
    this.onUpgradePowerUp,
    this.onUpgradeLaser,
    this.onStartLevelUp,
    this.onStartLevelDown
  });

  final PersistantGameState gameState;
  final UpgradePowerUpCallback onUpgradePowerUp;
  final VoidCallback onUpgradeLaser;
  final VoidCallback onStartLevelUp;
  final VoidCallback onStartLevelDown;

  State<MainScene> createState() => new MainSceneState();
}

class MainSceneState extends State<MainScene> {

  TabBarSelection _tabSelection;

  void initState() {
    super.initState();

    _tabSelection = new TabBarSelection(index: 0);
  }

  Widget build(BuildContext context) {
    return new CoordinateSystem(
      systemSize: new Size(320.0, 320.0),
      child:new DefaultTextStyle(
        style: new TextStyle(fontSize:20.0),
        child: new Stack(<Widget>[
          new MainSceneBackground(),
          new Column(<Widget>[
            new SizedBox(
              width: 320.0,
              height: 108.0,
              child: new TopBar(
                onSelectTab: (int tab) {
                  setState(() => _tabSelection.index = tab);
                },
                selection: _tabSelection,
                gameState: config.gameState
              )
            ),
            new Flexible(
              child: new CenterArea(
                selection: _tabSelection,
                onUpgradeLaser: config.onUpgradeLaser,
                onUpgradePowerUp: config.onUpgradePowerUp,
                gameState: config.gameState
              )
            ),
            new SizedBox(
              width: 320.0,
              height: 93.0,
              child: new BottomBar(
                onPlay: () {
                  Navigator.pushNamed(context, '/game');
                },
                onStartLevelUp: config.onStartLevelUp,
                onStartLevelDown: config.onStartLevelDown,
                gameState: config.gameState
              )
            )
          ])
        ])
      )
    );
  }
}

class TopBar extends StatelessComponent {
  TopBar({this.selection, this.onSelectTab, this.gameState});

  final TabBarSelection selection;
  final SelectTabCallback onSelectTab;
  final PersistantGameState gameState;

  Widget build(BuildContext context) {

    TextStyle scoreLabelStyle = new TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w500,
      color: _darkTextColor
    );

    return new Stack([
      new Positioned(
        left: 10.0,
        top: 6.0,
        child: new TextureImage(
          texture: _spriteSheetUI['player_icon.png'],
          width: 44.0,
          height: 44.0
        )
      ),
      new Positioned(
        left: 64.0,
        top: 6.0,
        child: new Text(
          "Last Score:",
          style: scoreLabelStyle
        )
      ),
      new Positioned(
        left: 64.0,
        top: 28.0,
        child: new Text(
          "Weekly Best:",
          style: scoreLabelStyle
        )
      ),
      new Positioned(
        right: 10.0,
        top: 6.0,
        child: new Text(
          "${gameState.lastScore}",
          style: scoreLabelStyle
        )
      ),
      new Positioned(
        right: 10.0,
        top: 28.0,
        child: new Text(
          "${gameState.weeklyBestScore}",
          style: scoreLabelStyle
        )
      ),
      _buildTabButton("Upgrades", 0),
      _buildTabButton("Friend Scores", 1),
      _buildTabButton("World Scores", 2),
      new Positioned(
        left: 10.0,
        top: 87.0,
        child: new TextureImage(
          texture: _spriteSheetUI['icn_crystal.png'],
          width: 12.0,
          height: 18.0
        )
      ),
      new Positioned(
        left: 28.0,
        top: 87.0,
        child: new Text(
          "${gameState.coins}",
          style: new TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: _darkTextColor
          )
        )
      )
    ]);
  }

  Widget _buildTabButton(String title, int index) {
    TextAlign textAlign = TextAlign.center;
    if (index == 0) textAlign = TextAlign.left;
    else if (index == 2) textAlign = TextAlign.right;

    TextStyle textStyle = null;
    if (index == selection.index) {
      textStyle = new TextStyle(
        fontWeight: FontWeight.w700,
        textAlign: textAlign,
        fontSize: 14.0,
        color: _darkTextColor
      );
    } else {
      textStyle = new TextStyle(
        fontWeight: FontWeight.w400,
        textAlign: textAlign,
        fontSize: 14.0,
        color: _darkTextColor
      );
    }

    return new Positioned(
      left: 10.0 + index * 100.0,
      top: 56.0,
      child: new TextureButton(
        texture: null,
        textStyle: textStyle,
        label: title,
        onPressed: () => onSelectTab(index),
        width: 100.0,
        height: 25.0
      )
    );
  }
}

class CenterArea extends StatelessComponent {

  CenterArea({
    this.selection,
    this.onUpgradeLaser,
    this.gameState,
    this.onUpgradePowerUp
  });

  final TabBarSelection selection;
  final VoidCallback onUpgradeLaser;
  final UpgradePowerUpCallback onUpgradePowerUp;
  final PersistantGameState gameState;

  Widget build(BuildContext context) {
    return _buildCenterArea();
  }

  Widget _buildCenterArea() {
    return new TabBarView(
      items: <int>[0, 1, 2],
      itemExtent: 320.0,
      selection: selection,
      itemBuilder: (BuildContext context, int item, int index) {
        if (item == 0)
          return _buildUpgradePanel();
        else if (item == 1)
          return _buildFriendScorePanel();
        else if (item == 2)
          return _buildWorldScorePanel();
      }
    );
  }

  Widget _buildUpgradePanel() {
    return new Column(<Widget>[
        new Text("Upgrade Laser"),
        _buildLaserUpgradeButton(),
        new Text("Upgrade Power-Ups"),
        new Row(<Widget>[
            _buildPowerUpButton(PowerUpType.shield),
            _buildPowerUpButton(PowerUpType.sideLaser),
            _buildPowerUpButton(PowerUpType.speedBoost),
            _buildPowerUpButton(PowerUpType.speedLaser),
          ],
        justifyContent: FlexJustifyContent.center)
      ],
      justifyContent: FlexJustifyContent.center,
      key: new Key("upgradePanel")
    );
  }

  Widget _buildFriendScorePanel() {
    return new ScorePanel(key: new Key("friendScorePanel"));
  }

  Widget _buildWorldScorePanel() {
    return new ScorePanel(key: new Key("worldScorePanel"));
  }

  Widget _buildPowerUpButton(PowerUpType type) {
    return new Padding(
      padding: new EdgeDims.all(8.0),
      child: new Column([
        new TextureButton(
          texture: _spriteSheetUI['btn_powerup_${type.index}.png'],
          width: 57.0,
          height: 57.0,
          label: "${gameState.powerUpUpgradePrice(type)}",
          labelOffset: new Offset(0.0, 19.0),
          textStyle: new TextStyle(
            fontSize: 13.0,
            textAlign: TextAlign.center,
            color: _darkTextColor
          ),
          onPressed: () => onUpgradePowerUp(type)
        ),
        new Padding(
          padding: new EdgeDims.all(5.0),
          child: new Text(
            "Lvl ${gameState.powerupLevel(type) + 1}",
            style: new TextStyle(fontSize: 15.0)
          )
        )
      ])
    );
  }

  Widget _buildLaserUpgradeButton() {
    return new Padding(
      padding: new EdgeDims.TRBL(8.0, 0.0, 18.0, 0.0),
      child: new Stack([
        new TextureButton(
          texture: _spriteSheetUI['btn_laser_upgrade.png'],
          width: 137.0,
          height: 63.0,
          label: "${gameState.laserUpgradePrice()}",
          labelOffset: new Offset(0.0, 19.0),
          textStyle: new TextStyle(
            fontSize: 13.0,
            textAlign: TextAlign.center,
            color: _darkTextColor
          ),
          onPressed: onUpgradeLaser
        ),
        new Positioned(
          child: new LaserDisplay(level: gameState.laserLevel),
          left: 19.5,
          top: 14.0
        ),
        new Positioned(
          child: new LaserDisplay(level: gameState.laserLevel + 1),
          right: 19.5,
          top: 14.0
        )
      ])
    );
  }
}

class ScorePanel extends StatelessComponent {
  ScorePanel({
    Key key
  }) : super(key: key);

  Widget build(BuildContext context) {
    return new ScrollableList<int>(
      items: <int>[0, 1, 2],
      itemBuilder: _itemBuilder,
      itemExtent: 64.0
    );
  }

  Widget _itemBuilder(BuildContext context, int item, int index) {
    return new Stack(
      [
        new Positioned(
          left: 0.0,
          top: 0.0,
          child: new Container(
            width: 320.0,
            height: 63.0,
            foregroundDecoration: new BoxDecoration(
              backgroundColor: new Color(0x33000000)
            )
          )
        ),
        new Positioned(
          left: 10.0,
          top: 10.0,
          child: new TextureImage(
            texture: _spriteSheetUI['player_icon.png'],
            width: 44.0,
            height: 44.0
          )
        ),
        new Positioned(
          left: 70.0,
          top: 12.0,
          child: new Text(
            "Player Name $index",
            style: new TextStyle(fontSize: 18.0)
          )
        ),
        new Positioned(
          left: 70.0,
          bottom: 12.0,
          child: new Text(
            "${(index + 1) * 25428}",
            style: new TextStyle(fontSize: 16.0)
          )
        )
      ],
      key: new Key("$index")
    );
  }
}

class BottomBar extends StatelessComponent {

  BottomBar({this.onPlay, this.gameState, this.onStartLevelUp, this.onStartLevelDown});

  final VoidCallback onPlay;
  final VoidCallback onStartLevelUp;
  final VoidCallback onStartLevelDown;
  final PersistantGameState gameState;

  Widget build(BuildContext context) {
    return new Stack([
      new Positioned(
        left: 18.0,
        top: 14.0,
        child: new TextureImage(
          texture: _spriteSheetUI['level_display.png'],
          width: 62.0,
          height: 62.0
        )
      ),
      new Positioned(
        left: 18.0,
        top: 14.0,
        child: new TextureImage(
          texture: _spriteSheetUI['level_display_${gameState.currentStartingLevel + 1}.png'],
          width: 62.0,
          height: 62.0
        )
      ),
      new Positioned(
        left: 85.0,
        top: 14.0,
        child: new TextureButton(
          texture: _spriteSheetUI['btn_level_up.png'],
          width: 30.0,
          height: 30.0,
          onPressed: onStartLevelUp
        )
      ),
      new Positioned(
        left: 85.0,
        top: 46.0,
        child: new TextureButton(
          texture: _spriteSheetUI['btn_level_down.png'],
          width: 30.0,
          height: 30.0,
          onPressed: onStartLevelDown
        )
      ),
      new Positioned(
        left: 120.0,
        top: 14.0,
        child: new TextureButton(
          onPressed: onPlay,
          texture: _spriteSheetUI['btn_play.png'],
          label: "PLAY",
          width: 181.0,
          height: 62.0
        )
      )
    ]);
  }
}

class MainSceneBackground extends StatefulComponent {
  MainSceneBackgroundState createState() => new MainSceneBackgroundState();
}

class MainSceneBackgroundState extends State<MainSceneBackground> {
  MainSceneBackgroundNode _backgroundNode;

  void initState() {
    super.initState();
    _backgroundNode = new MainSceneBackgroundNode();
  }

  Widget build(BuildContext context) {
    return new SpriteWidget(_backgroundNode, SpriteBoxTransformMode.fixedWidth);
  }
}

class MainSceneBackgroundNode extends NodeWithSize {
  Sprite _bgTop;
  Sprite _bgBottom;
  RepeatedImage _background;
  RepeatedImage _nebula;

  MainSceneBackgroundNode() : super(new Size(320.0, 320.0)) {
    assert(_spriteSheet.image != null);

    // Add background
    _background = new RepeatedImage(_imageMap["assets/starfield.png"]);
    addChild(_background);

    StarField starField = new StarField(_spriteSheet, 200, true);
    addChild(starField);

    // Add nebula
    _nebula = new RepeatedImage(_imageMap["assets/nebula.png"], TransferMode.plus);
    addChild(_nebula);

    _bgTop = new Sprite.fromImage(_imageMap["assets/ui_bg_top.png"]);
    _bgTop.pivot = Point.origin;
    _bgTop.size = new Size(320.0, 108.0);
    addChild(_bgTop);

    _bgBottom = new Sprite.fromImage(_imageMap["assets/ui_bg_bottom.png"]);
    _bgBottom.pivot = new Point(0.0, 1.0);
    _bgBottom.size = new Size(320.0, 97.0);
    addChild(_bgBottom);
  }

  void paint(Canvas canvas) {
    canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, 320.0, 320.0), new Paint()..color=new Color(0xff000000));
    super.paint(canvas);
  }

  void spriteBoxPerformedLayout() {
    _bgBottom.position = new Point(0.0, spriteBox.visibleArea.size.height);
  }

  void update(double dt) {
    _background.move(10.0 * dt);
    _nebula.move(100.0 * dt);
  }
}

class LaserDisplay extends StatelessComponent {
  LaserDisplay({this.level});

  final int level;

  Widget build(BuildContext context) {
    return new SizedBox(
      child: new SpriteWidget(new LaserDisplayNode(level)),
      width: 26.0,
      height: 26.0
    );
  }
}

class LaserDisplayNode extends NodeWithSize {
  LaserDisplayNode(int level): super(new Size(16.0, 16.0)) {
    Node placementNode = new Node();
    placementNode.position = new Point(8.0, 8.0);
    placementNode.scale = 0.7;
    addChild(placementNode);
    addLaserSprites(placementNode, level, 0.0, _spriteSheet);
  }
}
