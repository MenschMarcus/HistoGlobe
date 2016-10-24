window.HG ?= {}

# ==============================================================================
# base class for all steps
# handles input/output from/to workflow window and operation class
# ==============================================================================

class HG.EditOperationStep

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_hgInstance, direction, start=no) ->

    ## handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback "onFinish"
    @addCallback "onAbort"

    ## handle undo
    # only add undo manager on forward direction, to be able to undo the actions
    # when going backwards through the steps
    if direction is 1
      @_undoManager = new UndoManager
      @_hgInstance.editOperation.addUndoManager @_undoManager
    else
      @_undoManager = @_hgInstance.editOperation.getUndoManager()

    # main data: operation and step data (local reference => accessible anywhere)
    @_stepData = @_hgInstance.editOperation.operation.steps[@_hgInstance.editOperation.operation.idx]


  # ============================================================================
  # finish/abort methods can be intervoked both by clicking next button
  # in the workflow window and by the operation itself
  # (e.g. if last area successfully named)
  # ============================================================================

  finish: () ->
    @_cleanup 1
    @notifyAll 'onFinish'

  # ----------------------------------------------------------------------------
  abort: () ->
    @_cleanup -1
    @notifyAll 'onAbort'


  # ============================================================================
  # get / set operation id
  # ============================================================================
  _setOperationId: (id) ->  @_hgInstance.editOperation.operation.id = id
  _getOperationId: () ->    @_hgInstance.editOperation.operation.id

  # ============================================================================
  # get a new random id
  # ============================================================================

  _getId: () -> @_hgInstance.editOperation.getNewId()

  # ============================================================================
  # cleanup to be implemented by each step on its own
  # ============================================================================

  _cleanup: (direction) ->
