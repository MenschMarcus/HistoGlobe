window.HG ?= {}

# debug output?

class HG.AreaController

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  constructor: (config) ->

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onCreateArea'
    @addCallback 'onDestroyArea'
    @addCallback 'onSelectArea'
    @addCallback 'onDeselectArea'

    # handle config
    defaultConfig = {}
    @_config = $.extend {}, defaultConfig, config

    # init members
    @_areaHandles = []            # all areas in HistoGlobe ((in)visible, (un)selected, ...)
    @_maxSelections = 1           # 1 = single-selection mode, n = multi-selection mode


  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add module to HG instance
    @_hgInstance.areaController = @



  # ============================================================================
  # Receive a new AreaHandle (from EditMode and DatabaseInterface) and add it to
  # the list and tell the view about it
  # ============================================================================

  addAreaHandle: (areaHandle) ->
    @_areaHandles.push areaHandle

    # divert "addAreaHandle" to all the view classes
    @notifyAll 'onCreateArea', areaHandle

    # listen to destruction callback and tell everybody about it
    areaHandle.onDestroy @, () =>
      @_areaHandles.splice(@_areaHandles.indexOf(areaHandle), 1)
      @notifyAll 'onDestroyArea', areaHandle

    # listen to select/deselect callback and tell everybody about it
    areaHandle.onSelect @, () =>
      @notifyAll 'onSelectArea', areaHandle

    areaHandle.onDeselect @, () =>
      @notifyAll 'onDeselectArea', areaHandle


  # ============================================================================
  # set / get Single- and Multi-Selection Mode
  # -> how many areas can be selected at the same time?
  # ============================================================================

  getMaxNumOfSelections: () -> @_maxSelections

  # ------------------------------------------------------------------------
  enableMultiSelection: (num) ->

    # error handling: must be a number and can not be smaller than 1
    if (num < 1) or (isNaN num)
      return console.error "There can not be less than 1 area selected"

    # set maximum number of selections
    @_maxSelections = num

  # ------------------------------------------------------------------------
  disableMultiSelection: () ->

    # restore single-selection mode
    @_maxSelections = 1


  # ============================================================================
  # GETTER for areas
  # ============================================================================

  getAreaHandles: () ->
    @_areaHandles

  # ----------------------------------------------------------------------------
  getAreaHandle: (id) ->
    for areaHandle in @_areaHandles
      area = areaHandle.getArea()
      if area.id is id
        return areaHandle
    return null

  # ----------------------------------------------------------------------------
  getSelectedAreaHandles: () ->
    selectedAreas = []
    for areaHandle in @_areaHandles
      selectedAreas.push areaHandle if areaHandle.isSelected()
    selectedAreas