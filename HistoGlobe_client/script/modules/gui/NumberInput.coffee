window.HG ?= {}

# ============================================================================
# <input type='number' name='id'>

class HG.NumberInput

  # ============================================================================
  constructor: (@_hgInstance, id=null, classes=[]) ->

    console.error "Please enter an id for the number input field, it is required" unless id?

    # add to HG instance
    @_hgInstance.inputs = {} unless @_hgInstance.inputs?
    @_hgInstance.inputs[id] = @

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onChange'

    # create dom element
    domElemCreator = new HG.DOMElementCreator
    elem = domElemCreator.create 'input', id, classes, [['type', 'number'], ['name', id]]

    # change
    $(elem).on 'keyup mouseup', (e) =>
      # tell everyone the new value
      @notifyAll 'onChange', e.currentTarget.value

  # ============================================================================
  getDOMElement: () ->        @_elem

  # ============================================================================
  destroy: () ->              $(@_elem).remove()
  remove: () ->               @destroy()
  delete: () ->               @destroy()