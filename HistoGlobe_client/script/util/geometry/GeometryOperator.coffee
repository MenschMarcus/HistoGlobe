window.HG ?= {}

# ============================================================================
# perform geo operations on given geometry objects

class HG.GeometryOperator

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: () ->
    @_geometryReader = new HG.GeometryReader

  # ============================================================================
  # union = cascaded union = dissolve
  # credits: elrobis
  # http://gis.stackexchange.com/questions/85229/looking-for-dissolve-algorithm-for-javascript
  # -> extended to perform cascaded union (unifies all (Multi)Polygons in array of wkt representations of (Multi)Polygons)
  # thank you!
  union: (inGeometries) ->
    geometries = @_getNonemptyGeometries inGeometries

    # all geometries empty => return empty geometry
    if geometries.length is 0
      return @_geometryReader.read null

    # 1 geometry not empty => return the other
    else if geometries.length is 1
      return geometries[0]

    # >1 geometry not empty => return cascaded union
    else
      # TODO: could be more efficient with a tree, but I really do not care about this at this point :P
      tempGeometry = geometries[0]
      idx = 1 # = start at the second geometry
      while idx < geometries.length
        if geometries[idx].isValid()
          tempGeometry = @_geometryReader.read(tempGeometry.jsts().union(geometries[idx].jsts()))
        idx++
      tempGeometry

    # TODO: remove sliver polygons = maintain topological correctness

  # ----------------------------------------------------------------------------
  intersection: (A, B) ->
    # >1 geometries empty => return empty geometry
    if not A.isValid() or not B.isValid()
      return @_geometryReader.read null

    # both geometries not empty => return intersection
    else
      return @_geometryReader.read(A.jsts().intersection(B.jsts()))

  # ----------------------------------------------------------------------------
  difference: (A, B) ->
    # both geometries empty => return empty geometry
    if not A.isValid() and not B.isValid()
      return @_geometryReader.read null

    # 1st geometry empty => null \ A = null => return empty geometry
    else if not A.isValid()
      return @_geometryReader.read null

    # 2nd geometry empty => A \ null = A => return 1st geometry
    else if not B.isValid()
      return A

    # both geometries not empty => return difference
    else
      return @_geometryReader.read(A.jsts().difference(B.jsts()))


  # ----------------------------------------------------------------------------
  merge: (inGeometries) ->
    # merge one geometry into another is somewhat complicated
    # not all levels can be treated the same way:
    # merging only makes sense for polygons and polypolygons
    # the result will always be a polypolygon
    outCoordinates = []

    for geometry in inGeometries
      if geometry.type() is 'Polygon'
        outCoordinates.push geometry.coordinates()
      else if geometry.type() is 'MultiPolygon'
        for polygon in geometry._geometries
          outCoordinates.push polygon.coordinates()
      else if geometry.type() is 'LineString'
        # TODO: this one will probably not work...
        for polygon in geometry._geometries
          for polyline in polygon._geometries
            outCoordinates.push [polyline.coordinates()]
      else
        return console.error "It is not possible to merge a point. Idiot !!!"

    if outCoordinates.length > 0
      @_geometryReader.read outCoordinates

  # ----------------------------------------------------------------------------
  isWithin: (Ageom, Bgeom) ->
    # approach from set theory:
    #   A \union B = B <=> A \in B <=> A \intersect B = A
    #   A \union B = A <=> B \in A <=> A \intersect B = B
    # only one of the two tests required, because they are the same
    #                  A \union B = B            <=>            A \intersect B = A
    #   {x : x \in A \or x \in B} = {x: x \in B} <=> {x: x \in A \and x \in B} = {x: x \in A}
    #               {\nexist x in A: x \notin B} <=> {\nexist x in A: x \notin B}
    #                                          1 <=> 1  q.e.d.
    # if A \union B = B => A \in B

    # simple theory, a little harder praxis: A polyline technically does not
    # "contain" anything, because it doesn't have an area. Therefore, a Polygon
    # has to be created first

    A = Ageom.jsts()
    B = Bgeom.jsts()

    # problem: 'contains' function only works with polygons and multipolygons
    # => if LinearRing is given in, it must be converted to a Polygon

    A = new jsts.geom.Polygon A if A.getGeometryType() is 'LineString'
    B = new jsts.geom.Polygon B if B.getGeometryType() is 'LineString'

    B.contains A


  # ----------------------------------------------------------------------------
  areEqual: (A, B) ->
    (A.jsts().compareTo(B.jsts())) is 0

  # ----------------------------------------------------------------------------
  copy: (geometry) ->
    # nasty way to deep copy a string
    # credits to: AffluentOwl
    # http://stackoverflow.com/questions/31712808/how-to-force-javascript-to-deep-copy-a-string
    geometryCopy = (' ' + geometry.wkt()).slice(1)
    @_geometryReader.read geometryCopy


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ----------------------------------------------------------------------------
  _getNonemptyGeometries: (inGeometries) ->
  # error handling: only deal with non-empty Polygons or Polypolygons
  # reject the rest
    outGeometries = []
    for geometry in inGeometries
      outGeometries.push geometry if geometry.isValid()
    outGeometries