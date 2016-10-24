window.HG ?= {}

##############################################################################
# nowMarker shows the current date above the timeline

class HG.NowMarker

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->


  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add module to HG instance
    @_hgInstance.nowMarker = @

    # include
    domElemCreator = new HG.DOMElementCreator

    ### SETUP UI ###

    # create now marker
    @_nowMarker = domElemCreator.create 'div', 'nowMarker', 'no-text-select'
    @_hgInstance.getBottomArea().appendChild @_nowMarker


    @_hgInstance.onAllModulesLoaded @, () =>

      # initialize position and content
      @_resetPosition()
      @_upDate @_hgInstance.timeController.getNowDate()

      ### INTERACTION ###

      # window: update position on resize
      $(window).resize =>
        @_resetPosition()

      # update date
      @_hgInstance.timeController.onNowChanged @, (date) =>
        @_upDate date


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _upDate: (date) ->
    $(@_nowMarker).html date.format @_hgInstance.config.dateFormat

  # ============================================================================
  _resetPosition: (pos) ->
    @_nowMarker.style.left = (window.innerWidth / 2) + "px"