window.HG ?= {}

# ==============================================================================
# reads geometry strings / objects in the following formats:
#   GeometryArray   [[[[lng, lat]]]] or [[[{'lat': lat, 'lng': lng}]]]
#   GeoJSON object  {'geometry':{'type': 'AnyThing', coordinates: GeometryArray}}
#   Leaflet layer   L.MultiPolygon, L.Polygon, L.LineString, L.Point
#   wkt string      "GEOMETRYTYPE(((LAT LNG,LAT LNG,...)))"
#   jsts object     "GEOMETRYTYPE(((LAT LNG,LAT LNG,...)))"
# input can be either a single object or an [array of objects]

class HG.GeometryReader

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: () ->

  # ============================================================================
  read: (inObject) ->
    # error handling: empty geometry
    geometry = 'EMPTY' if inObject is null

    # convert to geometry array
    geometry = @_readJsts inObject            unless geometry
    geometry = @_readWkt inObject             unless geometry
    geometry = @_readLeafletLayer inObject    unless geometry
    geometry = @_readGeoJSON inObject         unless geometry
    geometry = @_readCoordinateArray inObject unless geometry

    # error handling: empty geometry
    if geometry is 'EMPTY'
      return new HG.Point null

    # error handling: non-detectable format
    if geometry is null
      console.error "The given geometry could not be read, it must be in one of the accepted formats: \n
        leaflet layer, GeoJSON object, pure geometry array, WKT string or jsts object"
      return null


    ### OUTPUT ###
    # create actual geometry
    if geometry.depth is 0
      return new HG.Point geometry.coordinates
    else if geometry.depth is 1
      return new HG.Polyline geometry.coordinates
    else if geometry.depth is 2
      return new HG.Polygon geometry.coordinates
    else if geometry.depth is 3
      return new HG.Polypolygon geometry.coordinates
    else
      return null

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  ### INPUT ###
  # ============================================================================
  _readCoordinateArray: (inObject) ->
    # detect
    if (Array.isArray inObject)

      # determine depth of point specification
      depth = @_findPoints inObject

      # error handling: empty geometry
      return null if depth is null

      return {
        'depth':        depth
        'coordinates':  inObject
      }

    # reject
    return null

  # ----------------------------------------------------------------------------
  _readGeoJSON: (inObject) ->
    geom = null

    # 1. possibility: complete GeoJSON object
    # detect
    if (
      (inObject.constructor is Object) and
      (inObject.hasOwnProperty 'geometry') and
      (inObject.type is 'feature')
    )

      # accept: extract geometry array and convert to MultiPolygon
      return @_readCoordinateArray inObject.geometry.coordinates

    # 2. possibility: GeoJSON geometry object
    # detect
    if ((inObject.constructor is Object) and
        (inObject.hasOwnProperty 'coordinates') and
        (inObject.hasOwnProperty 'type'))

      # accept: extract geometry array and convert to MultiPolygon
      return @_readCoordinateArray inObject.coordinates

    # reject if geometry is still null => no GeoJSON object input
    return null

  # ----------------------------------------------------------------------------
  _readLeafletLayer: (inObject) ->
    # detect
    if (
      (inObject instanceof L.Point) or
      (inObject instanceof L.Polyline) or     # AAARGH! why this inconsistency? Why is that not 'L.LineString?'
      (inObject instanceof L.Polygon) or
      (inObject instanceof L.MultiPolygon)
    )

      # accept: parse geoJON and read that one
      return @_readGeoJSON inObject.toGeoJSON().geometry

    # reject
    return null

  # ----------------------------------------------------------------------------
  _readWkt: (inObject) ->
    # detect
    if (
      (typeof inObject is 'string') and
      (
        ((inObject.indexOf 'POINT') isnt -1) or
        ((inObject.indexOf 'LINESTRING') isnt -1) or
        ((inObject.indexOf 'POLYGON') isnt -1) or
        ((inObject.indexOf 'MULTIPOLYGON') isnt -1)
      )
    )

      # accept: parse geoJON and read that one
      wicket = new Wkt.Wkt
      wicket.read inObject
      return @_readGeoJSON wicket.toJson()

    # reject
    return null

  # ----------------------------------------------------------------------------
  _readJsts: (inObject) ->
    # detect
    # TODO: better way to detect it?
    if (
      (typeof inObject is 'object') and
      (inObject.hasOwnProperty 'factory')
    )

      # accept: parse wkt and read that one
      wktWriter = new jsts.io.WKTWriter
      wktString = wktWriter.write inObject

      # error handling: reject any kind of empty geometry
      return 'EMPTY' if (wktString.indexOf 'EMPTY') isnt -1

      # error handling: merge GEOMETRYCOLLECTIONS
      # TODO

      return @_readWkt wktString

    return null

  # ----------------------------------------------------------------------------
  _findPoints: (coordinatesArray, arrayDepth=0) ->
    # idea: check for each level, if the subarray is the level in which points are defined
    # => what an elegant solution ;)

    # error handling
    return null if arrayDepth > 3 or not coordinatesArray

    # points found! no more subarrays...
    return arrayDepth if @_checkIfPointArr coordinatesArray
    return arrayDepth if @_checkIfPointObj coordinatesArray

    # points not fount => recursion
    arrayDepth++
    @_findPoints coordinatesArray[0], arrayDepth

  # ----------------------------------------------------------------------------
  _checkIfPointArr: (coordinates) ->
    (Array.isArray(coordinates)) and   # checks if array
    (coordinates.length is (2)) and
    (not isNaN(coordinates[0])) and (not isNaN(coordinates[1])) and
    (isFinite(coordinates[0])) and (isFinite(coordinates[1]))

  # ----------------------------------------------------------------------------
  _checkIfPointObj: (coordinates) ->
    (coordinates.constructor is Object) and
    (coordinates.hasOwnProperty('lat')) and
    (coordinates.hasOwnProperty('lng'))


  ### OUTPUT ###
  # ============================================================================
  # _mergeGeometries: (inCoordinates, outCoords={'depth':0, 'coordinates':[]}, depth=3) ->
  #   # recursively go through coords and merge the geometries on the same layer

  #   # break up condition #1: reached lower level
  #   return outCoords if depth < 0

  #   # # break up condition #2: all geometries merged
  #   # return outCoords if inCoords.length is 0

  #   # test if there are geometries on this level
  #   for coords in inCoords
  #     if coords.depth is depth
  #       # geometries inherit depth from highest depth level
  #       outCoords.depth = Math.max depth, outCoords.depth
  #       # put the coordinates of this level into the final geometry array
  #       # -> on the same level!
  #       outCoords.coordinates.push inCoords.coordinates

  #   # recursion
  #   depth--
  #   @_mergeGeometries inCoords[0], outCoords[0], depth

  #   # merge all together and return
  #   console.log "WTF?"