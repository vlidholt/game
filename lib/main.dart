// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

import 'game_demo.dart';

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

// TODO(viktork): The task bar purple is the wrong purple, we may need
// a custom theme swatch to match the purples in the sprites.
final ThemeData _theme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.purple
);

class GameDemo extends StatefulComponent {
  GameDemoState createState() => new GameDemoState();
}

class GameDemoState extends State<GameDemo> {
  NodeWithSize _game;
  int _lastScore = 0;

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Asteroids',
      theme: _theme,
      routes: <String, RouteBuilder>{
        '/': _buildMainScene,
        '/game': _buildGameScene
      }
    );
  }

  Widget _buildGameScene(RouteArguments args) {
    return new SpriteWidget(_game, SpriteBoxTransformMode.fixedWidth);
  }

  Widget _buildMainScene(RouteArguments args) {
    NavigatorState navigatorState = Navigator.of(args.context);

    return new CoordinateSystem(
      systemSize: new Size(320.0, 320.0),
      child:new DefaultTextStyle(
        style: new TextStyle(fontSize:20.0),
        child: new Stack(<Widget>[
          new SpriteWidget(new MainScreenBackground(), SpriteBoxTransformMode.fixedWidth),
          new ScrollableList<String>(
            items: ["Hey", "ho", "let's", "go"],
            itemExtent: 50.0,
            itemBuilder: (BuildContext context, String data, int index) {
              return new ListItem(
                key: new Key(data),
                center: new Text(data)
              );
            }
          ),
          new Column(<Widget>[
              new TextureButton(
                onPressed: () {
                  _game = new GameDemoNode(
                    _imageMap,
                    _spriteSheet,
                    _spriteSheetUI,
                    _sounds,
                    (int lastScore) {
                      setState(() { _lastScore = lastScore; });
                      navigatorState.pop();
                    }
                  );
                  navigatorState.pushNamed('/game');
                },
                texture: _spriteSheetUI['btn_play.png'],
                label: "PLAY",
                width: 181.0,
                height: 62.0
              ),
              new Row(<Widget>[
                  _buildPowerUpButton(PowerUpType.shield),
                  _buildPowerUpButton(PowerUpType.sideLaser),
                  _buildPowerUpButton(PowerUpType.speedBoost),
                  _buildPowerUpButton(PowerUpType.speedLaser),
                ],
                justifyContent: FlexJustifyContent.center
              ),
              new DefaultTextStyle(
                child: new Text(
                  "Last Score: $_lastScore"
                ),
                style: new TextStyle(fontSize:20.0)
              )
            ],
            justifyContent: FlexJustifyContent.center
          )
        ])
      )
    );
  }

  Widget _buildPowerUpButton(PowerUpType type) {
    return new Padding(
      padding: new EdgeDims.all(5.0),
      child: new TextureButton(
        texture: _spriteSheetUI['btn_powerup_${type.index}.png'],
        width: 57.0,
        height: 57.0
      )
    );
  }
}

class TextureButton extends StatefulComponent {
  TextureButton({
    Key key,
    this.onPressed,
    this.texture,
    this.textureDown,
    this.width: 128.0,
    this.height: 128.0,
    this.label,
    this.textStyle
  }) : super(key: key);

  final VoidCallback onPressed;
  final Texture texture;
  final Texture textureDown;
  final TextStyle textStyle;
  final String label;
  final double width;
  final double height;

  TextureButtonState createState() => new TextureButtonState();
}

class TextureButtonState extends State<TextureButton> {
  bool _highlight = false;

  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Container(
        width: config.width,
        height: config.height,
        child: new CustomPaint(
          onPaint: paintCallback,
          token: new _TextureButtonToken(
            _highlight,
            config.texture,
            config.textureDown,
            config.width,
            config.height,
            config.label,
            config.textStyle
          )
        )
      ),
      onTapDown: (_) {
        SoundEffectPlayer.sharedInstance().play(_sounds["click"]);
        setState(() {
          _highlight = true;
        });
      },
      onTap: () {
        setState(() {
          _highlight = false;
        });
        if (config.onPressed != null)
          config.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _highlight = false;
        });
      }
    );
  }

  void paintCallback(PaintingCanvas canvas, Size size) {
    if (config.texture == null)
      return;

    canvas.save();
    if (_highlight) {
      // Draw down state
      if (config.textureDown != null) {
        canvas.scale(size.width / config.textureDown.size.width, size.height / config.textureDown.size.height);
        config.textureDown.drawTexture(canvas, Point.origin, new Paint());
      } else {
        canvas.scale(size.width / config.texture.size.width, size.height / config.texture.size.height);
        config.texture.drawTexture(
          canvas,
          Point.origin,
          new Paint()..colorFilter = new ColorFilter.mode(new Color(0x66000000), TransferMode.srcATop)
        );
      }
    } else {
      // Draw up state
      canvas.scale(size.width / config.texture.size.width, size.height / config.texture.size.height);
      config.texture.drawTexture(canvas, Point.origin, new Paint());
    }
    canvas.restore();

    if (config.label != null) {
      TextStyle style;
      if (config.textStyle == null)
        style = new TextStyle(textAlign: TextAlign.center, fontSize: 24.0, fontWeight: FontWeight.w700);
      else
        style = config.textStyle;

      PlainTextSpan textSpan = new PlainTextSpan(config.label);
      StyledTextSpan styledTextSpan = new StyledTextSpan(style, <TextSpan>[textSpan]);
      TextPainter painter = new TextPainter(styledTextSpan);

      painter.maxWidth = size.width;
      painter.minWidth = 0.0;
      painter.layout();
      painter.paint(canvas, new Offset(0.0, size.height / 2.0 - painter.height / 2.0 ));
    }
  }
}

class _TextureButtonToken {
  _TextureButtonToken(
    this._highlight,
    this._texture,
    this._textureDown,
    this._width,
    this._height,
    this._label,
    this._textStyle
  );

  final bool _highlight;
  final Texture _texture;
  final Texture _textureDown;
  final double _width;
  final double _height;
  final String _label;
  final TextStyle _textStyle;

  bool operator== (other) {
    return
      other is _TextureButtonToken &&
      _highlight == other._highlight &&
      _texture == other._texture &&
      _textureDown == other._textureDown &&
      _width == other._width &&
      _height == other._height &&
      _label == other._label &&
      _textStyle == other._textStyle;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value * _highlight.hashCode;
    value = 37 * value * _texture.hashCode;
    value = 37 * value * _textureDown.hashCode;
    value = 37 * value * _width.hashCode;
    value = 37 * value * _height.hashCode;
    value = 37 * value * _textStyle.hashCode;
    value = 37 * value * _label.hashCode;
    return value;
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

  void paint(PaintingCanvas canvas) {
    canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, 320.0, 320.0), new Paint()..color=new Color(0xff000000));
    super.paint(canvas);
  }

  void spriteBoxPerformedLayout() {
    _bgBottom.position = new Point(0.0, spriteBox.visibleArea.size.height);
  }
}
