window.HG ?= {}

# ============================================================================
# <div> element representing an on/off switch (default: on)

class HG.Switch

  # ============================================================================
  constructor: (@_hgInstance, id=null, classes=[]) ->

    # add to switch object of HG instance
    @_hgInstance.switches = {} unless @_hgInstance.switches?
    @_hgInstance.switches[id] = @

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onSwitchOn'
    @addCallback 'onSwitchOff'

    # init state variables
    state = on

    classes.unshift 'toggle-on-off'
    classes.unshift 'switch-on'

    # create dom element
    domElemCreator = new HG.DOMElementCreator
    elem = domElemCreator.div id, classes

    # toggle
    $(elem).click () =>

      # switch off
      if state is on
        $(elem).removeClass 'switch-on'
        $(elem).addClass 'switch-off'
        state = off
        @notifyAll 'onSwitchOff'

      # switch on
      else # state is off
        $(elem).removeClass 'switch-off'
        $(elem).addClass 'switch-on'
        state = on
        @notifyAll 'onSwitchOn'

  # ============================================================================
  getDOMElement: () ->        @_elem

  # ============================================================================
  destroy: () ->              $(@_elem).remove()
  remove: () ->               @destroy()
  delete: () ->               @destroy()