
window.HG ?= {}

class HG.NewNameTool

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_hgInstance, initData, allowNameChange=yes) ->

    @_hgInstance.newNameTool = @

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onChangeShortName'
    @addCallback 'onChangeFormalName'
    @addCallback 'onSubmit'

    # includes / variables
    @_domElemCreator = new HG.DOMElementCreator
    @_map = @_hgInstance.map.getMap()
    @_histoGraph = @_hgInstance.histoGraph
    @_viewCenter = @_map.getCenter()


    ### SETUP UI ###

    # PROBLEM:
    # I need a text field with the following three characterstics:
    # 1. it needs to be in the coordinate system of the world
    # 2. it needs to be draggable
    # 3. its text needs to be editable

    # POSSIBLE SOLUTIONS:
    # A) use Leaflet element
    #   (+) in coordinate system
    #   (-) no element is both draggable and editable
    # => not possible without reimplementation of leaflet features!
    # B) use HTML text input in the view point
    #   (+) draggable and editable
    #   (-) not in coordinate system
    #   (-) position does not automatically update on zoom / pan of the map
    # => possible, but hard...

    ## draggable wrapper for whole name tool

    @_wrapper = @_domElemCreator.create 'div', 'new-name-wrapper', ['hg-input']
    @_hgInstance.getTopArea().appendChild @_wrapper


    ## editable input field for short name

    @_shortNameInput = new HG.TextInput @_hgInstance, 'newShortName', ['new-name-input']
    $(@_shortNameInput.getDOMElement()).removeClass 'hg-input' # it is not a normal input field

    # set either the text that is given (to just accept it)
    if initData.name
      @_shortNameInput.setText initData.name.shortName

    # or have only a placeholder + give initial size
    else
      @_shortNameInput.setPlaceholder 'name'
      $(@_shortNameInput).attr 'size', INIT_SIZE


    @_wrapper.appendChild @_shortNameInput.getDOMElement()


    ## editable input field for formal name

    @_formalNameInput = new HG.TextInput @_hgInstance, 'newFormalName', ['new-name-input']
    $(@_formalNameInput.getDOMElement()).removeClass 'hg-input' # it is not a normal input field

    # set either the text that is given (to just accept it)
    if initData.name
      @_formalNameInput.setText initData.name.formalName

    # or have only a placeholder + give initial size
    else
      @_formalNameInput.setPlaceholder 'formal name'
      $(@_formalNameInput).attr 'size', INIT_SIZE

    @_wrapper.appendChild @_formalNameInput.getDOMElement()


    # save short and formal name DOM objects for combined processing
    @_nameInputs = $('.new-name-input')

    # if name can not be changed, add additional class to input elements and
    # make readonly
    if not allowNameChange
      @_nameInputs.attr 'readonly', true
      @_nameInputs.addClass 'no-value-change'


    ## autocomplete wrapper to choose a suggestion
    @_autocompleteWrapper = @_domElemCreator.create 'div', 'autocomplete-wrapper'
    @_wrapper.appendChild @_autocompleteWrapper

    # inline spacer inside to get actual width of the element
    @_autocompleteSpacer = @_domElemCreator.create 'div', 'autocomplete-spacer'
    @_autocompleteWrapper.appendChild @_autocompleteSpacer
    $(@_autocompleteSpacer).hide()


    # setup autocomplete
    if initData.nameSuggestions

      # for short name: if selected, also fill formal name
      shortNameSuggestions = []
      for name in initData.nameSuggestions
        shortNameSuggestions.push {
          # I need "label" and "value" for jQuery UI
          label:  name.shortName
          value:  name.shortName
          formal: name.formalName
        }

      $(@_shortNameInput.getDOMElement()).autocomplete {
        source: shortNameSuggestions
        appendTo: '#autocomplete-spacer'
        open: (evt, ui) =>
          $(@_autocompleteSpacer).show()
          $(@_autocompleteWrapper).addClass 'sep-border-top'
          @_resize()
        close: (evt, ui) =>
          $(@_autocompleteSpacer).hide()
          $('#autocomplete-spacer>ul>li').width 0 # reset width to accurately calculate width
          $(@_autocompleteWrapper).removeClass 'sep-border-top'
          @_resize()
        select: (evt, ui) =>
          @_shortNameInput.setText ui.item.value
          @_formalNameInput.setText ui.item.formal
          @_resize()
          @_okButton.enable()
      }

      # for formal name: if selected, only fill formal, do not override short name
      formalNameSuggestions = []
      for name in initData.nameSuggestions
        formalNameSuggestions.push {
          # I need "label" and "value" for jQuery UI
          label:  name.formalName
          value:  name.formalName
        }

      $(@_formalNameInput.getDOMElement()).autocomplete {
        source: formalNameSuggestions
        appendTo: '#autocomplete-spacer'
        open: (evt, ui) =>
          $(@_autocompleteSpacer).show()
          @_resize()
        close: (evt, ui) =>
          $(@_autocompleteSpacer).hide()
          @_resize()
        select: (evt, ui) =>
          @_formalNameInput.setText ui.item.value
          @_resize()
          @_okButton.enable() if @_shortNameInput.getText()
      }


    # set initial position of wrapper = representative point of areas territory
    posPx = @_map.latLngToContainerPoint initData.oldPoint.latLng()
    $(@_wrapper).css 'left', posPx.x
    $(@_wrapper).css 'top',  posPx.y


    ## OK button to confirm selection

    @_okButton = new HG.Button @_hgInstance,
      'newNameOK', ['confirm-button'],
      [
        {
          'iconFA':   'check'
        }
      ]
    @_okButton.disable() if (not @_shortNameInput.getText()) or (not @_formalNameInput.getText())
    @_wrapper.appendChild @_okButton.getDOMElement()

    # set initial size
    @_resize()


    ### INTERACTION ###

    # seamless interaction
    @_makeDraggable()
    $(@_nameInputs).on 'keydown keyup click each', @_resize
    @_map.on 'drag',    @_respondToMapDrag
    @_map.on 'zoomend', @_respondToMapZoom

    # focus wrappper on focus input elements
    $(@_nameInputs).on 'focus', () =>
      $(@_wrapper).addClass 'new-name-wrapper-focus'

    $(@_nameInputs).on 'focusout', () =>
      $(@_wrapper).removeClass 'new-name-wrapper-focus'

    # user types name => name changes => notify
    # enable / disable OK button if name is complete
    $(@_shortNameInput.getDOMElement()).on 'keyup mouseup', (e) =>
      @notifyAll 'onChangeShortName', @_shortNameInput.getText()
      if @_shortNameInput.getText() and @_formalNameInput.getText()
        @_okButton.enable()
      else
        @_okButton.disable()

    $(@_formalNameInput.getDOMElement()).on 'keyup mouseup', (e) =>
      @notifyAll 'onChangeFormalName', @_formalNameInput.getText()
      if @_shortNameInput.getText() and @_formalNameInput.getText()
        @_okButton.enable()
      else
        @_okButton.disable()


    # user clicks OK button => submit name and position
    @_okButton.onClick @, () =>

      # get center coordinates
      center = new L.Point $(@_wrapper).position().left, $(@_wrapper).position().top

      # get name user has typed
      newName = {
        shortName:  @_shortNameInput.getText()
        formalName: @_formalNameInput.getText()
      }

      # return new data by preserving original point and name suggestions
      # (for further processing)
      newData = {
        nameSuggestions:  initData.nameSuggestions
        name:             newName
        oldPoint:         initData.oldPoint
        newPoint:         new HG.Point @_map.containerPointToLatLng center
      }
      @notifyAll 'onSubmit', newData


  # ============================================================================
  destroy: () ->

    # remove interaction: detach event handlers from map
    @_map.off 'zoomend', @_respondToMapZoom
    @_map.off 'drag',    @_respondToMapDrag

    # cleanup UI
    @_okButton.remove()
    @_shortNameInput.remove()
    $(@_wrapper).remove()

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  # Compute the actual width that is necessary to show all the elements and then
  # set their width accordingly.
  # It was f*** hard to come up with a div layout that allows for centering
  # both name inputs and the suggestions. Please no major changes to this
  # function and also to the CSS layout in NewNameTool.less
  # ============================================================================

  _resize: (e) =>

    # get width that elements actually need
    newWidth = Math.max(
        MIN_WIDTH,
        $(@_shortNameInput.getDOMElement()).width(),    # actual width of short name
        $(@_formalNameInput.getDOMElement()).width(),   # actual width of formal name
        $('#autocomplete-spacer>ul>li').width()         # actual width of autocomplete suggestions
      )

    # set the new width
    $(@_shortNameInput.getDOMElement()).width newWidth
    $(@_formalNameInput.getDOMElement()).width newWidth
    $(@_autocompleteWrapper).width newWidth
    $('#autocomplete-spacer>ul>li').width newWidth

    # recenter accordingly
    $(@_wrapper).css 'margin-top',  -($(@_shortNameInput.getDOMElement()).height() / 2)
    $(@_wrapper).css 'margin-left', -($(@_shortNameInput.getDOMElement()).width()  / 2)


  # ============================================================================
  # preparation functions

  # ----------------------------------------------------------------------------
  _makeDraggable: () ->
    # make input field draggable
    # this code snippet does MAGIC !!!
    # credits to: A. Wolff
    # http://stackoverflow.com/questions/22814073/how-to-make-an-input-field-draggable
    # http://jsfiddle.net/9SPvQ/2/
    $(@_wrapper).draggable start: (event, ui) ->
      $(this).data 'preventBehaviour', true

    $(@_nameInputs).on 'mousedown', (e) =>
      mdown = document.createEvent 'MouseEvents'
      mdown.initMouseEvent 'mousedown', true, true, window, 0, e.screenX, e.screenY, e.clientX, e.clientY, true, false, false, true, 0, null
      @_wrapper.dispatchEvent mdown
      return # for some reason this has to be there ?!?

    $(@_nameInputs).on 'click', (e) =>
      if $(@_wrapper).data 'preventBehaviour'
        e.preventDefault()
        $(@_wrapper).data 'preventBehaviour', false
      return # for some reason this has to be there ?!?

  # ----------------------------------------------------------------------------
  _respondToMapDrag: (e) =>
    # this is probably more complicated than necessary - but it works :)
    # get movement of center of the map (as reference)
    mapOld = @_viewCenter
    mapNew = @_map.getCenter()
    ctrOld = @_map.latLngToContainerPoint mapOld
    ctrNew = @_map.latLngToContainerPoint mapNew
    ctrDist = [
      (ctrNew.x - ctrOld.x),
      (ctrNew.y - ctrOld.y)
    ]
    # project movement to wrapper
    inputOld = $(@_wrapper)
    inputNew = L.point(
      (inputOld.position().left) - ctrDist[0], # x
      (inputOld.position().top) - ctrDist[1]  # y
    )
    $(@_wrapper).css 'left', inputNew.x
    $(@_wrapper).css 'top', inputNew.y
    # refresh
    @_viewCenter = mapNew

  # ----------------------------------------------------------------------------
  _respondToMapZoom: (e) =>
    @_viewCenter = @_map.getCenter() # to prevent jumping label on drag after zoom
    # TODO: get to work
    # zoomCenter = @_map.latLngToContainerPoint e.target._initialCenter
    # zoomFactor = @_map.getScaleZoom()
    # windowCenterStart = @_inputCenter

    # windowCenterEnd = L.point(
    #   zoomCenter.x - ((zoomCenter.x - windowCenterStart.x) / zoomFactor),
    #   zoomCenter.y - ((zoomCenter.y - windowCenterStart.y) / zoomFactor)
    # )

    # console.log e
    # console.log zoomCenter
    # console.log zoomFactor
    # console.log windowCenterStart
    # console.log windowCenterEnd


  # ============================================================================
  INIT_SIZE = 7
  MIN_WIDTH = 100
