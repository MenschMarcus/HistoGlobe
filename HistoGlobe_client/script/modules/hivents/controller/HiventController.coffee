window.HG ?= {}

# ==============================================================================
# HiventController is used to load Hivent data from files and store them into
# buffers. Additionally, this class provides functionality to filter and access
# Hivents.
# ==============================================================================
class HG.HiventController

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # Constructor
  # Initializes members and stores the given configuration named "config".
  # ============================================================================
  constructor: (config) ->

    ## init callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onHiventAdded'
    @addCallback 'onChangeAreas'


    ## init config
    defaultConfig =
      dsvConfigs: undefined
      numHiventsInView: 10

    @_config = $.extend {}, defaultConfig, config


    ## init member variables
    @_hiventHandles           = []
    @_handlesNeedSorting      = false

    @_currentTimeFilter       = null  # {start: <Date>, end: <Date>}
    @_currentSpaceFilter      = null  # { min: {lat: <float>, long: <float>},
                                      #   max: {lat: <float>, long: <float>}}
    @_currentCategoryFilter   = null  # [category_a, category_b, ...]
    @_categoryFilter          = null

    @_nowDate = null                  # current date


  # ============================================================================
  # Issues configuration depending on the current HistoGlobe instance.
  # ============================================================================
  hgInit: (@_hgInstance) ->

    # add module to HistoGlobe instance
    @_hgInstance.hiventController = @


    ### INTERACTION ###

    @_hgInstance.onAllModulesLoaded @, () =>

      # load initial Hivents on load from DatabaseInterface
      @_hgInstance.databaseInterface.onFinishLoadingInitData @, (minDate) ->

        @_sortHivents()

        # create current state on the map
        # -> accumulate all changes from the earliest hivent until now
        oldDate = minDate
        nowDate = @_hgInstance.timeController.getNowDate()

        @_findHistoricalChanges oldDate, nowDate

        @_nowDate = @_hgInstance.timeController.getNowDate()


      # load initial Hivents on load from DatabaseInterface
      @_hgInstance.databaseInterface.onFinishSavingHistoricalOperation @, () ->
        @_sortHivents()


      ### VIEW ###

      ## load hivents that have happened since last now change
      @_hgInstance.timeController.onNowChanged @, (nowDate) =>

        # error handling: nowDate will not be set
        return if not @_nowDate

        # get change dates
        oldDate = @_nowDate
        newDate = nowDate

        @_findHistoricalChanges oldDate, newDate

        @_nowDate = nowDate



  # ============================================================================
  # Sets the current time filter to the value of "timeFilter". The passed value
  # has to be an object of format {start: <Date>, end: <Date>}
  # ============================================================================

  setTimeFilter: (timeFilter) ->
    @_currentTimeFilter = timeFilter
    @_filterHivents();


  # ============================================================================
  # Sets the current space filter to the value of "spaceFilter". The passed
  # value has to be an object of format
  # { min: {lat: <float>, long: <float>},
  #   max: {lat: <float>, long: <float>}}
  # ===========================================================================

  setSpaceFilter: (spaceFilter) ->
    @_currentSpaceFilter = spaceFilter
    @_filterHivents()


  # ============================================================================
  # Adds a created HiventHandle to the list
  # ============================================================================

  addHiventHandle: (hiventHandle) ->
    @_hiventHandles.push hiventHandle
    @_handlesNeedSorting = yes

    # listen to destruction callback and tell everybody about it
    hiventHandle.onDestroy @, () =>
      @_hiventHandles.splice(@_hiventHandles.indexOf(hiventHandle), 1)


  # ============================================================================
  # Returns all stored HiventHandles.
  # Additionally, if "object" and "callbackFunc" are specified, "callbackFunc"
  # is registered to be called for every Hivent loaded in the future and called
  # for every Hivent that has been loaded already.
  # ============================================================================

  getHivents: (object, callbackFunc) ->
    if object? and callbackFunc?
      @onHiventAdded object, callbackFunc

      for handle in @_hiventHandles
        @notify "onHiventAdded", object, handle

    @_hiventHandles


  # ============================================================================
  # Returns a HiventHandle by the specified "hiventId". Every Hivent has to be
  # assigned a unique ID to avoid unexpected behaviour.
  # ============================================================================

  getHiventHandle: (hiventId) ->
    for handle in @_hiventHandles
      if handle.getHivent().id is hiventId
        return handle
    console.log "A Hivent with the id \"#{hiventId}\" does not exist!"
    return null


  # ============================================================================
  # Returns a HiventHandle by the specified index of the internal array.
  # ============================================================================
  getHiventHandleByIndex: (handleIndex) ->
    return @_hiventHandles[handleIndex]


  # ============================================================================
  # Get the next / previous HiventHandle.
  # Next / Previous in this case means the chronologically closest Hivent
  # after / before the date specified by the passed Date object "now".
  # "ignoredIds" can be specified to exclude specific HiventHandles from being
  # selected.
  # ============================================================================

  getNextHiventHandle: (now, ignoredIds=[]) ->
    result = null
    distance = -1
    handles = @_hiventHandles

    for handle in handles
      if handle._state isnt 0 and not (handle.getHivent().id in ignoredIds)
        diff = handle.getHivent().date.getTime() - now.getTime()
        if (distance is -1 or diff < distance) and diff >= 0
          distance = diff
          result = handle
    return result


  # ----------------------------------------------------------------------------

  getPreviousHiventHandle: (now, ignoredIds=[]) ->
    result = null
    distance = -1
    handles = @_hiventHandles

    for handle in handles
      if handle._state isnt 0 and not (handle.getHivent().id in ignoredIds)
        diff = now.getTime() - handle.getHivent().date.getTime()
        if (distance is -1 or diff < distance) and diff >= 0
          distance = diff
          result = handle
    return result


  # ============================================================================
  # Blends in all visible Hivents.
  # ============================================================================

  showVisibleHivents: ->
    for handle in @_hiventHandles

      state = handle._state

      if state isnt 0
        handle.setState 0
        handle.setState state



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################


  # ============================================================================
  # find Hivents happening between two dates and execute their changes
  # ============================================================================

  _findHistoricalChanges: (oldDate, newDate) ->

      # change direction: forward (+1) or backward (-1)
      changeDir = if oldDate < newDate then +1 else -1

      # opposite direction: swap old and new date, so it can be assumed that always oldDate < newDate
      if changeDir is -1
        tempDate = oldDate
        oldDate = newDate
        newDate = tempDate

      # distance user has scrolled
      timeLeap = Math.abs(oldDate.year() - newDate.year())

      # go through all changes in (reversed) order
      # check if the change date is inside the change range from the old to the new date
      # as soon as one change is inside, all changes will be executed until one change is outside the range
      # -> then termination of the loop
      inChangeRange = no
      changes = []

      # IMP!!! if change direction is the other way, also the hivents have
      # to be looped through the other way!
      for hiventHandle in @_hiventHandles by changeDir

        if hiventHandle.happenedBetween oldDate, newDate

          # state that a change is found => entered change range of hivents
          inChangeRange = yes

          # TODO: make nicer later
          for historicalChange in hiventHandle.getHivent().historicalChanges
            historicalChange.execute changeDir, timeLeap

        # N.B: if everything is screwed up: comment the following three lines ;)
        else
          # loop went out of change range => no hivent will be following
          break if inChangeRange


      # tell everyone if new changes
      # @notifyAll 'onChangeAreas', changes, changeDir, timeLeap if changes.length isnt 0



  # ============================================================================
  # Sorts all HiventHandles by date
  # ============================================================================

  _sortHivents: ->
    # filter by date
    @_hiventHandles.sort (a, b) =>
      if a? and b?
        # sort criterion 1) effect date
        unless a.getHivent().date is b.getHivent().date
          return a.getHivent().date - b.getHivent().date
        # sort criterion 2) id
        else
          if a.getHivent().id > b.getHivent().id
            return 1
          else if a.getHivent().id < b.getHivent().id
            return -1
      return 0


  # ============================================================================
  # Filters all HiventHandles according to all current filters
  # ============================================================================

  _filterHivents: ->
    if @_handlesNeedSorting
      @_sortHivents()

    for handle, i in @_hiventHandles
      if @_handlesNeedSorting
        handle.sortingIndex = i
      hivent = handle.getHivent()

      state = 1
      # 0 --> invisible
      # 1 --> visiblePast
      # 2 --> visibleFuture

      # filter by category
      if @_currentCategoryFilter?
        noCategoryFilter = @_currentCategoryFilter.length is 0
        defaultCategory = hivent.category is "default"
        inCategory = @_areEqual hivent.category, @_currentCategoryFilter
        unless noCategoryFilter or defaultCategory or inCategory
          state = 0

      if state isnt 0 and @_currentTimeFilter?
        # start date in visible future
        if hivent.date.getTime() > @_currentTimeFilter.now.getTime() and hivent.date.getTime() < @_currentTimeFilter.end.getTime()
          #make them visible in future
          state = 1
        # completely  outside
        else if hivent.date.getTime() > @_currentTimeFilter.end.getTime() or hivent.endDate.getTime() < @_currentTimeFilter.start.getTime()
          state = 0

      # filter by location
      if state isnt 0 and @_currentSpaceFilter?
        unless hivent.lat >= @_currentSpaceFilter.min.lat and
               hivent.long >= @_currentSpaceFilter.min.long and
               hivent.lat <= @_currentSpaceFilter.max.lat and
               hivent.long <= @_currentSpaceFilter.max.long
          state = 0

      if @_ab.hiventsOnTl is "A"
        handle.setState state
      else if @_ab.hiventsOnTl is "B"
        handle._tmp_state = state

      if state isnt 0
        if @_currentTimeFilter?
          # half of timeline:
          #new_age = Math.min(1, (hivent.endDate.getTime() - @_currentTimeFilter.start.getTime()) / (@_currentTimeFilter.now.getTime() - @_currentTimeFilter.start.getTime()))
          # quarter of timeline:
          new_age = Math.min(1, ((hivent.endDate.getTime() - @_currentTimeFilter.start.getTime()) / (0.5*(@_currentTimeFilter.now.getTime() - @_currentTimeFilter.start.getTime())))-1)
          if new_age isnt handle._age
            handle.setAge new_age

    @_handlesNeedSorting = false

  # ============================================================================
  _areEqual: (str1, str2) ->
    (str1?="").localeCompare(str2) is 0