window.HG ?= {}

# ==============================================================================
# control the workflow of a complete operation
# manage operation window (init, send data, get data)
# handle communication with backend (get data, send data)
# ==============================================================================

class HG.EditOperation

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # setup the whole operation
  # ============================================================================

  constructor: (@_hgInstance, operationConfig) ->
    # add module to HG Instance
    @_hgInstance.editOperation = @

    # error handling
    if not @_hgInstance.map.getMap()?
      console.error "Unable to load Edit Mode: There is no map, you idiot! Why would you want to have HistoGlobe without a map ?!?"

    if not @_hgInstance.areaController?
      console.error "Unable to load Edit Mode: AreaController module is not included in the current hg instance (has to be loaded before EditMode)"

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onStepComplete'
    @addCallback 'onStepIncomplete'
    @addCallback 'onStepTransition'
    @addCallback 'onOperationComplete'
    @addCallback 'onOperationIncomplete'
    @addCallback 'onFinish'

    # random ids that have been created for new objects in EditOperationSteps
    # => ensures each id will be unique
    @_idCtr = 0


    ### SETUP OPERATION DATA CONFIG ###
    # public -> will be changed by OperationSteps directly

    @operation =
      {
        id:                       operationConfig.id
        idx:                      0    # = step index -> 0 = start
        steps: [
          { # idx                 0
            id:                   'START'
            userInput:            no
          }
          { # idx                 1
            id:                   'SEL_OLD_AREA'
            title:                null
            userInput:            no
            number:               {}
            outData: {
              areas:              []
              areaNames:          []
              areaTerritories:    []
            }
          },
          { # idx                 2
            id:                   'SET_NEW_TERR'
            title:                null
            userInput:            no
            number:               {}
            inData: {
              areas:              []
              areaNames:          []
              areaTerritories:    []
            }
            tempData: {
              areas:              []
              oldTerritories:     []
              newTerritories:     []
              oldNames:           []
              newNames:           []
              drawLayers:         []
            }
            outData: {
              areas:              []
              areaNames:          []
              areaTerritories:    []
            }
          },
          { # idx                 3
            id:                   'SET_NEW_NAME'
            title:                null
            userInput:            no
            number:               {}
            inData: {
              areas:              []
              areaNames:          []
              areaTerritories:    []
            }
            tempData:             []
            outData: {
              areas:              []
              areaNames:          []
              areaTerritories:    []
            }
          },
          { # idx                 4
            id:                   'ADD_CHNG'
            title:                "add change <br /> to historical event"
            userInput:            yes
            outData: {
              hiventData:         {}
              historicalChange:   null
            }
          }
        ]
      }

    # fill up default information with information of loaded change operation
    for stepConfig in operationConfig.steps
      for stepData in @operation.steps
        if stepData.id is stepConfig.id
          stepData.title = stepConfig.title
          stepData.userInput = yes
          stepData.number = (@_getRequiredNum stepConfig.num) if stepData.number
          break

    # current step the user is in
    @_step = null


    ### SETUP UI ###

    new HG.WorkflowWindow @_hgInstance, @operation


    ### UNDO FUNCTIONALITY ###

    # UndoManager is public -> can be accessed by EditOperationSteps
    @_undoManagers = [null, null, null, null]
    @_fullyAborted = no

    # next step button
    @_hgInstance.buttons.nextStep.onNext @, () =>
      @_step.finish()

    # finish button
    @_hgInstance.buttons.nextStep.onFinish @, () =>
      @_step.finish()

    # undo button
    @_hgInstance.buttons.undoStep.onClick @, () =>
      @_undo()

    # abort button
    @_hgInstance.buttons.abortOperation.onAbort @, () =>
      @_undo() while not @_fullyAborted


    ### LET'S GO ###
    @_makeStep 1



  # ============================================================================
  # manage undo functionality
  # ============================================================================

  addUndoManager: (undoManager) ->
    @_undoManagers[@operation.idx] = undoManager

  # ----------------------------------------------------------------------------
  getUndoManager: () ->
    @_undoManagers[@operation.idx]


  # ============================================================================
  # create a random id for an object that does not exit yet
  # ============================================================================
  getNewId: () ->
    @_idCtr++       # next id that has not been assigned yet
    "T" + @_idCtr   # unique id = "T" for "temporary" + contiguous number

  # ============================================================================
  # manage stepping through the steps
  # ============================================================================

  _makeStep: (direction) ->

    oldStep = @operation.steps[@operation.idx]
    newStep = @operation.steps[@operation.idx+direction]

    # transfer data between steps
    if newStep? and oldStep?
      if direction is 1 then  newStep.inData  = oldStep.outData
      else                    newStep.outData = oldStep.inData

    # change workflow window
    if newStep?.userInput
      @notifyAll 'onStepTransition', direction
      @notifyAll 'onStepIncomplete'

    # go to next step
    @operation.idx += direction

    # setup new step
    switch @operation.idx
      when 0 then return @_abort()  # only on undo from first step
      when 1 then @_step = new HG.EditOperationStep.SelectOldAreas        @_hgInstance, direction
      when 2 then @_step = new HG.EditOperationStep.CreateNewTerritories  @_hgInstance, direction
      when 3 then @_step = new HG.EditOperationStep.CreateNewNames        @_hgInstance, direction
      when 4 then @_step = new HG.EditOperationStep.AddChange             @_hgInstance, direction
      when 5 then return @_finish()

    # react on user input
    if newStep?.userInput
      @_step.onFinish @, () ->  @_makeStep 1
      @_step.onAbort @, () ->   @_makeStep -1

    # go to next step if no input required
    else
      @_makeStep direction


  # ============================================================================
  # perform undo operation
  # ============================================================================

  _undo: () ->

    # if current step has reversible actions
    # => undo it
    if @_undoManagers[@operation.idx].hasUndo()
      @_undoManagers[@operation.idx].undo()

    # otherwise destroy the step and go one step back
    else
      @_step.abort()



  # ============================================================================
  # finish up the whole operation, send new data to server and update model
  # on the client with the reponse data from the server
  # ============================================================================

  _finish: () ->

    # get data for hivent and historical change
    hiventData =            @operation.steps[4].outData.hiventData
    historicalChangeData =  @operation.steps[4].outData.historicalChange

    # HACK: prevent writing into database
    # @_hgInstance.databaseInterface.saveHistoricalOperation hiventData, historicalChange

    # @_hgInstance.databaseInterface.onFinishSavingHistoricalOperation @, () =>

    ## HACK: create objects manually

    # create Hivent
    hivent = new HG.Hivent {
      id :            hiventData.id
      name :          hiventData.name
      date :          moment(hiventData.date)
      location :      hiventData.location
      description :   hiventData.description
    }

    # create HistoricalChange
    historicalChange = new HG.HistoricalChange historicalChangeData.id
    historicalChange.operation = historicalChangeData.operation

    # create AreaChanges
    for areaChangeData in historicalChangeData.areaChanges
      areaChange = new HG.AreaChange areaChangeData.id
      areaChange.operation = areaChangeData.operation
      areaChange.area = areaChangeData.area
      areaChange.oldAreaName = areaChangeData.oldAreaName
      areaChange.newAreaName = areaChangeData.newAreaName
      areaChange.oldAreaTerritory = areaChangeData.oldAreaTerritory
      areaChange.newAreaTerritory = areaChangeData.newAreaTerritory

      # link HistoricalChange <-> AreaChange
      areaChange.historicalChange = historicalChange
      historicalChange.areaChanges.push areaChange

    # link Hivent <-> HistoricalChange
    historicalChange.hivent = hivent
    hivent.historicalChanges.push historicalChange

    # link HiventHandle <-> Hivent
    hiventHandle = new HG.HiventHandle @_hgInstance, hivent
    hivent.handle = hiventHandle

    # add to HG
    @_hgInstance.hiventController.addHiventHandle hiventHandle

    @notifyAll 'onFinish'


  # ============================================================================
  # break up the whole operation
  # ============================================================================

  _abort: () ->
    @_fullyAborted = yes
    @notifyAll 'onFinish'


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  # get minimum / maximum number of areas required for each step
  # possible inputs:  1   1+  2   2+   1|2
  # ============================================================================

  _getRequiredNum: (expr) ->
    # error handling
    return 0 if not expr?
    # is there a deliminator present (either | or -)?
    delIdx = Math.max(expr.indexOf("|"), expr.indexOf("-"))
    if (delIdx is -1) # there is no deliminator
      # if last character is "+", treat max as unlimited
      lastChar = expr.substr(expr.length-1)
      min = expr.substring(0,1)
      max = if lastChar is '+' then HGConfig.max_area_selection.val else lastChar
    else # there is a deliminator
      min = expr.substring(0,delIdx)
      max = expr.substring(delIdx+1,expr.length)
    return {
      'min': parseInt(min)
      'max': parseInt(max)
    }