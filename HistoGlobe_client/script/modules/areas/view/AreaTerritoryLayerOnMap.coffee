window.HG ?= {}

# ==============================================================================
# A leaflet MultiPolygonLayer for an area territory
# will be created and destructed by AreasOnMap
# listens to callbacks from AreaHandle directly
# ==============================================================================

class HG.AreaTerritoryLayerOnMap

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # create a MultiPolygonLayer givent the information extracted from the Area
  # ============================================================================

  constructor: (@_areaHandle, @_map) ->

    ### INTERACTION ###

    @_areaHandle.onAddTerritory @,    @_addLayer
    @_areaHandle.onUpdateTerritory @, @_updateLayer
    @_areaHandle.onRemoveTerritory @, @_removeLayer

    @_areaHandle.onFocus @,           @_updateStyle
    @_areaHandle.onUnfocus @,         @_updateStyle
    @_areaHandle.onSelect @,          @_updateStyle
    @_areaHandle.onDeselect @,        @_updateStyle
    @_areaHandle.onStartEdit @,       @_updateStyle
    @_areaHandle.onEndEdit @,         @_updateStyle


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################


  # ============================================================================
  # add / update / remove the MultiPolygonLayer for the area
  # ============================================================================

  _addLayer: () ->
    geometry = @_areaHandle.getArea().territory.geometry.latLng()

    # styling area in CSS based on its calss is a bad idea, because d3 can not
    # update that => use leaflet layer options
    properties = @_areaHandle.getStyle()
    options = {
      'className':    'area'
      'clickable':    true
      'fillColor':    properties.areaColor
      'fillOpacity':  properties.areaOpacity
      'color':        properties.borderColor
      'opacity':      properties.borderOpacity
      'weight':       properties.borderWidth
    }

    # actual geometry layer
    @_areaHandle.multiPolygonLayer = new L.multiPolygon geometry, options

    # create double-link: leaflet layer knows HG area and HG area knows leaflet layer
    @_areaHandle.multiPolygonLayer.areaHandle = @_areaHandle

    @_areaHandle.multiPolygonLayer.addTo @_map


    ### INTERACTION ###

    # user interaction -> THIS -> AreaHandle

    @_areaHandle.multiPolygonLayer.on 'mouseover', (evt) =>
      @_areaHandle.focus()

    @_areaHandle.multiPolygonLayer.on 'mouseout', (evt) =>
      @_areaHandle.unfocus()

    @_areaHandle.multiPolygonLayer.on 'click', (evt) =>
      @_areaHandle.select()
      # bug: after clicking, it is assumed to be still focused
      # fix: unfocus afterwards
      @_areaHandle.unfocus()

  # ----------------------------------------------------------------------------
  _updateLayer: () ->
    @_areaHandle.multiPolygonLayer.setLatLngs @_areaHandle.getArea().territory.geometry.latLng()

  # ----------------------------------------------------------------------------
  _removeLayer: () ->
    @_map.removeLayer @_areaHandle.multiPolygonLayer
    @_areaHandle.multiPolygonLayer = null


  # ============================================================================
  # get the style based on the current properties of the area and animate the area
  # ============================================================================

  _updateStyle: () ->

    # error handling: do not update if layer not there
    return if not @_areaHandle.multiPolygonLayer

    properties = @_areaHandle.getStyle()
    @animate {
      'fill':           properties.areaColor
      'fill-opacity':   properties.areaOpacity
      'stroke':         properties.borderColor
      'stroke-opacity': properties.borderOpacity
      'stroke-width':   properties.borderWidth
    }, HGConfig.fast_animation_time.val


  # ============================================================================
  # actual animation based on d3
  # N.B. needs animation duration as a parameter !!!
  # ============================================================================

  animate: (attributes, duration, finishFunction) ->
    console.error "no animation duration given" if not duration?
    area = @_areaHandle.multiPolygonLayer
    if area._layers?
      for id, path of area._layers
        d3.select(path._path).transition().duration(duration).attr(attributes).each('end', finishFunction)
    else if area._path?
      d3.select(area._path).transition().duration(duration).attr(attributes).each('end', finishFunction)