window.HG ?= {}

# ==============================================================================
# Step 1 in Edit Operation Workflow: Select areas on the map subject to change
# interaction with AreaController module
# ==============================================================================

class HG.EditOperationStep.SelectOldAreas extends HG.EditOperationStep

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_hgInstance, direction) ->

    # inherit functionality from base class
    super @_hgInstance, direction

    # skip step if not user input
    if not @_stepData.userInput
      if direction is 1 # forward
        return @finish()
      else # backward
        return @abort()


    ### SETUP OPERATION ###

    # tell AreaController to start selecting maximal X number of areas
    @_hgInstance.areaController.enableMultiSelection @_stepData.number.max

    # hack for backwards step: is step already complete?
    if @_stepData.outData.areas.length >= @_stepData.number.min
      @_hgInstance.editOperation.notifyAll 'onStepComplete'

    # forward change
    if direction is 1
      # select currently selected area (if there is one)
      @_select (@_hgInstance.areaController.getSelectedAreaHandles())[0]

    # backward change
    else
      # restore areas on the map
      area.handle.select() for area in @_stepData.outData.areas


    ### SETUP USER INPUT ###

    # listen to area (de)selection from AreaController
    @_hgInstance.areaController.onSelectArea @,    @_select
    @_hgInstance.areaController.onDeselectArea @,  @_deselect


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  # select an area = make him part of the HistoricalChange
  # -> create an 'DEL' AreaChange for it
  # ============================================================================

  _select: (areaHandle) ->

    # error handling
    return if not areaHandle

    # add to workflow
    @_stepData.outData.areas.push           areaHandle.getArea()
    @_stepData.outData.areaNames.push       areaHandle.getArea().name
    @_stepData.outData.areaTerritories.push areaHandle.getArea().territory

    # is step complete?
    if @_stepData.outData.areas.length >= @_stepData.number.min
      @_hgInstance.editOperation.notifyAll 'onStepComplete'

    # make action reversible
    @_undoManager.add {
      undo: =>
        areaHandle.deselect()
    }

  # ----------------------------------------------------------------------------
  _deselect: (areaHandle) ->

    # error handling
    return if not areaHandle

    # remove from workflow
    idx = @_stepData.outData.areas.indexOf areaHandle.getArea()
    @_stepData.outData.areas.splice idx, 1
    @_stepData.outData.areaNames.splice idx, 1
    @_stepData.outData.areaTerritories.splice idx, 1

    # is step incomplete?
    if @_stepData.outData.length < @_stepData.number.min
      @_hgInstance.editOperation.notifyAll 'onStepIncomplete'

    # make action reversible
    @_undoManager.add {
      undo: =>
        areaHandle.select()
    }


  # ============================================================================
  _cleanup: (direction) ->

    ### CLEANUP USER INPUT LISTENING ###

    @_hgInstance.areaController.removeListener 'onSelectArea', @
    @_hgInstance.areaController.removeListener 'onDeselectArea', @


    ### CLEANUP OPERATION ###

    # tell AreaController to stop selecting multiple areas
    @_hgInstance.areaController.disableMultiSelection()

    # deselect all selected areas (clean cleanup)
    if direction is 1
      for area in @_stepData.outData.areas
        area.handle.deselect()