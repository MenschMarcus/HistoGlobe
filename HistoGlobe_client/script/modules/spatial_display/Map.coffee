window.HG ?= {}

# ==============================================================================
# Class for displaying a 2D Map using leaflet. Derived from Display base class.
# ==============================================================================
class HG.Map extends HG.SpatialDisplay

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->
    HG.SpatialDisplay.call @

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback "onClick"

    # handle config
    defaultConfig =
      minZoom: 1
      maxZoom: 6
      startZoom: 4
      maxBounds: undefined


    @_config = $.extend {}, defaultConfig, config


  # ============================================================================
  # Inits associated data.
  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add module to HG instance
    @_hgInstance.map = @

    # call constructor of base class
    super @_hgInstance

    # include
    domElemCreator = new HG.DOMElementCreator

    ### INIT MEMBERS ###
    @_isRunning = no

    ### SETUP UI ###
    @_mapParent = domElemCreator.create 'div'
    @_mapParent.style.width = HG.SpatialDisplay.CONTAINER.offsetWidth + "px"
    @_mapParent.style.height = HG.SpatialDisplay.CONTAINER.offsetHeight + "px"
    @_mapParent.style.zIndex = "#{HG.SpatialDisplay.Z_INDEX}"

    HG.SpatialDisplay.CONTAINER.appendChild @_mapParent

    # TODO: integreate mapbox
    # -> use TileMill to style layers
    # leaflet + mapbox
    # accessToken = 'pk.eyJ1IjoibWVuc2NobWFyY3VzIiwiYSI6ImNpZ3p6c2x5NDB3Y200bW0za2cxZzJ0YXoifQ.B8RX1-Sj6v_tmGe-_kP6zQ'
    # style = 'mapbox://styles/menschmarcus/cillef2ly00419vknx2mifdqx'

    options =
      maxZoom:      @_config.maxZoom
      minZoom:      @_config.minZoom
      zoomControl:  false
      maxBounds:    @_config.maxBounds
      worldCopyJump: true

    @_map = L.map @_mapParent, options
    @_map.setView @_hgInstance.config.startPoint, @_config.startZoom

    tileLayer = L.tileLayer(@_hgInstance.config.tiles + '/{z}/{x}/{y}.png')
    tileLayer.addTo @_map


    # old version
    # options =
    #   maxZoom:      @_config.maxZoom
    #   minZoom:      @_config.minZoom
    #   zoomControl:  false
    #   maxBounds:    @_config.maxBounds
    #   worldCopyJump: true

    # @_map = L.map @_mapParent, options
    # @_map.setView @_hgInstance.config.startPoint, @_config.startZoom

    # tileLayer = L.tileLayer(@_hgInstance.config.tiles + '/{z}/{x}/{y}.png')
    # tileLayer.addTo @_map


    # random shit ???
    @_map.attributionControl.setPrefix ''
    @overlayContainer = @_map.getPanes().mapPane

    @_isRunning = yes


    ### INTERACTION ###
    # control buttons

    @_hgInstance.onAllModulesLoaded @, () =>
      if @_hgInstance.buttons.zoomIn?
        @_hgInstance.buttons.zoomIn.onClick @, () =>
          @_map.zoomIn()

      if @_hgInstance.buttons.zoomOut?
        @_hgInstance.buttons.zoomOut.onClick @, () =>
          @_map.zoomOut()

      if @_hgInstance.buttons.highContrast?
        @_hgInstance.buttons.highContrast.onEnter @, () =>
          tileLayer.setUrl @_hgInstance.config.tilesHighContrast + '/{z}/{x}/{y}.png'

        @_hgInstance.buttons.highContrast.onLeave @, () =>
          tileLayer.setUrl @_hgInstance.config.tiles + '/{z}/{x}/{y}.png'

    # window click and resize
    # I do not know why there are two different functions, but it works :)
    window.addEventListener 'resize', @_onWindowResize, false
    @_mapParent.addEventListener 'click', @_onClick, false

    @_hgInstance.onWindowResize @, (width, height) =>
      @_mapParent.style.width = width + "px"
      @_mapParent.style.height = height + "px"
      @_map.invalidateSize()


  # ============================================================================
  # Returns the map itself
  # ============================================================================
  getMap: () -> @_map

  # ============================================================================
  # Activates the 2D Display-
  # ============================================================================
  start: ->
    unless @_isRunning
      @_isRunning = yes
      @_mapParent.style.display = "block"

  # ============================================================================
  # Deactivates the 2D Display-
  # ============================================================================
  stop: ->
    @_isRunning = no
    @_mapParent.style.display = "none"

  # ============================================================================
  # Returns whether the display is active or not.
  # ============================================================================
  isRunning: ->
    @_isRunning

  # ============================================================================
  # Returns the DOM element associated with the display.
  # ============================================================================
  getCanvas: ->
    @_mapParent

  # ============================================================================
  # Returns the coordinates of the current center of the display.
  # ============================================================================
  getCenter: () ->
    # @_map.getCenter()
    [@_map.getCenter().lng, @_map.getCenter().lat]

  # ============================================================================
  # Implementation of setting the center of the current display.
  # ============================================================================
  setCenter: (lngLat, offset) ->
    # center marker ~ 2/3 vertically and horizontally
    if offset? # if offset passed to function
      # Calculate the offset
      bounds = @_map.getBounds()
      bounds_lat = bounds._northEast.lat - bounds._southWest.lat
      bounds_lng = bounds._northEast.lng - bounds._southWest.lng

      target =
        lon: parseFloat(lngLat.x) + offset.x * bounds_lng
        lat: parseFloat(lngLat.y) + offset.y * bounds_lat

      @_map.panTo target

    else # no offset? -> center marker
      @_map.panTo
        lon: lngLat.x
        lat: lngLat.y

  # ============================================================================
  # Implementation of zooming to a specifig area.
  # ============================================================================
  zoomToBounds: (minLng, minLat, maxLng, maxLat) ->
    @_map.fitBounds [
      [minLat, minLng],
      [maxLat, maxLng]
    ]



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _onWindowResize: (event) =>
    @_mapParent.style.width = $(HG.SpatialDisplay.CONTAINER.parentNode).width() + "px"
    @_mapParent.style.height = $(HG.SpatialDisplay.CONTAINER.parentNode).height() + "px"

  # ============================================================================
  _onClick: (event) =>
    @notifyAll "onClick", event.target