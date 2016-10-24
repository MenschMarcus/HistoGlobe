window.HG ?= {}

# ============================================================================
#

class HG.Polypolygon extends HG.Geometry

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (inCoordinates) ->

    @_type = 'MultiPolygon'
    @_isValid = yes
    @_polygons = []

    for polygon in inCoordinates
      newPolygon = new HG.Polygon polygon
      @_isValid = no if not newPolygon.isValid()
      @_polygons.push newPolygon

    super @_polygons


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _fixHoles: () ->

    # error handling
    unless @_isValid
      return console.error "The Polypolygon is not valid"


    # structure of underlying polygons is like this:
    # 1. polyline in polygon: outer ring
    # 2+ polyline in polygon: inner ring(s) / hole(s)
    # if a hole has a whole itself, it becomes the first polyline of a new polygon
    # => only partially hierarchical structure
    # problem: how to create / maintain this structure?
    # solution: set up n-ary within tree

    tree = new HG.WithinTree

    # insert all polylines into tree
    for polygon, it1 in @_polygons
      for polyline, it2 in polygon._polylines
        id = it1+'-'+it2
        tree.insert(new HG.WithinTreeNode id, polyline)

    # extract one polygon after the other
    # with all its polylines in the correct strucutre (outer ring, inner rings...)
    newPolygons = []
    while not tree.isEmpty()
      polygon = []
      for polyline in tree.extract()
        polygon.push polyline.coordinates()
      newPolygons.push new HG.Polygon polygon

    return newPolygons