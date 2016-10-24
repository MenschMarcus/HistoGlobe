window.HG ?= {}

# ==============================================================================
# loads initial areas and hivents from the server and creates their links
# to each other via start/end hivents and ChangeAreas/ChangeAreaNames/Territorie
# ==============================================================================

class HG.DatabaseInterface


  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################


  # ============================================================================
  constructor: () ->

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onFinishLoadingInitData'
    @addCallback 'onFinishSavingHistoricalOperation'


  # ============================================================================
  hgInit: (@_hgInstance) ->

    # add to hg instance
    @_hgInstance.databaseInterface = @

    # include
    @_geometryReader = new HG.GeometryReader

    # temporary quick and dirty solution
    # that actually works quite well for now :P

    $.ajax
      url:  'get_all/'
      type: 'POST'
      data: ""

      # success callback: load areas and hivents here and connect them
      success: (response) =>
        dataObj = $.parseJSON response

        # create Areas
        areas = []
        for areaData in dataObj.areas
          area = new HG.Area areaData.id
          areaHandle = new HG.AreaHandle @_hgInstance, area
          area.handle = areaHandle
          areas.push area

        # create AreaNames and AreaTerritories and store them
        # so they can be linked to ChangeAreas later
        areaNames = []
        for anData in dataObj.area_names
          areaName = new HG.AreaName {
            id:           anData.id
            shortName:    anData.short_name
            formalName:   anData.formal_name
          }
          areaName.area = areas.find (obj) -> obj.id is anData.area
          areaNames.push areaName

        areaTerritories = []
        for atData in dataObj.area_territories
          areaTerritory = new HG.AreaTerritory {
            id:                   atData.id
            geometry:             @_geometryReader.read atData.geometry
            representativePoint:  @_geometryReader.read atData.representative_point
          }
          areaTerritory.area = areas.find (obj) -> obj.id is atData.area
          areaTerritories.push areaTerritory

        # keep track of earliest data to know where to start tracing the changes
        minDate = moment()

        # create Hivents
        for hData in dataObj.hivents
          hivent = new HG.Hivent {
            id:           hData.id
            name:         hData.name
            date:         moment(hData.date)
            location:     hData.location    ?= null
            description:  hData.description ?= null
            link:         hData.link        ?= null
          }

          minDate = moment.min(minDate, hivent.date)

          # create HistoricalChanges
          for eoData in hData.edit_operations
            historicalChange = new HG.HistoricalChange  eoData.id
            historicalChange.operation =                eoData.operation
            historicalChange.hivent =                   eoData.hivent

            # create AreaChanges
            for hoData in eoData.hivent_operations

              # link ChangeArea <- Area / AreaName / AreaTerritory
              switch hoData.operation

                # --------------------------------------------------------------
                when 'UNI'
                  # old areas
                  for oldArea, i in hoData.old_areas
                    ac = new HG.AreaChange hoData.id+"OA"+i
                    ac.historicalChange = historicalChange
                    ac.operation = 'DEL'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is oldArea.area
                    n = areaNames.find (obj) -> obj.id is oldArea.name
                    t = areaTerritories.find (obj) -> obj.id is oldArea.territory

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.oldAreaName = n
                    ac.oldAreaTerritory = t
                    a.endChange = ac
                    n.endChange = ac  if n
                    t.endChange = ac  if t

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                  # new area
                  if true
                    newArea = hoData.new_areas[0]

                    ac = new HG.AreaChange hoData.id+"NA"+0
                    ac.historicalChange = historicalChange
                    ac.operation = 'ADD'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is newArea.area
                    n = areaNames.find (obj) -> obj.id is newArea.name
                    t = areaTerritories.find (obj) -> obj.id is newArea.territory

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.newAreaName = n
                    ac.newAreaTerritory = t
                    a.startChange = ac
                    n.startChange = ac  if n
                    t.startChange = ac  if t

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                # --------------------------------------------------------------
                when 'INC'
                  # old areas
                  for oldArea, i in hoData.old_areas
                    ac = new HG.AreaChange hoData.id+"OA"+i
                    ac.historicalChange = historicalChange
                    ac.operation = 'DEL'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is oldArea.area
                    n = areaNames.find (obj) -> obj.id is oldArea.name
                    t = areaTerritories.find (obj) -> obj.id is oldArea.territory

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.oldAreaName = n
                    ac.oldAreaTerritory = t
                    a.endChange = ac
                    n.endChange = ac  if n
                    t.endChange = ac  if t

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                  # update area
                  if true
                    updArea = hoData.update_area

                    ac = new HG.AreaChange hoData.id+"UA"+0
                    ac.historicalChange = historicalChange
                    ac.operation = 'TCH'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is updArea.area
                    ot = areaTerritories.find (obj) -> obj.id is updArea.old_territory
                    nt = areaTerritories.find (obj) -> obj.id is updArea.new_territory

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.oldAreaTerritory = ot
                    ac.newAreaTerritory = nt
                    a.updateChanges.push ac
                    ot.endChange = ac     if ot
                    nt.startChange = ac   if nt

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                # --------------------------------------------------------------
                when 'SEP'
                  # old area
                  if true
                    oldArea = hoData.old_areas[0]

                    ac = new HG.AreaChange hoData.id+"OA"+0
                    ac.historicalChange = historicalChange
                    ac.operation = 'DEL'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is oldArea.area
                    n = areaNames.find (obj) -> obj.id is oldArea.name
                    t = areaTerritories.find (obj) -> obj.id is oldArea.territory

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.oldAreaName = n
                    ac.oldAreaTerritory = t
                    a.endChange = ac
                    n.endChange = ac  if n
                    t.endChange = ac  if t

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                  # new area
                  for newArea, i in hoData.new_areas
                    ac = new HG.AreaChange hoData.id+"NA"+i
                    ac.historicalChange = historicalChange
                    ac.operation = 'ADD'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is newArea.area
                    n = areaNames.find (obj) -> obj.id is newArea.name
                    t = areaTerritories.find (obj) -> obj.id is newArea.territory

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.newAreaName = n
                    ac.newAreaTerritory = t
                    a.startChange = ac
                    n.startChange = ac  if n
                    t.startChange = ac  if t

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                # --------------------------------------------------------------
                when 'SEC'
                  # new areas
                  for newArea, i in hoData.new_areas
                    ac = new HG.AreaChange hoData.id+"NA"+i
                    ac.historicalChange = historicalChange
                    ac.operation = 'ADD'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is newArea.area
                    n = areaNames.find (obj) -> obj.id is newArea.name
                    t = areaTerritories.find (obj) -> obj.id is newArea.territory

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.newAreaName = n
                    ac.newAreaTerritory = t
                    a.startChange = ac
                    n.startChange = ac    if n
                    t.startChange = ac    if t

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                  # update area
                  if true
                    updArea = hoData.update_area

                    ac = new HG.AreaChange hoData.id+"UA"+0
                    ac.historicalChange = historicalChange
                    ac.operation = 'TCH'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is updArea.area
                    ot = areaTerritories.find (obj) -> obj.id is updArea.old_territory
                    nt = areaTerritories.find (obj) -> obj.id is updArea.new_territory

                    # HACK: ignore omega
                    break if not ot and not nt

                    ac.area = a
                    ac.oldAreaTerritory = ot
                    ac.newAreaTerritory = nt
                    a.updateChanges.push ac
                    ot.endChange = ac     if ot
                    nt.startChange = ac   if nt

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

                # --------------------------------------------------------------
                when 'NCH'
                  if true
                    updArea = hoData.update_area

                    ac = new HG.AreaChange hoData.id+"UA"+0
                    ac.historicalChange = historicalChange
                    ac.operation = 'NCH'

                    # find associated area, name and territory
                    a = areas.find (obj) -> obj.id is updArea.area
                    ot = areaNames.find (obj) -> obj.id is updArea.old_name
                    nt = areaNames.find (obj) -> obj.id is updArea.new_name

                    # link AreaChange <-> Area(Name/Territory)
                    ac.area = a
                    ac.oldAreaName = ot
                    ac.newAreaName = nt
                    a.updateChanges.push ac
                    ot.endChange = ac     if ot
                    nt.startChange = ac   if nt

                    # link HistoricalChange <- ChangeArea
                    historicalChange.areaChanges.push ac

              # ----------------------------------------------------------------
              # link Hivent <- HistoricalChange
              hivent.historicalChanges.push historicalChange

          # finalize handle
          hiventHandle = new HG.HiventHandle @_hgInstance, hivent
          hivent.handle = hiventHandle
          @_hgInstance.hiventController.addHiventHandle hiventHandle

        # DONE!
        # hack: make min date slightly smaller to detect also first change
        newMinDate = minDate.clone()
        newMinDate.subtract 10, 'year'
        @notifyAll 'onFinishLoadingInitData', newMinDate

      error: @_errorCallback


  # ============================================================================
  # Save the outcome of an historical Operation to the server: the Hivent,
  # its associated HistoricalChange and their AreaChanges, including their
  # associated Areas, AreaNames and AreaTerritories.
  # All objects have temporary IDs, the server will create real IDs and return
  # them. This function also updates the IDs.
  # ============================================================================

  saveHistoricalOperation: (hiventData, historicalChange) ->

    # request data sent to the server

    request = {
      hivent:               null
      hivent_is_new:        yes
      historical_change:    {}
      new_areas:            []
      new_area_names:       []
      new_area_territories: []
    }

    # assemble relevant data for the request, resolving the circular double-link
    # structure to a one-directional hierarchical structure:
    # Hivent -> HistoricalChange -> [AreaChange] --> Area
    #                                            |-> AreaName / AreaTerritory

    ## Hivent: create new or update?
    if hiventData.isNew   # => create new Hivent
      hivent = new HG.Hivent hiventData
      hiventHandle = new HG.HiventHandle @_hgInstance, hivent
      hivent.handle = hiventHandle

    else # not isNew        => update existing Hivent
      hiventHandle = @_hgInstance.hiventController.getHiventHandle hiventData.id
      hivent = hiventHandle.getHivent()
      # override hivent data with new info from server
      $.extend hivent, hiventData

    # add to request
    request.hivent = @_hiventToServer hivent
    request.hivent_is_new = hiventData.isNew


    ## HistoricalChange: omit Hivent (link upward)
    request.historical_change = {
      id:           historicalChange.id
      operation:    historicalChange.operation
      area_changes: []  # store only ids, so they can be associated
    }

    ## AreaChanges: omit HistoricalChange (link upward), save only ids of Areas
    for areaChange in historicalChange.areaChanges
      request.historical_change.area_changes.push {
        id:                   areaChange.id
        operation:            areaChange.operation
        area:                 areaChange.area.id
        old_area_name:        areaChange.oldAreaName?.id
        old_area_territory:   areaChange.oldAreaTerritory?.id
        new_area_name:        areaChange.newAreaName?.id
        new_area_territory:   areaChange.newAreaTerritory?.id
      }

      ## new Area is part of each ADD operation
      if areaChange.operation is 'ADD'
        request.new_areas.push {
          id:   areaChange.area.id
        }

      ## new AreaName is part of each ADD and NCH operation
      if areaChange.operation is 'ADD' or areaChange.operation is 'NCH'
        request.new_area_names.push {
          id:           areaChange.newAreaName.id
          short_name:   areaChange.newAreaName.shortName
          formal_name:  areaChange.newAreaName.formalName
        }

      ## new AreaTerritory is part of each ADD and TCH operation
      if areaChange.operation is 'ADD' or areaChange.operation is 'TCH'
        request.new_area_territories.push {
          id:                   areaChange.newAreaTerritory.id
          geometry:             areaChange.newAreaTerritory.geometry.wkt()
          representative_point: areaChange.newAreaTerritory.representativePoint.wkt()
        }

      # make hivent and historicalChange accessible in success callback
      @_hivent =            hivent
      @_historicalChange =  historicalChange


      $.ajax
        url:  'save_operation/'
        type: 'POST'
        data: JSON.stringify request

        # success callback: load areas and hivents here and connect them
        success: (response) =>

          dataObj = $.parseJSON response

          ### UPDATE IDS AND ESTABLISH DOUBLE-LINKS ###

          ## Hivent: update with possibly new data from server
          @_hivent = $.extend @_hivent, @_hiventToClient dataObj.hivent


          ## HistoricalChange
          @_historicalChange.id = dataObj.historical_change_id

          # Hivent <-> HistoricalChange
          hivent.historicalChanges.push @_historicalChange
          @_historicalChange.hivent = hivent


          ## AreaChanges
          for areaChange in @_historicalChange.areaChanges

            # find associated areaChangeData id in response data
            for area_change in dataObj.area_changes
              if areaChange.id is area_change.old_id

                # update id
                areaChange.id = area_change.new_id

                ## Area
                areaChange.area.id = area_change.area_id

                # AreaChange <- Area
                switch areaChange.operation
                  when 'ADD' then         areaChange.area.startChange =       areaChange
                  when 'DEL' then         areaChange.area.endChange =         areaChange
                  when 'TCH', 'NCH' then  areaChange.area.updateChanges.push  areaChange

                ## AreaName
                if areaChange.oldAreaName
                  # id is already up to data
                  # AreaChange <- AreaName
                  areaChange.oldAreaName.endChange = areaChange

                if areaChange.newAreaName
                  # update id
                  areaChange.newAreaName.id = area_change.new_area_name_id
                  # AreaChange <- AreaName
                  areaChange.newAreaName.startChange = areaChange

                ## AreaTerritory
                if areaChange.oldAreaTerritory
                  # id is already up to data
                  # AreaChange <- AreaTerritory
                  areaChange.oldAreaTerritory.endChange = areaChange

                if areaChange.newAreaTerritory
                  # update id
                  areaChange.newAreaTerritory.id = area_change.new_area_territory_id
                  # AreaChange <- AreaTerritory
                  areaChange.newAreaTerritory.startChange = areaChange

          # finalize: make Hivent known to HistoGlobe (HiventController)
          @_hgInstance.hiventController.addHiventHandle @_hivent.handle
          @notifyAll 'onFinishSavingHistoricalOperation'

        error: @_errorCallback



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################


  # ============================================================================
  # data objects from the client to the server to each other
  # ============================================================================

  _areaTerritoryToServer: (dataObj) ->
    {
      id:                   parseInt dataObj.id
      geometry:             dataObj.geometry.wkt()
      representative_point: dataObj.representativePoint.wkt()
      area:                 dataObj.area?.id
      start_change:         dataObj.startChange?.id
      end_change:           dataObj.endChange?.id
    }

  # ----------------------------------------------------------------------------
  _areaTerritoryToClient: (dataObj) ->
    {
      id:                   parseInt dataObj.id
      geometry:             @_geometryReader.read dataObj.geometry
      representativePoint:  @_geometryReader.read dataObj.representative_point
      area:                 (@_hgInstance.areaController.getAreaHandle dataObj.area).getArea()
      startChange:          dataObj.start_change  # only id!
      endChange:            dataObj.end_change    # only id!
    }

  # ----------------------------------------------------------------------------
  _areaNameToServer: (dataObj) ->
    {
      id:           parseInt dataObj.id
      short_name:   dataObj.shortName
      formal_name:  dataObj.formalName
      area:         dataObj.area?.id
      start_change: dataObj.startChange?.id
      end_change:   dataObj.endChange?.id
    }

  # ----------------------------------------------------------------------------
  _areaNameToClient: (dataObj) ->
    {
      id:           parseInt dataObj.id
      shortName:    dataObj.short_name
      formalName:   dataObj.formal_name
      area:         (@_hgInstance.areaController.getAreaHandle dataObj.area).getArea()
      startChange:  dataObj.start_change  # only id!
      endChange:    dataObj.end_change    # only id!
    }

  # ----------------------------------------------------------------------------
  _hiventToClient: (dataObj) ->
    {
      id:           dataObj.id
      name:         dataObj.name
      date:         moment(dataObj.date)
      location:     dataObj.location    ?= null
      description:  dataObj.description ?= null
      link:         dataObj.link        ?= null
    }

  # ----------------------------------------------------------------------------
  _hiventToServer: (dataObj) ->
    {
      id:           dataObj.id
      name:         dataObj.name
      date:         dataObj.date
      location:     dataObj.location
      description:  dataObj.description
      link:         dataObj.link
    }

  # ----------------------------------------------------------------------------
  _historicalChangeToClient: (dataObj) ->
    {
      id:           parseInt dataObj.id
      operation:    dataObj.operation
      hivent:       dataObj.hivent
      areaChanges:  dataObj.area_changes  # not changed, yet
    }

  # ----------------------------------------------------------------------------
  _historicalChangeToServer: (dataObj) ->
    # TODO if necessary

  # ----------------------------------------------------------------------------
  _areaChangeToClient: (dataObj, areaNames, areaTerritories) ->
    {
      id:               parseInt dataObj.id
      operation:        dataObj.operation
      historicalChange: dataObj.historical_change # not changed, yet
      area:             (@_hgInstance.areaController.getAreaHandle dataObj.area)?.getArea()
      oldAreaName:      areaNames.filter (obj) -> obj.id is dataObj.old_area_name
      newAreaName:      areaNames.filter (obj) -> obj.id is dataObj.new_area_name
      oldAreaTerritory: areaTerritories.filter (obj) -> obj.id is dataObj.old_area_territory
      newAreaTerritory: areaTerritories.filter (obj) -> obj.id is dataObj.new_area_territory
    }

  # ----------------------------------------------------------------------------
  _areaChangeToServer: (dataObj) ->
    # TODO if necessary


  # ============================================================================
  # validation for all data in HistoricalChange
  # ensures that HistoricalChange can correctly be executed
  # ============================================================================

  _validateHistoricalChange: (dataObj) ->

    # check if id is a number
    if isNaN(dataObj.id)
      return console.error "The id is not valid"

    # check if operation type is correct
    if ['CRE','UNI','INC','SEP','SEC','NCH','TCH','BCH','DES'].indexOf(dataObj.operation) is -1
      return console.error "The operation type " + dataObj.operation + " is not valid"

    # got all the way here? Then everything is good :)
    return dataObj


  # ============================================================================
  # validation for all data in AreaChange
  # ensures that AreaChange can correctly be executed
  # ============================================================================

  _validateAreaChange: (dataObj) ->

    # check if id is a number
    dataObj.id = parseInt dataObj.id
    if isNaN(dataObj.id)
      return console.error "The id is not valid"
    # check if operation type is correct
    if ['ADD','DEL','TCH','NCH'].indexOf(dataObj.operation) is -1
      return console.error "The operation type " + dataObj.operation + " is not valid"

    # check if area is given
    if not dataObj.area
      return console.error "The associated Area could not been found"

    # check if old/new area name/territories are singular
    if dataObj.oldAreaName.length is 0
      dataObj.oldAreaName = null
    else if dataObj.oldAreaName.length is 1
      dataObj.oldAreaName = dataObj.oldAreaName[0]
    else
      return console.error "There have been multiple AreaNames found, this is impossible"

    if dataObj.newAreaName.length is 0
      dataObj.newAreaName = null
    else if dataObj.newAreaName.length is 1
      dataObj.newAreaName = dataObj.newAreaName[0]
    else
      return console.error "There have been multiple AreaNames found, this is impossible"

    if dataObj.oldAreaTerritory.length is 0
      dataObj.oldAreaTerritory = null
    else if dataObj.oldAreaTerritory.length is 1
      dataObj.oldAreaTerritory = dataObj.oldAreaTerritory[0]
    else
      return console.error "There have been multiple AreaTerritorys found, this is impossible"

    if dataObj.newAreaTerritory.length is 0
      dataObj.newAreaTerritory = null
    else if dataObj.newAreaTerritory.length is 1
      dataObj.newAreaTerritory = dataObj.newAreaTerritory[0]
    else
      return console.error "There have been multiple AreaTerritorys found, this is impossible"

    # check if operation has necessary new/old area name/territory
    switch dataObj.operation

      when 'ADD'
        if not (
            (dataObj.newAreaName)           and
            (dataObj.newAreaTerritory)      and
            (not dataObj.oldAreaName)       and
            (not dataObj.oldAreaTerritory)
          )
          return console.error "The ADD operation does not have the expected data provided"

      when 'DEL'
        if not (
            (not dataObj.newAreaName)       and
            (not dataObj.newAreaTerritory)  and
            (dataObj.oldAreaName)           and
            (dataObj.oldAreaTerritory)
          )
          return console.error "The DEL operation does not have the expected data provided"

      when 'TCH'
        if not (
            (not dataObj.newAreaName)       and
            (dataObj.newAreaTerritory)      and
            (not dataObj.oldAreaName)       and
            (dataObj.oldAreaTerritory)
          )
          return console.error "The TCH operation does not have the expected data provided"

      when 'NCH'
        if not (
            (dataObj.newAreaName)           and
            (not dataObj.newAreaTerritory)  and
            (dataObj.oldAreaName)           and
            (not dataObj.oldAreaTerritory)
          )
          return console.error "The NCH operation does not have the expected data provided"

    # got all the way here? Then everything is good :)
    return dataObj


    # ==========================================================================
    # error callback
    # ==========================================================================

    _errorCallback: (xhr, status, errorThrown) ->
      console.log xhr
      console.log status
      console.log errorThrown