window.HG ?= {}

# ============================================================================
#

class HG.Polygon extends HG.Geometry

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (inCoordinates) ->

    @_type = 'Polygon'
    @_isValid = yes
    @_polylines = []

    for polyline in inCoordinates
      newPolyline = new HG.Polyline polyline
      @_isValid = no if not newPolyline.isValid()

      # do not allow for sliver polygons!
      # i.e. if is polyline has a very small area, it gets omitted
      # -> has to be transformed to POlygon first to calculate the area
      if (new jsts.geom.Polygon(newPolyline.jsts())).getArea() < MIN_AREA_SIZE
        continue

      @_polylines.push newPolyline

    ## hole restructuring
    # goal: create the correct structure of holes in the geometry

    super @_polylines


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################






  ##############################################################################
  #                             STATIC INTERFACE                               #
  ##############################################################################

  MIN_AREA_SIZE = 0.0000001
