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

typedef void SelectTabCallback(int index);

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

PersistantGameState _gameState = new PersistantGameState();

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
  GameRoute(this.child);
  final Widget child;
  Duration get transitionDuration => const Duration(milliseconds: 1000);
  Color get barrierColor => null;
  Widget buildPage(BuildContext context, PerformanceView performance, PerformanceView forwardPerformance) => child;
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
  Widget build(BuildContext context) {
    return new Title(
      title: 'Asteroids',
      color: const Color(0xFF9900FF),
      child: new Navigator(
        onGenerateRoute: (NamedRouteSettings settings) {
          switch (settings.name) {
            case '/game': return new GameRoute(new GameScene());
            default:      return new GameRoute(new MainScene());
          }
        }
      )
    );
  }
}

class GameScene extends StatefulComponent {
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
      (int lastScore) {
        setState(() { _gameState.lastScore = lastScore; });
        Navigator.pop(context);
      }
    );
  }

  Widget build(BuildContext context) {
    return new SpriteWidget(_game, SpriteBoxTransformMode.fixedWidth);
  }
}

class MainScene extends StatefulComponent {
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
          new SpriteWidget(new MainScreenBackground(), SpriteBoxTransformMode.fixedWidth),
          new Column(<Widget>[
            new SizedBox(
              width: 320.0,
              height: 108.0,
              child: new TopBar(
                onSelectTab: (int tab) {
                  setState(() => _tabSelection.index = tab);
                },
                selection: _tabSelection
              )
            ),
            new Flexible(
              child: new CenterArea(
                selection: _tabSelection,
                onUpgradeLaser: null
              )
            ),
            new SizedBox(
              width: 320.0,
              height: 93.0,
              child: new BottomBar(
                onPlay: () {
                  Navigator.pushNamed(context, '/game');
                }
              )
            )
          ])
        ])
      )
    );
  }
}

class TopBar extends StatelessComponent {
  TopBar({this.selection, this.onSelectTab});

  final TabBarSelection selection;
  final SelectTabCallback onSelectTab;

  Widget build(BuildContext context) {
    return new Stack([
      _buildTabButton("Upgrades", 0),
      _buildTabButton("Friend Scores", 1),
      _buildTabButton("World Scores", 2),
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
        fontSize: 14.0
      );
    } else {
      textStyle = new TextStyle(
        fontWeight: FontWeight.w400,
        textAlign: textAlign,
        fontSize: 14.0
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

  CenterArea({this.selection, this.onUpgradeLaser});

  final TabBarSelection selection;
  final VoidCallback onUpgradeLaser;

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
          height: 57.0
        ),
        new Padding(
          padding: new EdgeDims.all(5.0),
          child: new Text(
            "Lvl ${_gameState.powerupLevel(type) + 1}",
            style: new TextStyle(fontSize: 15.0)
          )
        )
      ])
    );
  }

  Widget _buildLaserUpgradeButton() {
    return new Padding(
      padding: new EdgeDims.TRBL(8.0, 0.0, 18.0, 0.0),
      child: new TextureButton(
        texture: _spriteSheetUI['btn_laser_upgrade.png'],
        width: 137.0,
        height: 63.0,
        onPressed: onUpgradeLaser
      )
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
            height: 59.0,
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
      key: new Key("${key.toString()}_$index")
    );
  }
}

class BottomBar extends StatelessComponent {

  BottomBar({this.onPlay});

  final VoidCallback onPlay;

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
        left: 85.0,
        top: 14.0,
        child: new TextureButton(
          texture: _spriteSheetUI['btn_level_up.png'],
          width: 30.0,
          height: 30.0
        )
      ),
      new Positioned(
        left: 85.0,
        top: 46.0,
        child: new TextureButton(
          texture: _spriteSheetUI['btn_level_down.png'],
          width: 30.0,
          height: 30.0
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

class MainScreenBackground extends NodeWithSize {
  Sprite _bgTop;
  Sprite _bgBottom;

  MainScreenBackground() : super(new Size(320.0, 320.0)) {
    assert(_spriteSheet.image != null);

    StarField starField = new StarField(_spriteSheet, 200, true);
    addChild(starField);

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
}
