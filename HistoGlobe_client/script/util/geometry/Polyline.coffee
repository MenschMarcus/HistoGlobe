window.HG ?= {}

# ============================================================================
#

class HG.Polyline extends HG.Geometry

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (inCoordinates) ->

    @_type = 'LineString'
    @_isValid = yes
    @_points = []

    for point in inCoordinates
      newPoint = new HG.Point point
      @_isValid = no if not newPoint.isValid()
      @_points.push newPoint

    ## validation
    # polyline must not intersect itself
    @_isValid = not @_checkSelfIntersection()

    super @_points


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _checkSelfIntersection: () ->
  # credits to: Engineering Team of Nextdoor and Harry Potter
  # https://gist.github.com/anonymous/d9b9552df056a6773ad5
  # https://engblog.nextdoor.com/2014/05/21/fast-polygon-self-intersection-detection-in-javascript/
  # Thank you very much !!!

    # get boundary coordinates in jsts format
    coordinates = []
    for point in @_points
      pointCoordinates = point.coordinates()
      coordinates.push new jsts.geom.Coordinate pointCoordinates[0], pointCoordinates[1]

    # do magic #1: Expecto Patronum
    geometryFactory = new jsts.geom.GeometryFactory
    shell = geometryFactory.createLinearRing coordinates
    jstsPolygon = geometryFactory.createPolygon shell

    # do magic #2: Expelliarmus
    # if the geometry is aleady a simple linear ring, do not
    # try to find self intersection points
    validator = new jsts.operation.IsSimpleOp jstsPolygon
    if validator.isSimpleLinearGeometry jstsPolygon # no self-intersection
      return no

    # do magic #3: Avada Kedavra
    graph = new jsts.geomgraph.GeometryGraph 0, jstsPolygon
    magic = new jsts.operation.valid.ConsistentAreaTester graph
    # ALERT! if node is not a consistent area => polyline is self-intersecting!
    # only He-Who-Must-Not-Be-Named knows why
    return not magic.isNodeConsistentArea()