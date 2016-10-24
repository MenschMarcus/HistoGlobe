window.HG ?= {}

# ============================================================================
# <input type='text' name='id'>

class HG.TextInputArea

  # ============================================================================
  constructor: (@_hgInstance, id=null, classes=[], dimensions=[]) ->

    console.error "Please enter an id for the text input field, it is required" unless id?

    # add to HG instance
    @_hgInstance.inputs = {} unless @_hgInstance.inputs?
    @_hgInstance.inputs[id] = @

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onChange'

    # create dom element
    domElemCreator = new HG.DOMElementCreator
    classes.unshift 'hg-input'
    @_elem = domElemCreator.create 'textarea', id, classes, [['rows', dimensions[0]], ['cols', dimensions[1]], ['name', id]]

    # change
    $(@_elem).on 'keyup mouseup', (e) =>
      # tell everyone the new value
      @notifyAll 'onChange', e.currentTarget.value


  # ============================================================================
  getDOMElement: () ->        @_elem

  # ============================================================================
  setPlaceholder: (text) ->   $(@_elem).attr 'placeholder', text

  # ----------------------------------------------------------------------------
  getValue: () ->             @_elem.value
  getText: () ->              @getValue()

  # ----------------------------------------------------------------------------
  setValue: (text) ->         @_elem.value = text
  setText: (text) ->          @setValue text