window.HG ?= {}

# ==============================================================================
# Step 4 in Edit Operation Workflow: Add change to a Hivent
# ==============================================================================

class HG.EditOperationStep.AddChange extends HG.EditOperationStep

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_hgInstance, direction) ->

    # inherit functionality from base class
    super @_hgInstance, direction

    # get the historical change data and add to workflow
    @_prepareChange()
    @_stepData.outData.historicalChange = @_historicalChange

    ### SETUP OPERATION ###

    if direction is -1
      @_hgInstance.areaController.enableMultiSelection HGConfig.max_area_selection.val
      @_hgInstance.editMode.enterAreaEditMode()

    # hivent box: select existing or create new hivent
    @_hiventBox = new HG.NewHiventBox @_hgInstance, @_historicalChange.getDescription()

    @_hiventBox.onSubmit @, (hiventData) ->
      @_stepData.outData.hiventData = hiventData
      @finish()



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _cleanup: () ->

    @_hiventBox.destroy()

    # set all handles out of edit mode
    # HACK: with all I mean really all that have been involved in the operation
    # old areas
    for area in @_hgInstance.editOperation.operation.steps[1].outData.areas
      if area
        area.handle.endEdit()
        area.handle.deselect()
        area.handle.update()

    # new areas
    for area in @_hgInstance.editOperation.operation.steps[3].outData.areas
      area.handle.endEdit()
      area.handle.deselect()
      area.handle.update()

    @_hgInstance.editMode.leaveAreaEditMode()
    @_hgInstance.areaController.disableMultiSelection()

    # select the one area that is most important for the operation
    # randomly take the first one :D
    # @_stepData.inData.areas[0].handle.select()


  # ============================================================================
  # assemble HistoricalChange including all AreaChanges
  # ============================================================================

  _prepareChange: () ->

    # get relevant data from operations object
    stepsData = @_hgInstance.editOperation.operation.steps
    @_oldAreas = stepsData[1].outData
    @_newAreas = stepsData[3].outData

    # => main HistoricalChange object that contains the AreaChanges
    # made in the workflow
    @_historicalChange = new HG.HistoricalChange @_getId()
    @_historicalChange.operation = @_getOperationId()


    ### PREPARE AREA CHANGES ###

    switch @_getOperationId()

      # ------------------------------------------------------------------------
      when 'CRE'

        # add new Area
        @_makeADD 0

        # for all other areas: decide if their territory has been changed or removed
        oldIdx = 1  # N.B. start NOT at 0, because 0 is the ADD area
        while oldIdx < @_oldAreas.areas.length

          # get corresponding area from newAreas array, if there is any
          newIdx = @_newAreas.areas.indexOf @_oldAreas.areas[oldIdx]

          # if there is no corresponding Area, it was removed => DES
          if newIdx is -1
            @_makeDEL oldIdx

          # if there is a corresponding Area, its territory got changed => TCH
          else
            @_makeTCH oldIdx, newIdx

          oldIdx++

      # ------------------------------------------------------------------------
      when 'UNI'

        # delete old Areas
        idx = 0
        while idx < @_oldAreas.areas.length
          @_makeDEL idx
          idx++

        # add new Area
        @_makeADD 0

      # ------------------------------------------------------------------------
      when 'INC'

        # Area that the others are incorporated in
        incArea = @_newAreas.areas[0]

        idx = 0
        while idx < @_oldAreas.areas.length

          # incorporation area creates a TCH, because it continues the identity
          # if formal name has changed, add this NCH areaChange as well
          if @_oldAreas.areas[idx] is incArea
            @_makeTCH idx, 0
            @_makeNCH idx, 0 if @_oldAreas.areaNames[idx] isnt @_newAreas.areaNames[0]

          # normal non-incorporation area will be deleted
          else @_makeDEL idx

          idx++

      # ------------------------------------------------------------------------
      when 'SEP'

        # delete old Area
        @_makeDEL 0

        # add new Areas
        idx = 0
        while idx < @_newAreas.areas.length
          @_makeADD idx
          idx++

      # ------------------------------------------------------------------------
      when 'SEC'

        # Area that the others are seceded from
        secArea = @_oldAreas.areas[0]

        idx = 0
        while idx < @_newAreas.areas.length

          # secession area creates a TCH, because it continues the identity
          # if formal name has changed, add this NCH areaChange as well
          if @_newAreas.areas[idx] is secArea
            @_makeTCH 0, idx
            @_makeNCH 0, idx if @_oldAreas.areaNames[0] isnt @_newAreas.areaNames[idx]

          # normal non-secession area will be added
          else @_makeADD idx

          idx++

      # ------------------------------------------------------------------------
      when 'TCH', 'BCH'

        idx = 0
        while idx < @_newAreas.areas.length
          @_makeTCH idx, idx
          idx++

      # ------------------------------------------------------------------------
      when 'NCH'
        @_makeNCH 0, 0

      # ------------------------------------------------------------------------
      when 'ICH'
        @_makeDEL 0
        @_makeADD 0

      # ------------------------------------------------------------------------
      when 'DES'
        @_makeDEL 0


  # ============================================================================
  # helper functions to create a single AreaChange for each operation
  # ============================================================================

  _makeADD: (idx) ->
    newChange = new HG.AreaChange @_getId()
    newChange.operation =        'ADD'
    newChange.historicalChange = @_historicalChange
    newChange.area =             @_newAreas.areas[idx]
    newChange.newAreaName =      @_newAreas.areaNames[idx]
    newChange.newAreaTerritory = @_newAreas.areaTerritories[idx]
    @_historicalChange.areaChanges.push newChange

  # ----------------------------------------------------------------------------
  _makeDEL: (idx) ->
    newChange = new HG.AreaChange @_getId()
    newChange.operation =        'DEL'
    newChange.historicalChange = @_historicalChange
    newChange.area =             @_oldAreas.areas[idx]
    newChange.oldAreaName =      @_oldAreas.areaNames[idx]
    newChange.oldAreaTerritory = @_oldAreas.areaTerritories[idx]
    @_historicalChange.areaChanges.push newChange

  # ----------------------------------------------------------------------------
  _makeNCH: (oldIdx, newIdx) ->
    newChange = new HG.AreaChange @_getId()
    newChange.operation =        'NCH'
    newChange.historicalChange = @_historicalChange
    newChange.area =             @_oldAreas.areas[oldIdx]
    newChange.oldAreaName =      @_oldAreas.areaNames[oldIdx]
    newChange.newAreaName =      @_newAreas.areaNames[newIdx]
    @_historicalChange.areaChanges.push newChange

  # ----------------------------------------------------------------------------
  _makeTCH: (oldIdx, newIdx) ->
    newChange = new HG.AreaChange @_getId()
    newChange.operation =        'TCH'
    newChange.historicalChange = @_historicalChange
    newChange.area =             @_oldAreas.areas[oldIdx]
    newChange.oldAreaTerritory = @_oldAreas.areaTerritories[oldIdx]
    newChange.newAreaTerritory = @_newAreas.areaTerritories[newIdx]
    @_historicalChange.areaChanges.push newChange