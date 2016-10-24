window.HG ?= {}

# ==============================================================================
# Base class for Hivent markers.
# HiventMarker provides basic functionality and interfaces.
# ==============================================================================
class HG.HiventMarker

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # Constructor
  # Initializes members and adds callbacks for state changes.
  # ============================================================================
  constructor: (hiventHandle, parentDiv) ->

    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback "onPositionChanged"
    @addCallback "onDestruction"

    @parentDiv = parentDiv

    @_hiventHandle = hiventHandle

  # ============================================================================
  hgInit: (hgInstance) ->
    @_hgInstance = hgInstance

  # ============================================================================
  # Returns the associated HiventHandle. Multiple HiventMarkers may share the
  # same HiventHandle.
  # ============================================================================
  getHiventHandle: ->
    @_hiventHandle

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _destroy: =>
    @notifyAll "onDestruction"
    @_hiventHandle.inActiveAll()

