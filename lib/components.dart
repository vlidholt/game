part of game;

class TextureImage extends StatelessWidget {
  TextureImage({
    Key key,
    this.texture,
    this.width: 128.0,
    this.height: 128.0
  }) : super(key: key);

  final Texture texture;
  final double width;
  final double height;

  Widget build(BuildContext context) {
    return new Container(
      width: width,
      height: height,
      child: new CustomPaint(
        painter: new TextureImagePainter(texture, width, height)
      )
    );
  }
}

class TextureImagePainter extends CustomPainter {
  TextureImagePainter(this.texture, this.width, this.height);

  final Texture texture;
  final double width;
  final double height;

  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / texture.size.width, size.height / texture.size.height);
    texture.drawTexture(canvas, Point.origin, new Paint());
    canvas.restore();
  }

  bool shouldRepaint(TextureImagePainter oldPainter) {
    return oldPainter.texture != texture
      || oldPainter.width != width
      || oldPainter.height != height;
  }
}

class TextureButton extends StatefulWidget {
  TextureButton({
    Key key,
    this.onPressed,
    this.texture,
    this.textureDown,
    this.width: 128.0,
    this.height: 128.0,
    this.label,
    this.textStyle,
    this.textAlign: TextAlign.center,
    this.labelOffset: Offset.zero
  }) : super(key: key);

  final VoidCallback onPressed;
  final Texture texture;
  final Texture textureDown;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final String label;
  final double width;
  final double height;
  final Offset labelOffset;

  TextureButtonState createState() => new TextureButtonState();
}

class TextureButtonState extends State<TextureButton> {
  bool _highlight = false;

  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Container(
        width: widget.width,
        height: widget.height,
        child: new CustomPaint(
          painter: new TextureButtonPainter(widget, _highlight)
        )
      ),
      onTapDown: (_) {
        setState(() {
          _highlight = true;
        });
      },
      onTap: () {
        setState(() {
          _highlight = false;
        });
        if (widget.onPressed != null)
          widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _highlight = false;
        });
      }
    );
  }
}

class TextureButtonPainter extends CustomPainter {
  TextureButtonPainter(this.widget, this.highlight);

  final TextureButton widget;
  final bool highlight;

  void paint(Canvas canvas, Size size) {
    if (widget.texture != null) {
      canvas.save();
      if (highlight) {
        // Draw down state
        if (widget.textureDown != null) {
          canvas.scale(size.width / widget.textureDown.size.width, size.height / widget.textureDown.size.height);
          widget.textureDown.drawTexture(canvas, Point.origin, new Paint());
        } else {
          canvas.scale(size.width / widget.texture.size.width, size.height / widget.texture.size.height);
          widget.texture.drawTexture(
            canvas,
            Point.origin,
            new Paint()..colorFilter = new ColorFilter.mode(new Color(0x66000000), TransferMode.srcATop)
          );
        }
      } else {
        // Draw up state
        canvas.scale(size.width / widget.texture.size.width, size.height / widget.texture.size.height);
        widget.texture.drawTexture(canvas, Point.origin, new Paint());
      }
      canvas.restore();
    }

    if (widget.label != null) {
      TextStyle style;
      if (widget.textStyle == null)
        style = new TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700);
      else
        style = widget.textStyle;

      TextSpan textSpan = new TextSpan(style: style, text: widget.label);
      TextPainter painter = new TextPainter(text: textSpan, textAlign: widget.textAlign);

      painter.layout(minWidth: size.width, maxWidth: size.width);
      painter.paint(canvas, new Offset(0.0, size.height / 2.0 - painter.height / 2.0 ) + widget.labelOffset);
    }
  }

  bool shouldRepaint(TextureButtonPainter oldPainter) {
    return oldPainter.highlight != highlight
      || oldPainter.widget.texture != widget.texture
      || oldPainter.widget.textureDown != widget.textureDown
      || oldPainter.widget.textStyle != widget.textStyle
      || oldPainter.widget.label != widget.label
      || oldPainter.widget.width != widget.width
      || oldPainter.widget.height != widget.height;
  }
}
