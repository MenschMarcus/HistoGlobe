window.HG ?= {}

# ============================================================================
# represents a polypolygon geometry in various different formats
# support for:
#     polyline        LineString
#     polygon         Polygon
#     polypolygon     MultiPolygon

# ============================================================================
#   GeoJSON object -> json(PtArr?=no)
#     -> returns only geometry object; to use in existing JSON object:
#         {'type': 'feature', 'geometry': myGeometry.json(), 'properties': ...}
#     -> if ptArr=yes, the output coordinates will be in an array [lat, lng]
#     -> if ptArr=no*, the output coordinates will be in an object {'lat': float, 'lng': float}
#   geometry array -> array(PtArr?=no)
#     -> if ptArr=yes, the output coordinates will be in an array [lat, lng]
#     -> if ptArr=no*, the output coordinates will be in an object {'lat': float, 'lng': float}
#   leaflet layer  -> new L.multiPolygon myGeometry.array(), options
#   WKT string     -> .wkt()
#   JSTS object    -> .jsts()
#     -> to be used in JSTS library: http://bjornharrtell.github.io/jsts/

# ============================================================================
# The internal strucutre of each geometry array is:
# 'type': 'MultiPolygon' or 'Polygon' or 'LineString'
# 'coordinates':
#   [           1. array: polypolygon       [n]
#     [         2. array: polygon           [1: no holes, 2+: holes]
#       [       3. array: polyline (closed) [m]
#         {     4. object: point            [2]
#           'lat': float, 'lng': float    -> point object (PtObj)
#         }
#     OR: [  lng, lat  ]                  -> point array  (PtArr)
#       ]
#     ]
#   ]
# N.B. each polygon can contain inner and outer rings
# => polygon usually contains only one polyline
# ============================================================================


class HG.Geometry

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_geometries) ->


  # ============================================================================
  ### GETTER ###
  type: () ->                       @_type

  # ----------------------------------------------------------------------------
  json: () ->                       @_toJSON()
  wkt: () ->                        @_toWkt @_toJSON()
  jsts: () ->                       @_toJsts @_toWkt @_toJSON()

  # ----------------------------------------------------------------------------
  coordinates: (inLatLng=no) ->     @_getCoordinates inLatLng
  array: (inLatLng=no) ->           @_getCoordinates inLatLng
  latLng: () ->                     @_getCoordinates yes

  # ----------------------------------------------------------------------------
  isValid: () ->                    @_isValid

  # ----------------------------------------------------------------------------
  # bounding box structure: minLng, maxLng, minLat, maxLat
  getBoundingBox: (inLatLng=no) ->  @_getBoundingBox inLatLng
  getCenter: () ->                  new HG.Point(@_getCenter())
        # it seems weird that I can construct an object of a subclass
        # in its own baseclass, but I won't complain!

  # ----------------------------------------------------------------------------
  getArea: () ->                    @jsts().getArea()

  # ----------------------------------------------------------------------------
  fixHoles: () ->                   @_geometries = @_fixHoles()

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _getCoordinates: (inLatLng=no) ->
    coordinates = []
    coordinates.push geometry.coordinates(inLatLng) for geometry in @_geometries
    coordinates

  # ============================================================================
  _toJSON: () ->
    {
      'type':         @type()
      'coordinates':  @coordinates()
    }

  # ----------------------------------------------------------------------------
  _toWkt: (json) ->
    # error handling
    return "MULTIPOLYGON EMPTY" if json.coordinates is null

    # wicket can not read array, only json
    wicket = new Wkt.Wkt
    wicket.fromJson json
    wicket.write()

  # ----------------------------------------------------------------------------
  _toJsts: (wkt) ->
    # WKTReader for jsts can not read pure array, only wkt or json
    # create jsts object
    wktReader = new jsts.io.WKTReader
    wktReader.read wkt


  # ============================================================================
  # calculate properties

  # ----------------------------------------------------------------------------
  _getBoundingBox: (inLatLng=no) ->
    # approach: get bounding box of level underneath and
    # calculate this levels' bounding box based on them
    # what a great idea :)

    thisBbox = @_geometries[0].getBoundingBox(inLatLng)

    for lowerGeom in @_geometries
      lowerBbox = lowerGeom.getBoundingBox(inLatLng)
      if inLatLng
        thisBbox.minLng = Math.min thisBbox.minLng, lowerBbox.minLng
        thisBbox.maxLng = Math.max thisBbox.maxLng, lowerBbox.maxLng
        thisBbox.minLat = Math.min thisBbox.minLat, lowerBbox.minLat
        thisBbox.maxLat = Math.max thisBbox.maxLat, lowerBbox.maxLat
      else
        thisBbox[0] = Math.min thisBbox[0], lowerBbox[0]
        thisBbox[1] = Math.max thisBbox[1], lowerBbox[1]
        thisBbox[2] = Math.min thisBbox[2], lowerBbox[2]
        thisBbox[3] = Math.max thisBbox[3], lowerBbox[3]

    thisBbox


  # ----------------------------------------------------------------------------
  _getCenter: (inLatLng=no) ->
    # approach: get bounding box of largest geometry underneath and take its center
    # TODO: is that actually a good approach? Does that actually matter?
    # -> I'm going to redefine it later anyways...

    if inLatLng
      center = {'lat': 0.0, 'lng': 0.0}
    else
      center = [0.0,0.0]

    # find largest sub-part
    maxSize = 0
    for lowerGeom in @_geometries
      bbox = lowerGeom.getBoundingBox(inLatLng)
      if inLatLng
        size = (Math.abs bbox.maxLng-bbox.minLng)*(Math.abs bbox.maxLat-bbox.minLat)
      else
        size = (Math.abs bbox[1]-bbox[0])*(Math.abs bbox[3]-bbox[2])
      # new largest sub-part found!
      if size > maxSize
        maxSize = size
        # update center
        if inLatLng
          center.lng = ((bbox.minLng+bbox.maxLng)/2)
          center.lat = ((bbox.minLat+bbox.maxLat)/2)
        else
          center[0] = ((bbox[0]+bbox[1])/2)
          center[1] = ((bbox[2]+bbox[3])/2)

    center


  # ============================================================================
  # special operations
  # -> to be implemented in their subclasses

  # ----------------------------------------------------------------------------
  _fixHoles: () ->