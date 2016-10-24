window.HG ?= {}

# DEBUG: take out if not needed anymore
TEST_BUTTON = no

# ==============================================================================
# EditMode registers clicks on edit operation buttons -> init operation
#   manage operation window (init, send data, get data)
#   handle communication with backend (get data, send data)
#
# hierachy: EditMode -> EditOperation -> EditOperationStep -> action
# ==============================================================================


class HG.EditMode

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    # init config
    defaultConfig =
      editOperationsPath: 'common/editOperations.json'

    @_config = $.extend {}, defaultConfig, config

    # init members
    @_areaEditMode = off


  # ============================================================================
  hgInit: (@_hgInstance) ->

    # add to HG instance
    @_hgInstance.editMode = @

    # append pathes
    @_config.editOperationsPath = @_hgInstance.config.configPath + @_config.editOperationsPath


    ############################################################################
    if TEST_BUTTON
      testButton = new HG.Button @_hgInstance, 'test', null, [{'iconFA': 'question','callback': 'onClick'}]
      $(testButton.getDOMElement()).css 'position', 'absolute'
      $(testButton.getDOMElement()).css 'bottom', '0'
      $(testButton.getDOMElement()).css 'right', '0'
      $(testButton.getDOMElement()).css 'z-index', 100
      @_hgInstance.getTopArea().appendChild testButton.getDOMElement()
      @_testButton = @_hgInstance.buttons.test
      @_testButton.onClick @, () =>

        # TEST PLAYGROUND START HERE
        @_hgInstance.databaseInterface.saveHistoricalOperation(42,99)
        # examplePath = @_hgInstance.config.configPath + 'common/example.json'

        # $.getJSON examplePath, (request) =>
        #   @_hgInstance.databaseInterface.testSave request


        # TEST PLAYGROUND END HERE
    ############################################################################


    # init everything
    $.getJSON(@_config.editOperationsPath, (operationConfig) =>

      # load operations
      @_editOperations = new HG.ObjectArray operationConfig # all possible operations

      # setup edit button area and add editButton to it
      # is always there, never has to be destructed
      @_editButtonArea = new HG.ButtonArea @_hgInstance,
      {
        'id':           'editButtons'
        'posX':         'right'
        'posY':         'top'
        'orientation':  'horizontal'
        'direction':    'prepend'
      }
      @_hgInstance.getTopArea().appendChild @_editButtonArea.getDOMElement()

      @_editButton = new HG.Button @_hgInstance,
        'editMode', ['tooltip-left'],
        [
          {
            'id':       'normal',
            'tooltip':  "Enter Edit Mode",
            'iconFA':   'pencil',
            'callback': 'onEnter'
          },
          {
            'id':       'edit-mode',
            'tooltip':  "Leave Edit Mode",
            'iconFA':   'pencil',
            'callback': 'onLeave'
          }
        ]
      @_editButtonArea.addButton @_editButton


      ## (1) EDIT MODE ##
      # listen to click on edit button => start edit mode
      @_editButton.onEnter @, () ->

        @_setupEditMode()

        ## (2) OPERATION ##
        # listen to click on edit operation buttons => start operation
        @_operationButtons.foreach (operationButton) =>
          operationButton.button.onClick @, (operationButton) =>

            # get current operation
            currentOperation = @_editOperations.getByPropVal 'id', operationButton.getDOMElement().id
            @_operationId = currentOperation.id
            # TODO (opId_move_to_operation)
            # clean design: the EditMode should not need to know which
            # operation is active. Instead, the EditOperation does and this one
            # should tell the button to activate

            # setup new operation and move all the controlling logic in there
            @_setupOperation()
            operation = new HG.EditOperation @_hgInstance, currentOperation

            # wait for operation to finish
            operation.onFinish @, () =>
              @_cleanupOperation()


      # listen to next click on edit button => leave edit mode and cleanup
      @_editButton.onLeave @, () ->
        @_cleanupEditMode()
    )


  # ============================================================================
  # sets / returns status of edit mode for areas
  # ============================================================================

  enterAreaEditMode: () ->  @_areaEditMode = on
  leaveAreaEditMode: () ->  @_areaEditMode = off
  areaEditMode: () ->       @_areaEditMode



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _setupEditMode: () ->
    # activate edit button
    @_editButton.changeState 'edit-mode'
    @_editButton.activate()

    # setup new hivent button
    @_editButtonArea.addSpacer()
    @_newHiventButton = new HG.Button @_hgInstance,
      'newHivent', ['tooltip-bottom'],
      [
        {
          'id':       'normal',
          'tooltip':  "Add New Hivent",
          'iconOwn':  @_hgInstance.config.graphicsPath + 'buttons/new_hivent.svg',
          'callback': 'onClick'
        }
      ]
    @_editButtonArea.addButton @_newHiventButton

    # setup operation buttons
    @_editButtonArea.addSpacer()
    @_operationButtons = new HG.ObjectArray
    @_editOperations.foreach (operation) =>
      # add button to UI
      coButton = new HG.Button @_hgInstance,
        operation.id, ['button-horizontal', 'tooltip-bottom'],
        [
          {
            'id':       'normal',
            'tooltip':  operation.title,
            'iconOwn':  @_hgInstance.config.graphicsPath + 'buttons/' + operation.id + '.svg',
            'callback': 'onClick'
          }
        ]
      @_editButtonArea.addButton coButton, 'changeOperations-group'
      # add button in object array to keep track of it
      @_operationButtons.push {
          'id': operation.id,
          'button': coButton
        }

    # setup title
    @_title = new HG.Title @_hgInstance, "EDIT MODE" # TODO: internationalization

    # make the logo light
    @_hgInstance.watermark.makeLight()

  # ----------------------------------------------------------------------------
  _cleanupEditMode: () ->

    # restore the logo
    @_hgInstance.watermark.makeNormal()

    # remove title
    @_title.destroy()

    # remove operation buttons
    @_operationButtons.foreach (opb) =>
      opb.button.destroy()

    # remove new hivent button
    @_newHiventButton.destroy()

    # deactivate edit button
    @_editButton.deactivate()
    @_editButton.changeState 'normal'

  # ============================================================================
  _setupOperation: () ->
    # disable all buttons
    @_editButton.disable()
    @_newHiventButton.disable()
    @_operationButtons.foreach (opb) =>
      opb.button.disable()

    # highlight button of current operation
    # TODO (opId_move_to_operation)
    (@_operationButtons.getById @_operationId).button.activate()

    # setup workflow window (in the space of the title)
    @_title.clear()

  # ----------------------------------------------------------------------------
  _cleanupOperation: () ->
    # restore title
    @_title.set "EDIT MODE"   # TODO: internationalization

    # deactivate button of current operation
    # TODO (opId_move_to_operation)
    (@_operationButtons.getById @_operationId).button.deactivate()

    # enable all buttons
    @_newHiventButton.enable()
    @_operationButtons.foreach (obj) =>
      obj.button.enable()
    @_newHiventButton.enable()
    @_editButton.enable()