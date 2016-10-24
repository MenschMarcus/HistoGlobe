window.HG ?= {}

class HG.ControlButtonsTimeline

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # for new control button:
  #   define identifier (id) for control (e.g. 'fullscreen')
  #   -> new entry in default config in constructor (default set false 'false')
  #   set config in switch-when with new id
  #     1. init button itself
  #     2. set functionality of the button (listen to own callback)
  # if control button is used:
  #   in modules.json in module 'ControlButtons' set id to true
  # ============================================================================
  constructor: (config) ->
    defaultConfig =
      zoom :          true

    @_config = $.extend {}, defaultConfig, config

  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add module to HG instance
    @_hgInstance.controlButtonsTimeline = @

    # create button area for all control buttons of the timeline
    zoomButtonsArea = new HG.ButtonArea @_hgInstance,
    {
      'id':           'controlButtonsTimeline',
      'posX':         'left',
      'posY':         'right',
      'orientation':  'horizontal'
    }
    @_hgInstance.getBottomArea().appendChild zoomButtonsArea.getDOMElement()

    # create zoom buttons
    if @_config.zoom

      zoomButtonsArea.addButton new HG.Button(@_hgInstance,
        'timelineZoomOut', ['button-no-background', 'tooltip-top'],
        [
          {
            'id':         'normal',
            'tooltip':    "Zoom Out Timeline",
            'iconFA':     'minus'
            'callback':   'onClick'
          }
        ]),'timelineZoom'

      zoomButtonsArea.addButton new HG.Button(@_hgInstance,
        'timelineZoomIn', ['button-no-background', 'tooltip-top'],
        [
          {
            'id':         'normal',
            'tooltip':    "Zoom In Timeline",
            'iconFA':     'plus'
            'callback':   'onClick'
          }
        ]), 'timelineZoom'