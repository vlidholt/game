part of game;

class CoordinateSystem extends OneChildRenderObjectWidget {
  CoordinateSystem({ Key key, this.systemSize, this.systemType: CoordinateSystemType.fixedWidth, Widget child })
    : super(key: key, child: child) {
    assert(systemSize != null);
  }

  final Size systemSize;
  final CoordinateSystemType systemType;

  RenderCoordinateSystem createRenderObject() => new RenderCoordinateSystem(systemSize: systemSize, systemType: systemType);

  void updateRenderObject(RenderCoordinateSystem renderObject, CoordinateSystem oldWidget) {
    renderObject.systemSize = systemSize;
    renderObject.systemType = systemType;
  }
}
