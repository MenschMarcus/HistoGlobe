window.HG ?= {}

# ==============================================================================
# helper class to make text fields editable
# ==============================================================================
class HG.Editable


  ##############################################################################
  #                AWESOME STUFF I COPIED FROM OTHER PEOPLE                    #
  ##############################################################################

  # ============================================================================
  makeEditable: (element) ->
    $(element).inlineEdit(editableHoverInput, editableInputConnector)

  # ============================================================================
  ### MAKE TEXT EDITABLE ###
  # credits to: egstudio
  # http://jsfiddle.net/egstudio/aFMWg/1/
  # thank you very much

  editableHoverInput = $('<input name="temp" type="text" class="editable-hover-input" />')
  editableInputConnector = $('.editable-replace-input')

  $('body').append '<form><input class="editable-replace-input" type="hidden" name="hiddenField" /></form>'

  $.fn.inlineEdit = (editableHoverInput, editableInputConnector) ->

    $(@).hover () ->
      $(@).addClass('hover-input')
    , () ->
      $(@).removeClass('hover-input')

    $(@).click () ->

      elem = $(@)

      # adapt hover input to its connector element
      editableHoverInput.copyCSS elem
      editableHoverInput.val elem.text()

      elem.hide()
      elem.after(editableHoverInput)
      editableHoverInput.focus()

      editableHoverInput.on 'keydown keyup click each', (e) ->
        width = Math.max 1, (editableHoverInput.val().length)*1.25
        editableHoverInput.attr 'size', width

      editableHoverInput.blur () ->

        editableInputConnector.val($(@).val()).change()
        elem.text $(@).val()

        $(@).remove()
        elem.show()

  ### COPY STYLE ###
  # credits to: Dakota and Servy
  # https://stackoverflow.com/questions/754607/can-jquery-get-all-css-styles-associated-with-an-element/6416527#6416527
  # thank you very much!

  $.fn.copyCSS = (source) ->
    styles = $(source).getStyleObject()
    @css styles

  (($) ->
    $.fn.getStyleObject = ->
      dom = @get(0)
      style = undefined
      returns = {}
      if window.getComputedStyle

        camelize = (a, b) ->
          `var prop`
          b.toUpperCase()

        style = window.getComputedStyle dom, null
        i = 0
        l = style.length
        while i < l
          prop = style[i]
          camel = prop.replace(/\-([a-z])/g, camelize)
          val = style.getPropertyValue prop
          returns[camel] = val
          i++
        return returns
      if style = dom.currentStyle
        for prop of style
          returns[prop] = style[prop]
        return returns
      @css()
    return
  ) jQuery