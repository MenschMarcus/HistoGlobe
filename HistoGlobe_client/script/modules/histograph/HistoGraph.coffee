window.HG ?= {}

##############################################################################
# VIEW MODULE
# graph above the timeline that shows the history of countries
# and historical events (hivents) that changed them
# visualisation based on d3 (?)
##############################################################################

class HG.HistoGraph

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onHeightChanged'

    # handle config
    defaultConfig =
      depth: 1

    @_config = $.extend {}, defaultConfig, config

    # include
    @_domElemCreator = new HG.DOMElementCreator

    # init variables
    @_numAreas = 0
    @_height

  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add to HG instance
    @_hgInstance.histoGraph = @

    # DOM Elements
    @_bottomArea =  @_hgInstance.getBottomArea()
    @_tlSlider =    @_hgInstance.timeline.getSlider()
    @_tlMain =      $('#tl-main, #tl-wrapper')

    # create transparent center line
    # not inside HistoGraph, but centered on top of it
    # -> same level as NowMarker
    @_centerLine = @_domElemCreator.create 'div', 'histograph-centerline', ['no-text-select']
    @_bottomArea.appendChild @_centerLine

    # create canvas itself
    @_canvas = d3
      .select @_tlSlider
      .append 'svg'
      .attr 'id', 'histograph-canvas'

    # put an arbitrary circle on the graph

  # ============================================================================
  getHeight: () -> @_height
  getCanvas: () -> @_canvas


  # ============================================================================
  # fold / onfold HistoGraph
  # idea: if at least one area is shown on the graph, it it visible
  #       total height = INIT_HEIGHT (it always needs it for padding top / bottom)
  #                    + AREA_HEIGHT (height per area shown)
  # some elements should be animated up (the ones with background
  # some can just be height-changed, because it does not appear together
  # this is very imperformant on Chrome :(

  updateHeight: (direction) ->
    @_numAreas += direction

    # status variables: are animations complete to fire callback?
    ani1complete = no
    ani2complete = no

    # animation 1: (un)fold HistoGraph
    @_height = @_numAreas*AREA_HEIGHT
    @_height += INIT_HEIGHT if @_numAreas > 0
    $(@_centerLine).animate {height: @_height}, HGConfig.fast_animation_time.val, () =>
      $(@_canvas[0]).height @_height
      ani1complete = yes
      if ani2complete
        ani1complete = no
        @notifyAll 'onHeightChanged'

    # animation 2: increase the height of the timeline
    tlHeight = HGConfig.timeline_height.val + @_height
    # bad hack: since two DOM elements are in @_tlMain, the success callback
    # would also be called twice, this has to be prevented
    # => count number of callback calls
    numCalls = 0
    @_tlMain.animate {height: tlHeight}, HGConfig.fast_animation_time.val, () =>
      $(@_tlSlider).height tlHeight
      $(@_bottomArea).height tlHeight
      @_hgInstance.updateLayout()
      numCalls++
      if numCalls is 2
        ani2complete = yes
        if ani1complete
          ani2complete = no
          @notifyAll 'onHeightChanged'



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################


  ##############################################################################
  #                            STATIC INTERFACE                               #
  ##############################################################################

  INIT_HEIGHT =  40    # px, for padding above and below
  AREA_HEIGHT =  60    # px
