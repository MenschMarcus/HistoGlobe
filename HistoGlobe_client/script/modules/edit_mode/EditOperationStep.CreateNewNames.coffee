window.HG ?= {}

# ==============================================================================
# Step 3 in Edit Operation Workflow: define name of newly created area
# TODO: set names in all languages
# ==============================================================================

class HG.EditOperationStep.CreateNewNames extends HG.EditOperationStep


  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_hgInstance, direction) ->

    # inherit functionality from base class
    super @_hgInstance, direction

    # skip operations without user input
    return @finish() if not @_stepData.userInput

    # include
    @_geometryOperator = new HG.GeometryOperator


    ### SETUP OPERATION ###

    # forward: start at the first area
    if direction is 1
      @_areaIdx = -1

    # backward: start at the last area
    else
      @_areaIdx = @_stepData.inData.areas.length

    @_makeNewName direction



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _makeNewName: (direction) ->

    # abort prev Step -> first name and backwards
    return @abort()   if (@_areaIdx is 0) and (direction is -1)

    # go to next/previous area
    @_areaIdx += direction

    # get current area to work with
    if direction is 1 # forward
      currArea =      @_stepData.inData.areas[@_areaIdx]
      currName =      @_stepData.inData.areaNames[@_areaIdx]
      currTerritory = @_stepData.inData.areaTerritories[@_areaIdx]
    else # backward
      currArea =      @_stepData.outData.areas[@_areaIdx]
      currName =      @_stepData.outData.areaNames[@_areaIdx]
      currTerritory = @_stepData.outData.areaTerritories[@_areaIdx]

    # remove the name from the area, so it can be set in NewNameTool
    if currArea.name
      currArea.name = null
      currArea.handle.update()

    # hack for CRE operation: select the Area so it is visible for the user
    # which Area is currently get its name set
    if @_getOperationId() is 'CRE' and @_areaIdx > 0
      currArea.handle.select()

    # get original names of areas from 1st step (HG.AreaName)
    # to set them as name suggestions for the NewNameTool (autocomplete in there)
    @_origNames = @_hgInstance.editOperation.operation.steps[1].outData.areaNames

    # initial values for NewNameTool
    tempData = {
      nameSuggestions:    []
      name:               null
      oldPoint:           currTerritory.representativePoint
      newPoint:           null
    }

    # do not hand the HG.AreaName into NewNameTool, but only the name strings
    # => used name suggestion will be determined later by string comparison
    for nameSuggestion in @_origNames
      if nameSuggestion?
        tempData.nameSuggestions.push {
          shortName:  nameSuggestion.shortName
          formalName: nameSuggestion.formalName
        }

    # override with temporary data from last time, if it is available
    tempData = $.extend {}, tempData, @_stepData.tempData[@_areaIdx]

    # get initial data for NewNameTool
    allowNameChange = yes     # is the user allowed to change the name?
    switch @_getOperationId()

      # for CRE: treat the first Area (the one that gets created) normally
      # -> no default name
      # treat every other area just like Areas in TCH
      # -> default name that can not be changed
      when 'CRE'
        if @_areaIdx > 0
          tempData.name = {
            shortName:  currName.shortName
            formalName: currName.formalName
          }
          allowNameChange = no

      # for NCH/ICH: set the current name of the area as default value
      # to work immediately on it or just use it
      when 'NCH', 'ICH'
        tempData.name = {
          shortName:  currName.shortName
          formalName: currName.formalName
        }

      # for TCH/BCH: set the current name of the area as default value
      # that can not be changed (only name position can be changed)
      when 'TCH', 'BCH'
        tempData.name = {
          shortName:  currName.shortName
          formalName: currName.formalName
        }
        allowNameChange = no


    # backward into this step => reverse last operation
    if direction is -1
      switch @_getOperationId()

        # ----------------------------------------------------------------------
        when 'CRE'

          # the 1st Area in the workflow is the one that actually got set new
          if @_areaIdx is 0
            @_updateAreaName_reverse()

          # all the other ones are treated just like Areas in TCH operation
          @_updateRepresentativePoint_reverse()


        # ----------------------------------------------------------------------
        when 'UNI'

          @_updateAreaName_reverse()
          @_updateRepresentativePoint_reverse()

        # ----------------------------------------------------------------------
        when 'INC'

          @_continueIdentity_reverse()

        # ----------------------------------------------------------------------
        when 'SEP', 'SEC'

          # define if this area was continued in its identity
          # -> Area that caused secession instead of separation
          identityArea = @_stepData.outData.handleToBeDeleted?.getArea().id
          thisIsIdentityArea = identityArea and identityArea is @_stepData.inData.areas[@_areaIdx].id

          # reverse action which continued the identity of the selected area
          if thisIsIdentityArea
            @_continueIdentity_reverse()
            @_setOperationId 'SEP'

          # reverse action that created a new AreaName
          else
            @_updateAreaName_reverse()
            @_updateRepresentativePoint_reverse()

        # ----------------------------------------------------------------------
        when 'TCH', 'BCH'

          @_updateRepresentativePoint_reverse()

        # ----------------------------------------------------------------------
        when 'NCH'

          @_updateAreaName_reverse()

          # hack: remove the area name again
          # :( the code is getting really horrible here...
          @_stepData.inData.areas[@_areaIdx].name = null
          @_stepData.inData.areas[@_areaIdx].handle.update()

          @_updateRepresentativePoint_reverse()

        # ----------------------------------------------------------------------
        when 'ICH'

          @_copyAreaWithNewName_reverse()
          @_updateRepresentativePoint_reverse()

        # ----------------------------------------------------------------------


    # set up NewNameTool to set name and position of area interactively
    newNameTool = new HG.NewNameTool @_hgInstance, tempData, allowNameChange


    # ==========================================================================
    ### LISTEN TO USER INPUT ###

    newNameTool.onSubmit @, (newData) =>

      # temporarily save new data so it can be restores on undo
      @_stepData.tempData[@_areaIdx] = newData

      # get data for appling changes
      newShortName =   newData.name.shortName
      newFormalName =  newData.name.formalName
      newPoint =    newData.newPoint

      # handle different operations
      switch @_getOperationId()

        # ----------------------------------------------------------------------
        when 'CRE'

          # first Area: newly created area => update its AreaName
          if @_areaIdx is 0
            @_updateAreaName newShortName, newFormalName

          # every other Area: restore the name that has been there before
          else
            # deselect again
            @_restoreAreaName yes

          # update reprsentative point for any area
          @_updateRepresentativePoint newPoint

          # finish when old area was separated completely
          if @_areaIdx is @_stepData.inData.areas.length-1
            return @finish()

          # otherwise cleanup and continue with next area
          else
            @_hgInstance.newNameTool?.destroy()
            @_hgInstance.newNameTool = null
            @_makeNewName 1

          # make action reversible
          @_undoManager.add {
            undo: =>
              # cleanup
              @_hgInstance.newNameTool?.destroy()
              @_hgInstance.newNameTool = null

              # area left to restore => go back one step
              if @_areaIdx > 0
                @_restoreAreaName yes
                @_makeNewName -1

              # no area left => first action => abort step and go backwards
              else @abort()
          }

        # ----------------------------------------------------------------------
        when 'UNI', 'INC'

          # find out if new area continues the identity of one of the old areas
          # -> check if formal name equals
          origAreaName = null
          for oldName in @_origNames
            if oldName.formalName.localeCompare(newFormalName) is 0
              origAreaName = oldName

          # change of formal name => new identity => same as CRE operation
          if not origAreaName
            @_setOperationId 'UNI'
            @_updateAreaName newShortName, newFormalName
            @_updateRepresentativePoint newPoint

          # no change in formal name => continue this areas identity
          else
            @_setOperationId 'INC'
            @_continueIdentity origAreaName, newShortName, newFormalName, newPoint

          # only one step necessary => finish
          return @finish()

        # ----------------------------------------------------------------------
        when 'SEP', 'SEC'

          # find out if new area continues the identity of one of the old areas
          # -> check if formal name equals
          origAreaName = null
          if @_origNames[0].formalName.localeCompare(newFormalName) is 0
            origAreaName = @_origNames[0]

          # problem: how to distinguish SEP <-> SEC?
          # -> as soon as one area continues the identity of the selected area => SEC
          # mark this AreaHandle for deletion in outData.handleToBeDeleted
          # => if this variable carries an AreaHandle <-> SEC
          # => if this variable is null               <-> SEP

          # change of formal name => new identity => same as CRE operation
          if not origAreaName
            @_setOperationId 'SEP' if not @_stepData.outData.handleToBeDeleted
            @_updateAreaName newShortName, newFormalName
            @_updateRepresentativePoint newPoint

          # no change in formal name => continue this areas identity
          else
            @_setOperationId 'SEC'
            @_continueIdentity origAreaName, newShortName, newFormalName, newPoint


          # finish when old area was separated completely
          if @_areaIdx is @_stepData.inData.areas.length-1
            return @finish()

          # otherwise cleanup and continue with next area
          else
            @_hgInstance.newNameTool?.destroy()
            @_hgInstance.newNameTool = null
            @_makeNewName 1

          # make action reversible
          @_undoManager.add {
            undo: =>
              # cleanup
              @_hgInstance.newNameTool?.destroy()
              @_hgInstance.newNameTool = null

              # area left to restore => go back one step
              if @_areaIdx > 0
                @_makeNewName -1

              # no area left => first action => abort step and go backwards
              else @abort()
          }

        # ----------------------------------------------------------------------
        when 'TCH'

          @_updateRepresentativePoint newPoint
          @_restoreAreaName()

          # only one step necessary => finish
          return @finish()

        # ----------------------------------------------------------------------
        when 'BCH'

          @_updateRepresentativePoint newPoint
          @_restoreAreaName()

          if @_areaIdx is 0
            @_hgInstance.newNameTool?.destroy()
            @_hgInstance.newNameTool = null
            @_makeNewName 1

          else # areaIdx is 1
            return @finish()

          # make action reversible
          @_undoManager.add {
            undo: =>
              # cleanup
              @_hgInstance.newNameTool?.destroy()
              @_hgInstance.newNameTool = null

              # restore area
              oldArea = @_stepData.inData.areas[@_areaIdx]
              oldName = @_stepData.inData.areaNames[@_areaIdx]
              oldArea.name = oldName
              oldArea.handle.update()

              # area left to restore => go back one step
              if @_areaIdx > 0
                @_makeNewName -1

              # no area left => first action => abort step and go backwards
              else @abort()
          }


        # ----------------------------------------------------------------------
        when 'NCH', 'ICH'

          # find out if new area continues the identity of the old area
          # -> check if formal name equals
          shortNameChanged =  @_stepData.inData.areaNames[0].shortName.localeCompare(newShortName) isnt 0
          formalNameChanged = @_stepData.inData.areaNames[0].formalName.localeCompare(newFormalName) isnt 0

          if formalNameChanged # => new identity
            @_setOperationId 'ICH'

            @_updateRepresentativePoint newPoint

            # get a new Area with the same AreaTerritory than the original Area
            # sets the short and formal name and the new Point
            @_copyAreaWithNewName newShortName, newFormalName


          else  # formal name stayed the same

            if shortNameChanged
              @_setOperationId 'NCH'
              @_updateAreaName newShortName, newFormalName
              @_updateRepresentativePoint newPoint

            else
              @_updateRepresentativePoint newPoint
              @_stepData.outData.emptyOperation = yes

          # only one step necessary => finish
          return @finish()



  # ============================================================================
  # create new AreaName, attach it to current Area and add it to the output
  # ============================================================================

  _updateAreaName: (newShortName, newFormalName) ->

    # get area to work with
    oldArea = @_stepData.inData.areas[@_areaIdx]

    # create new AreaName
    newName = new HG.AreaName {
      id:         @_getId()
      shortName:  newShortName
      formalName: newFormalName
    }

    # update model: link Area and AreaName
    oldArea.name = newName
    newName.area = oldArea

    # update view
    oldArea.handle.update()

    # add to operation workflow
    @_stepData.outData.areas[@_areaIdx] =           oldArea
    @_stepData.outData.areaNames[@_areaIdx] =       newName
    @_stepData.outData.areaTerritories[@_areaIdx] = oldArea.territory


  # ----------------------------------------------------------------------------
  _updateAreaName_reverse: (newShortName, newFormalName) ->

    # get old area and name
    oldArea =  @_stepData.inData.areas[@_areaIdx]
    oldName =  @_stepData.inData.areaNames[@_areaIdx]

    # update model: link Area and AreaName
    oldArea.name = oldName

    # update view
    oldArea.handle.update()


  # ============================================================================
  # update the representative point of the territory with the new point set
  # in NewNameTool
  # ============================================================================

  _continueIdentity: (origAreaName, newShortName, newFormalName, newPoint) ->

    # get Areas to work with
    oldArea =   @_stepData.inData.areas[@_areaIdx]  # temporal Area that is to be removed
    origArea =  origAreaName.area                   # Area to continue its identity

    # attach new territory to it and update its representative point
    origArea.territory = oldArea.territory
    origArea.territory.representativePoint = newPoint

    # find out if short name has changed -> need for new AreaName?
    if origAreaName.shortName.localeCompare(newShortName) is 0
      # also same short name => reuse old AreaName
      origAreaName.area = origArea
      origArea.name = origAreaName

    else
      # different short name, but same formal name
      # => identitiy stays the same, but it still needs new AreaName
      newName = new HG.AreaName {
        id:         @_getId()
        shortName:  newShortName
        formalName: newFormalName
      }
      newName.area = origArea
      origArea.name = newName

    # update model and view:
    # hide the area that was created in the previous NewTerritory step
    # and restore (show) the updated area of this step
    oldArea.handle.deselect()
    oldArea.handle.endEdit()
    oldArea.handle.hide()
    origArea.handle.show()
    origArea.handle.startEdit()
    origArea.handle.select()

    # add to operation workflow
    @_stepData.outData.areas[@_areaIdx] =           origArea
    @_stepData.outData.areaNames[@_areaIdx] =       origArea.name
    @_stepData.outData.areaTerritories[@_areaIdx] = origArea.territory

    # mark hidden area handle for deletion in last step
    # do not destroy it know, because it might needs to be restored
    @_stepData.outData.handleToBeDeleted = oldArea.handle


  # ----------------------------------------------------------------------------
  _continueIdentity_reverse: () ->

    # get old and new data
    newArea =       @_stepData.outData.areas[@_areaIdx]
    newName =       @_stepData.outData.areaNames[@_areaIdx]
    newTerritory =  @_stepData.outData.areaTerritories[@_areaIdx]

    oldArea =       @_stepData.inData.areas[@_areaIdx]
    oldName =       @_stepData.inData.areaNames[@_areaIdx]
    oldTerritory =  @_stepData.inData.areaTerritories[@_areaIdx]

    # reset old representative point
    oldTerritory.representativePoint = @_stepData.tempData[@_areaIdx].oldPoint
    newTerritory.representativePoint = @_stepData.tempData[@_areaIdx].oldPoint

    # reset name
    oldArea.name = oldName
    newArea.name = null

    # reset territory
    oldArea.territory = oldTerritory
    newArea.territory = null

    # update view
    newArea.handle.deselect()
    newArea.handle.endEdit()
    newArea.handle.hide()
    oldArea.handle.show()
    oldArea.handle.startEdit()
    oldArea.handle.select()

    # unmark handle for deletion
    @_stepData.outData.handleToBeDeleted = null


  # ============================================================================
  # puts the AreaName that was just erased in the beginning of the step back on
  # the map
  # ============================================================================

  _restoreAreaName: (deselect=no) ->

    # get areas
    currArea =      @_stepData.inData.areas[@_areaIdx]
    currName =      @_stepData.inData.areaNames[@_areaIdx]
    currTerritory = @_stepData.inData.areaTerritories[@_areaIdx]

    # put names back on the map
    currArea.name = currName

    # update view
    currArea.handle.update()
    currArea.handle.deselect() if deselect

    # add to workflow
    @_stepData.outData.areas[@_areaIdx] =           currArea
    @_stepData.outData.areaNames[@_areaIdx] =       currName
    @_stepData.outData.areaTerritories[@_areaIdx] = currTerritory


  # ----------------------------------------------------------------------------
  _restoreAreaName_reverse: (deselect=no) ->

    # get areas
    currArea =      @_stepData.inData.areas[@_areaIdx]

    # delete area from the map
    currArea.name = null

    # update view
    currArea.handle.update()
    currArea.handle.deselect() if deselect


  # ============================================================================
  # copy an Area and its AreaTerritory to a new Area + new Handle
  # ============================================================================

  _copyAreaWithNewName: (newShortName, newFormalName) ->

    # get old Area
    oldArea = @_stepData.inData.areas[0]

    # create new Area
    newArea = new HG.Area @_getId()

    # copy AreaTerritory
    newTerritory = new HG.AreaTerritory {
      id:                   @_getId()
      geometry:             @_geometryOperator.copy oldArea.territory.geometry
      representativePoint:  @_geometryOperator.copy oldArea.territory.representativePoint
    }

    # link new Area <-> old AreaTerritory
    newArea.territory = newTerritory
    newTerritory.area = newArea

    # create new AreaName with names given
    newName = new HG.AreaName {
      id:         @_getId()
      shortName:  newShortName
      formalName: newFormalName
    }

    # link new Area <-> new AreaName
    newArea.name = newName
    newName.area = newArea

    # create AreaHandle <-> Area
    newHandle = new HG.AreaHandle @_hgInstance, newArea
    newArea.handle = newHandle

    # remove old area from model and hide
    oldArea.name =      null
    oldArea.territory = null
    oldArea.handle.endEdit()
    oldArea.handle.deselect()
    oldArea.handle.hide()

    # show new area
    newArea.handle.show()
    newArea.handle.select()
    newArea.handle.startEdit()

    # add to operation workflow
    @_stepData.outData.areas[0] =            newArea
    @_stepData.outData.areaNames[0] =        newName
    @_stepData.outData.areaTerritories[0] =  newTerritory


  # ----------------------------------------------------------------------------
  _copyAreaWithNewName_reverse: () ->

    # restore old areas
    oldArea =       @_stepData.inData.areas[0]
    oldName =       @_stepData.inData.areaNames[0]
    oldTerritory =  @_stepData.inData.areaTerritories[0]

    # reset link old Area <-> old AreaTerritory
    oldArea.territory = oldTerritory
    oldTerritory.area = oldArea

    # do not reset link new Area <-> new AreaName
    # because that would show the area on the map again
    oldName.area = oldArea
    # oldArea.name = oldName # Leave uncommented!

    # show old area
    oldArea.handle.show()
    oldArea.handle.select()
    oldArea.handle.startEdit()

    # remove new area
    newArea = @_stepData.outData.areas[0]
    newArea.handle.destroy()


  # ============================================================================
  # update the representative point of the territory with the new point set
  # in NewNameTool
  # ============================================================================

  _updateRepresentativePoint: (newPoint) ->

    # get area to work with
    oldArea = @_stepData.inData.areas[@_areaIdx]

    # update model
    oldArea.territory.representativePoint = newPoint

    # update view
    oldArea.handle.update()


  # ----------------------------------------------------------------------------
  _updateRepresentativePoint_reverse: (newPoint) ->

    # get area to work with
    oldArea =  @_stepData.inData.areas[@_areaIdx]

    # update model
    oldArea.territory.representativePoint = @_stepData.tempData[@_areaIdx].oldPoint

    # update view
    oldArea.handle.update()


  ##############################################################################

  # ============================================================================
  # end of operation
  # ============================================================================

  _cleanup: (direction) ->

    ### CLEANUP OPERATION ###
    @_hgInstance.newNameTool?.destroy()
    @_hgInstance.newNameTool = null

    # backwards step => restore name previously on the area
    if direction is -1
      oldArea = @_stepData.inData.areas[0]
      oldName = @_stepData.inData.areaNames[0]
      oldArea.name = oldName
      oldArea.handle.update()
