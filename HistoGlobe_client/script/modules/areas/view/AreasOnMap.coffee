window.HG ?= {}

class HG.AreasOnMap

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

  # ============================================================================
  hgInit: (@_hgInstance) ->

    # add areasOnMap to HG instance
    @_hgInstance.areasOnMap = @

    # error handling
    if not @_hgInstance.areaController
      console.error "Unable to show areas on the map: AreaController module not detected in HistoGlobe instance!"

    # init variables
    @_map = @_hgInstance.map.getMap()
    @_zoomLevel = @_map.getZoom()
    @_selectedAreas = []

    # includes
    @_labelManager = new HG.LabelManager @_map

    # event handling
    @_hgInstance.onAllModulesLoaded @, () =>

      # create new leaflet layers when new area gets created
      @_hgInstance.areaController.onCreateArea @, (areaHandle) =>
        new HG.AreaTerritoryLayerOnMap areaHandle, @_map
        new HG.AreaNameLayerOnMap areaHandle, @_map, @_labelManager

        areaHandle.onSelect @, @_select
        areaHandle.onDeselect @, @_deselect


      # listen to zoom event from map
      @_map.on "zoomend", @_onZoom



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################


  ### EVENT HANDLING ###

  # ----------------------------------------------------------------------------
  _select: (areaHandle) =>

    # error handling: do not update if layer not there
    return if not areaHandle.multiPolygonLayer

    # accumulate fullBound box around all currently selected areas
    fullBound = areaHandle.multiPolygonLayer.getBounds() # L.latLngBounds
    for selArea in @_selectedAreas
      currBound = selArea.multiPolygonLayer.getBounds()
      fullBound._northEast.lat = Math.max(currBound.getNorth(), fullBound.getNorth())
      fullBound._northEast.lng = Math.max(currBound.getEast(),  fullBound.getEast())
      fullBound._southWest.lat = Math.min(currBound.getSouth(), fullBound.getSouth())
      fullBound._southWest.lng = Math.min(currBound.getWest(),  fullBound.getWest())
    # @_map.fitBounds fullBound

    # add area to list in last step
    @_selectedAreas.push areaHandle

  # ----------------------------------------------------------------------------
  _deselect: (areaHandle) =>
    idx = @_selectedAreas.indexOf areaHandle
    @_selectedAreas.splice idx, 1


  # ----------------------------------------------------------------------------
  _onZoom: (evt) =>
    # get zoom direction
    oldZoom = @_zoomLevel
    newZoom = @_map.getZoom()

    # check zoom direction and update labels
    if newZoom > oldZoom  # zoom in
      @_labelManager.zoomIn()
    else                  # zoom out
      @_labelManager.zoomOut()

    # update zoom level
    @_zoomLevel = newZoom


  # ============================================================================
  ### HELPER FUNCTIONS ###

