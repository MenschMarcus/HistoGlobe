window.HG ?= {}

# ==============================================================================
# Base class for displays, i.e. 2D Map and 3D Globe. Provides basic interface
# which is implemented in the derived classes.
# ==============================================================================
class HG.SpatialDisplay

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # hgInit is called by the central HistoGlobe object.
  # Stores basic information and registeres callback listeners.
  # ============================================================================
  hgInit: (@_hgInstance) ->
    # Store the DOM element reserved for displaying map/globe
    HG.SpatialDisplay.CONTAINER ?= @_hgInstance.getSpatialCanvas()
    @overlayContainer = null

    # If all modules are loaded, check whether the module "HiventInfoAtTag" is
    # present and if so, register for notification on URL hash changes.
    @_hgInstance.onAllModulesLoaded @, () =>

      @_hgInstance.hiventInfoAtTag?.onHashChanged @, (key, value) =>
        # If the passed URL hash key is "bounds", zoom to the specified area.
        if key is "bounds"
          minMax = value.split ";"
          mins = minMax[0].split ","
          maxs = minMax[1].split ","
          @zoomToBounds(mins[0], mins[1], maxs[0], maxs[1])


  # ============================================================================
  # Focus a specific Hivent. "setCenter" is implemented by derived classes.
  # ============================================================================
  focus: (hivent) -> # hivent coords and offset coords
    @setCenter {x: hivent.long, y: hivent.lat}, {x: 0.07, y: 0.2}

  # ============================================================================
  # Interface for zooming to specific bounds. The actual implementation can be
  # found in the derived classes
  # ============================================================================
  zoomToBounds: (minLong, minLat, maxLong, maxLat) ->


  ##############################################################################
  #                             STATIC MEMBERS                                 #
  ##############################################################################

  @Z_INDEX = 0
  @CONTAINER = null
