window.HG ?= {}

# ==============================================================================
# VIEW class
# set up and handle the change operation window
#   edit operations: ADD, UNI, SEP, CHB, CHN, DEL
# steps:
#   1) select old country/-ies
#   2) set geometry of new country/-ies
#   3) set name of new country/-ies
#   4) add change to hivent
# ==============================================================================

class HG.WorkflowWindow

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # operation = json object containing relevant information for window
  #   title:    window title
  #   numOld:   number of old countries selected (null, '1', '2', '1+', '2+')
  #   numNew:   number of new countries created (null, '1', '2', '1+', '2+')
  #   newGeo:   set geometry of new country/-ies? (bool)
  #   newName:  set name of new country/-ies? (bool)
  # ============================================================================

  constructor: (@_hgInstance, operation) ->
    # add to hg instance
    @_hgInstance.workflowWindow = @

    # include
    domElemCreator = new HG.DOMElementCreator

    @_currStep = -1   # start without marker
    @_totalSteps = 0

    ### MAIN WINDOW ###

    # main window sits on top of hg title, has more height (to account for extra space needed)
    @_mainWindow = domElemCreator.create 'div', 'ww-main-window'
    @_hgInstance.getTopArea().appendChild @_mainWindow


    ### WORKFLOW TABLE ###

    # table layout    |stepBack| step1 | step..| stepn |stepNext|
    # -------------------------------------------------------------------
    # graphRow        |        |  (O)--|--( )--|--( )  |    X   |   -> hg title
    # descriptionRow  |   (<)  | text1 | text..| textn |   (>)  |   + semi-transparent bg

    ## rows ##
    # create graph and description divs that dynamically adjust to their content
    @_graphRow = domElemCreator.create 'div', 'ww-graph-wrapper'
    @_mainWindow.appendChild @_graphRow

    @_descriptionRow = domElemCreator.create 'div', 'ww-description-wrapper'
    @_mainWindow.appendChild @_descriptionRow

    ## columns ##

    # back column
    @_graphRow.appendChild domElemCreator.create 'div', null, ['ww-graph-row', 'ww-button-col']
    backButtonParent = domElemCreator.create 'div', null, ['ww-description-row', 'ww-button-col']
    @_descriptionRow.appendChild backButtonParent

    # step columns
    @_stepDescr = []
    for step in operation.steps
      # only setup a column for steps that require user input
      if step.userInput
        @_graphRow.appendChild domElemCreator.create 'div', null, ['ww-graph-row', 'ww-step-col']
        descr = domElemCreator.create 'div', null, ['ww-description-row', 'ww-step-col', 'ww-description-cell']
        $(descr).html step.title
        @_descriptionRow.appendChild descr
        @_stepDescr.push $(descr)
        @_totalSteps++

    # next column
    abortButtonParent = domElemCreator.create 'div', 'abort-button-parent', ['ww-graph-row', 'ww-button-col']
    @_graphRow.appendChild abortButtonParent
    nextButtonParent = domElemCreator.create 'div', 'next-button-parent', ['ww-description-row', 'ww-button-col']
    @_descriptionRow.appendChild nextButtonParent

    ## graph bar ##
    # spans from first to last step
    # consists of:
    #   a horizontal bar spanning above the steps
    #   three disabled buttons indicating the steps
    #   one moving active marker stating the current step

    cells = $(@_graphRow).children().toArray()  # contains all graph cells
    cells.shift()     # removes first element (empty)
    cells.pop()       # removes last element (abort)

    # bounding box of svg canvas: spans all graph cells
    minX = $(cells[0]).position().left
    minY = $(cells[0]).position().top
    maxX = 0
    maxY = 0

    # position of circles: central positions [x,y] of each graph cell
    @_circlePos = []
    for cell in cells
      @_circlePos.push {
        'x': $(cell).position().left + $(cell).width()/2 - minX,
        'y': $(cell).position().top + $(cell).height()/2 - minY
      }
      maxX = $(cell).position().left + $(cell).width()
      maxY = $(cell).position().top + $(cell).height()

    # create canvas
    @_graphCanvas = d3.select @_graphRow
      .append 'svg'
      .attr 'id', 'graph-canvas'
      .style 'left', minX
      .style 'top', minY
      .style 'width', maxX-minX
      .style 'height', maxY-minY

    # draw horizontal line
    @_graphCanvas
      .append 'line'
      .attr 'id', 'graph-bar'
      .attr 'x1', @_circlePos[0].x
      .attr 'x2', @_circlePos[@_circlePos.length-1].x
      .attr 'y1', @_circlePos[0].y
      .attr 'y2', @_circlePos[@_circlePos.length-1].y

    # draw a circle for each cell
    rad = HGConfig.button_diameter.val / 2
    circles = @_graphCanvas.selectAll 'circle'
      .data @_circlePos
      .enter()
      .append 'circle'
      .classed 'graph-circle', true
      .attr 'cx', (pos) -> pos.x
      .attr 'cy', (pos) -> pos.y
      .attr 'r', rad

    ## identifying current step -> initially start with first step
    @_stepMarker = @_graphCanvas
      .append 'circle'
      .attr 'id', 'graph-step-marker'
      .attr 'cx', @_circlePos[0].x
      .attr 'cy', @_circlePos[0].y
      .attr 'r', rad*0.7
    @_stepDescr[0].addClass 'ww-current-description'


    ### BUTTONS ###

    # back button (= undo, disabled)
    @_undoButton = new HG.Button @_hgInstance,
      'undoStep', ['tooltip-bottom'],
      [
        {
          'id':       'normal'
          'tooltip':  "Undo / Go Back"
          'iconFA':   'chevron-left'
          'callback': 'onClick'
        }
      ]
    backButtonParent.appendChild @_undoButton.getDOMElement()

    # next button ( = ok = go to next step, disabled)
    # -> changes to OK button / "finish" state in last step
    @_nextButton = new HG.Button @_hgInstance,
      'nextStep', ['tooltip-bottom'],
      [
        {
          'id':       'normal'
          'tooltip':  "Done / Next Step"
          'iconFA':   'chevron-right'
          'callback': 'onNext'
        },
        {
          'id':       'finish'
          'tooltip':  "Finish Operation"
          'iconFA':   'check'
          'callback': 'onFinish'
        },
      ]
    nextButtonParent.appendChild @_nextButton.getDOMElement()

    # abort button
    @_abortButton = new HG.Button @_hgInstance,
      'abortOperation', ['button-abort', 'tooltip-bottom'],
      [
        {
          'id':       'normal'
          'tooltip':  "Abort Operation"
          'iconFA':   'times'
          'callback': 'onAbort'
        }
      ]
    abortButtonParent.appendChild @_abortButton.getDOMElement()

    # recenter the window
    posLeft = $('#title').position().left + $('#title').width()/2
    marginLeft = -$(@_mainWindow).width()/2         # half of own window width
    $(@_mainWindow).css 'left', posLeft
    $(@_mainWindow).css 'margin-left', marginLeft

    # initially no way to get forward
    @_nextButton.disable()


    ### INTERACTION ###

    # ----------------------------------------------------------------------------
    @_hgInstance.editOperation.onStepComplete @, () ->
      @_nextButton.enable()

    # ----------------------------------------------------------------------------
    @_hgInstance.editOperation.onStepIncomplete @, () ->
      @_nextButton.disable()

    # ----------------------------------------------------------------------------
    @_hgInstance.editOperation.onOperationComplete @, () ->
      @_nextButton.enable()
      @_nextButton.changeState 'finish'

    # ----------------------------------------------------------------------------
    @_hgInstance.editOperation.onOperationIncomplete @, () ->
      @_nextButton.disable()
      @_nextButton.changeState 'normal'

    # ----------------------------------------------------------------------------
    @_hgInstance.editOperation.onStepTransition @, (dir) ->
      @_currStep += dir
      unless @_currStep is -1
        @_moveStepMarker()
        @_highlightText()
      else
        @destroy()

    # ----------------------------------------------------------------------------
    @_hgInstance.editOperation.onFinish @, () ->
      @_abortButton.destroy()
      @_nextButton.destroy()
      @_undoButton.destroy()
      $(@_mainWindow)?.empty()
      $(@_mainWindow)?.remove()
      delete @_mainWindow?


  ##############################################################################
  #                            PRIVATE INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # graph manipulation
  _moveStepMarker: () ->
    @_stepMarker
      .transition()
      .attr 'cx', @_circlePos[@_currStep].x

  _highlightText: () ->
    d.removeClass 'ww-current-description' for d in @_stepDescr
    @_stepDescr[@_currStep].addClass 'ww-current-description'
