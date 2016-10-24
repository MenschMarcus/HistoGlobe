window.HG ?= {}

class HG.ControlButtonsTop

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
  #   in modules.json in module 'ControlButtonsTop' set id to true
  # ============================================================================
  constructor: (config) ->
    defaultConfig =
      zoom :          true
      fullscreen :    true
      highContrast :  false
      minLayout :     false
      graphButton :   false

    @_config = $.extend {}, defaultConfig, config

  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add module to HG instance
    @_hgInstance.controlButtonsTop = @

    # idea: module "ControlButtons" a "ButtonArea" consisting of buttons
    @_buttonArea = new HG.ButtonArea @_hgInstance,
    {
      'id':           'controlButtonsTop',
      'posX':         'left',
      'posY':         'bottom',
      'orientation':  'vertical'
    }
    @_hgInstance.getTopArea().appendChild @_buttonArea.getDOMElement()

    # init predefined buttons
    for id, enable of @_config
      if enable
        switch id                 # selects class of required button

          when 'zoom' then (
            @_buttonArea.addButton new HG.Button(@_hgInstance,
              'zoomIn', null,
              [
                {
                  'id':       'normal',
                  'tooltip':  "Zoom In",
                  'iconFA':   'plus',
                  'callback': 'onClick'
                }
              ]), 'zoom-group'  # group name
            @_buttonArea.addButton new HG.Button(@_hgInstance,
              'zoomOut', [],
              [
                {
                  'id':       'normal',
                  'tooltip':  "Zoom Out",
                  'iconFA':   'minus',
                  'callback': 'onClick'
                }
              ]), 'zoom-group' # group name
            )

            # fullscreen mode
          when 'fullscreen' then (
            @_buttonArea.addButton new HG.Button @_hgInstance,
              'fullscreen', [],
              [
                {
                  'id':       'normal',
                  'tooltip':  "Fullscreen",
                  'iconFA':   'expand',
                  'callback': 'onEnter'
                },
                {
                  'id':       'fullscreen',
                  'tooltip':  "Leave Fullscreen",
                  'iconFA':   'compress',
                  'callback': 'onLeave'
                }
              ]
          )

          # high contrast mode
          when 'highContrast' then (
            @_buttonArea.addButton new HG.Button @_hgInstance,
              'highContrast', [],
              [
                {
                  'id':       'normal',
                  'tooltip':  "High-Contrast Mode",
                  'iconFA':   'adjust',
                  'callback': 'onEnter'
                },
                {
                  'id':       'high-contrast',
                  'tooltip':  "Normal Color Mode",
                  'iconFA':   'adjust',
                  'callback': 'onLeave'
                }
              ]
          )

          # minimal layout mode
          when 'minLayout' then (
            @_buttonArea.addButton new HG.Button @_hgInstance,
              'minLayoutButton', [],
              [
                {
                  'id':       'normal',
                  'tooltip':  "Simplify User Interface",
                  'iconFA':   'sort-desc',
                  'callback': 'onRemoveGUI'
                },
                {
                  'id':       'min-layout',
                  'tooltip':  "Restore Interface",
                  'iconFA':   'sort-asc',
                  'callback': 'onOpenGUI'
                }
              ]
          )

          # graph mode
          when 'graph' then (
            # 1. init button
            @_buttonArea.addButton new HG.Button @_hgInstance,
              'graph', [],
              [
                {
                  'id':       'normal',
                  'tooltip':  "Show Alliances",
                  'iconFA':   'share-alt',
                  'callback': 'onShow'
                },
                {
                  'id':       'graph',
                  'tooltip':  "Hide Alliances",
                  'iconFA':   'share-alt',
                  'callback': 'onHide'
                }
              ]
          )


    ### INTERACTION ###

    # fullscreen
    @_hgInstance.buttons.fullscreen?.onEnter @, (btn) =>
      body = document.body
      if (body.requestFullscreen)
        body.requestFullscreen()
      else if (body.msRequestFullscreen)
        body.msRequestFullscreen()
      else if (body.mozRequestFullScreen)
        body.mozRequestFullScreen()
      else if (body.webkitRequestFullscreen)
        body.webkitRequestFullscreen()
      btn.changeState 'fullscreen'

    @_hgInstance.buttons.fullscreen?.onLeave @, (btn) =>
      body = document.body
      if (body.requestFullscreen)
        document.cancelFullScreen()
      else if (body.msRequestFullscreen)
        document.msExitFullscreen()
      else if (body.mozRequestFullScreen)
        document.mozCancelFullScreen()
      else if (body.webkitRequestFullscreen)
        document.webkitCancelFullScreen()
      btn.changeState 'normal'

    # high contrast mode
    @_hgInstance.buttons.highContrast?.onEnter @, (btn) =>
      $(@_hgInstance.getContainer()).addClass 'highContrast'
      btn.changeState 'high-contrast'

    @_hgInstance.buttons.highContrast?.onLeave @, (btn) =>
      $(@_hgInstance.getContainer()).removeClass 'highContrast'
      btn.changeState 'normal'

    # min layout mode
    @_hgInstance.buttons.minLayoutButton?.onRemoveGUI @, (btn) =>
      $(@_hgInstance.getContainer()).addClass 'minGUI'
      btn.changeState 'min-layout'

    @_hgInstance.buttons.minLayoutButton?.onOpenGUI @, (btn) =>
      $(@_hgInstance.getContainer()).removeClass 'minGUI'
      btn.changeState 'normal'

    # graph on globe
    @_hgInstance.buttons.graph?.onShow @, (btn) =>
      $(@_hgInstance.getContainer()).addClass 'minGUI'
      btn.changeState 'min-layout'

    @_hgInstance.buttons.graph?.onHide @, (btn) =>
      $(@_hgInstance.getContainer()).removeClass 'minGUI'
      btn.changeState 'normal'



  # ============================================================================
  moveUp: (height) ->
    @_buttonArea.moveVertical height

  moveDown: (height) ->
    @_buttonArea.moveVertical -height
