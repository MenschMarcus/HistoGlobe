window.HG ?= {}

class HG.Timeline

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onIntervalChanged'
    @addCallback 'onZoom'

    # handle config
    defaultConfig =
      minZoom: 1
      maxZoom: 7
      startZoom: 2

    @_config = $.extend {}, defaultConfig, config

    # init members
    @_minDate = null
    @_maxDate = null
    @_dragged = false

  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add module to HG instance
    @_hgInstance.timeline = @

    # includes
    @_domElemCreator = new HG.DOMElementCreator

    ### INIT MEMBERS ###
    @_minDate = @_hgInstance.timeController.getMinDate()
    @_maxDate = @_hgInstance.timeController.getMaxDate()

    @_dateMarkers = []

    @notifyAll 'onIntervalChanged', @_getTimeFilter()


    ### SETUP UI ELEMENTS ###

    # main container for swiper
    @_timeline = @_domElemCreator.create 'div', 'tl-main', ['swiper-container', 'no-text-select']
    @_hgInstance.getBottomArea().appendChild @_timeline

    # first div needed for swiper (wrapper)
    @_tlWrapper = @_domElemCreator.create 'div', 'tl-wrapper', ['swiper-wrapper', 'no-text-select']
    @_timeline.appendChild @_tlWrapper

    # only purpose of that div: have a top border for the timeline
    # -> if HistoGraph extends tl wrapper up, it will still be the border
    # for the date markers
    @_tlBorder = @_domElemCreator.create 'div', 'tl-border', ['no-text-select']
    @_timeline.appendChild @_tlBorder

    # second div needed for swiper -> the one that is actually moving
    @_tlSlider = @_domElemCreator.create 'div', 'tl-slide', ['swiper-slide', 'no-text-select']
    @_tlWrapper.appendChild @_tlSlider


    # drag timeline
    # = transition of timeline container with swiper.j
    # swiper in Free Mode
    @_timelineSwiper ?= new Swiper '#tl-main',
      mode: 'horizontal'
      freeMode: true
      momentumRatio: 0.5
      scrollContainer: true

      onTouchStart: =>
        @_dragged = false
        @_moveDelay = 0

      onTouchMove: =>
        @_dragged = true
        @_updateNowDate @_moveDelay++ % 10 == 0
        @_updateDateMarkers()

      onTouchEnd: =>

      onSetWrapperTransition: (s, d) =>
        update_iteration_obj = setInterval =>
          @_updateNowDate true
          @_updateDateMarkers()
        , 50
        setTimeout =>
          clearInterval update_iteration_obj
        , d

    # start timeline
    @_updateLayout()
    @_updateDateMarkers()
    @_updateNowDate()


    @_hgInstance.onAllModulesLoaded @, () =>

      ### INTERACTION ###

      # zoom
      @_hgInstance.buttons.timelineZoomIn.onClick @, () =>
        @_zoom(1)

      @_hgInstance.buttons.timelineZoomOut.onClick @, () =>
        @_zoom(-1)

      # zoom timeline
      @_timeline.addEventListener "mousewheel", (e) =>
        e.preventDefault()
        @_zoom e.wheelDelta, e

      @_timeline.addEventListener "DOMMouseScroll", (e) =>
        e.preventDefault()
        @_zoom -e.detail, e

      # minimize UI
      @_hgInstance.minGUIButton?.onRemoveGUI @, () ->
        @_hideCategories()

      @_hgInstance.minGUIButton?.onOpenGUI @, () ->
        @_showCategories()

      # update now date
      @_hgInstance.timeController.onNowChanged @, (date) =>
        @_moveToDate date, 1
        @_updateDateMarkers()
        @notifyAll 'onIntervalChanged', @_getTimeFilter()


      # resize window
      $(window).resize  =>
        @_updateLayout()
        @_updateDateMarkers()
        @_updateNowDate()


  # ============================================================================
  # GETTER

  getSlider: () ->        @_tlSlider
  getInterval: () ->      [@_minVisibleDate(), @_maxVisibleDate]
  getDatePos: (date) ->   @_dateToPosition date


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _moveToDate: (date, delay=0, successCallback=undefined) ->
    if @_minDate > date
      @_moveToDate @_minDate, delay, successCallback
    else if @_maxDate < date
      @_moveToDate @_maxDate, delay, successCallback
    else
      dateDiff = @_minDate.valueOf() - date.valueOf()
      @_tlWrapper.style.transition =      delay + "s"
      @_tlWrapper.style.transform =       "translate3d(" + dateDiff / @_millisPerPixel() + "px ,0px, 0px)"
      @_tlWrapper.style.webkitTransform = "translate3d(" + dateDiff / @_millisPerPixel() + "px ,0px, 0px)"
      @_tlWrapper.style.MozTransform =    "translate3d(" + dateDiff / @_millisPerPixel() + "px ,0px, 0px)"
      @_tlWrapper.style.MsTransform =     "translate3d(" + dateDiff / @_millisPerPixel() + "px ,0px, 0px)"
      @_tlWrapper.style.oTransform =      "translate3d(" + dateDiff / @_millisPerPixel() + "px ,0px, 0px)"

      setTimeout(successCallback, delay * 1000) if successCallback?


  # ============================================================================
  _getTimeFilter: ->
    timefilter = []
    timefilter.end =    @_maxVisibleDate()
    timefilter.start =  @_minVisibleDate()
    timefilter.now =    @_hgInstance.timeController.getNowDate()
    timefilter


  # ============================================================================
  _millisPerPixel: ->
    (@_yearsToMillis(@_maxDate.year() - @_minDate.year()) / window.innerWidth) / @_config.startZoom

  _minVisibleDate: ->
    moment(@_hgInstance.timeController.getNowDate().valueOf() - (@_millisPerPixel() * window.innerWidth / 2))

  _maxVisibleDate: ->
    moment(@_hgInstance.timeController.getNowDate().valueOf() + (@_millisPerPixel() * window.innerWidth / 2))

  _timelineLength: ->
    @_yearsToMillis(@_maxDate.year() - @_minDate.year()) / @_millisPerPixel()

  _timeInterval: (i) ->
    x = Math.floor(i/3)
    if i % 3 == 0
      return @_yearsToMillis(Math.pow(10, x))
    if i % 3 == 1
      return @_yearsToMillis(2 * Math.pow(10, x))
    if i % 3 == 2
      return @_yearsToMillis(5 * Math.pow(10, x))


  # ============================================================================
  # helper functions: calculations date and position
  _dateToPosition: (date) ->
    dateDiff = date.valueOf() - @_minDate.valueOf()
    pos = (dateDiff / @_millisPerPixel()) + window.innerWidth/2

  _yearToDate: (year) ->
    moment(year, 'YYYY')

  _yearsToMillis: (year) ->
    millis = year * 365.25 * 24 * 60 * 60 * 1000

  _monthsToMillis: (months) ->
    millis = months * 30 * 24 * 60 * 60 * 1000

  _yearsToMonths: (years) ->
    months = Math.round(years * 12)

  _millisToYears: (millis) ->
    year = millis / 1000 / 60 / 60 / 24 / 365.25

  _millisToMonths: (millis) ->
    months = Math.round(millis / 1000 / 60 / 60 / 24 / 365.25 / 12)

  _daysToMillis: (days) ->
    millis = days * 24 * 60 * 60 * 1000

  _millisToDays: (millis) ->
    days = millis / 1000 / 60 / 60 / 24

  # ============================================================================
  # move and zoom
  _zoom: (delta, e=null, layout=true) =>
    zoomed = false
    if delta > 0
      if @_millisToDays(@_maxVisibleDate().valueOf()) - @_millisToDays(@_minVisibleDate().valueOf()) > @_config.maxZoom
        @_config.startZoom *= 1.1
        zoomed = true
    else
      if @_config.startZoom > @_config.minZoom
        @_config.startZoom /= 1.1
        zoomed = true

    if zoomed
      @_updateLayout() if layout
      @_updateDateMarkers()
      @notifyAll 'onZoom'
      @notifyAll 'onIntervalChanged', @_getTimeFilter()

    zoomed


  # ============================================================================
  # UI
  _updateLayout: ->
    @_timeline.style.width = window.innerWidth + "px"
    @_tlSlider.style.width = (@_timelineLength() + window.innerWidth) + "px"
    @_moveToDate @_hgInstance.timeController.getNowDate()
    @_timelineSwiper.reInit()
    @notifyAll 'onIntervalChanged', @_getTimeFilter()


  # ----------------------------------------------------------------------------
  _updateNowDate: (fireCallbacks =true) ->
    currPosToMillis = (-1) * @_timelineSwiper.getWrapperTranslate("x") * @_millisPerPixel()
    nowDate = @_minDate.clone().add(currPosToMillis, 'milliseconds').startOf('day')
    if fireCallbacks
      @_hgInstance.timeController.setNowDate @, nowDate
      @notifyAll 'onIntervalChanged', @_getTimeFilter()

  # ----------------------------------------------------------------------------
  # can internally keep on using date object, because it does not interfer with
  # nowDate, monDate or maxDate
  _updateDateMarkers: ->

    # TODO: find the error in here !!!

    # get interval
    intervalIndex = MIN_INTERVAL_INDEX
    while @_timeInterval(intervalIndex) <= window.innerWidth * @_millisPerPixel() * INTERVAL_SCALE
      intervalIndex++
    interval = @_timeInterval(intervalIndex)

    # scale datemarker
    $(".tl-datemarker").css({"max-width": Math.round(interval / @_millisPerPixel()) + "px"})

    # for every year on timeline check if datemarker is needed
    # or can be removed.
    for i in [0..@_maxDate.year() - @_minDate.year()]
      year = @_minDate.year() + i

      # fits year to interval?
      if year % @_millisToYears(interval) == 0 and
         year >= @_minVisibleDate().year() and
         year <= @_maxVisibleDate().year()

        # show datemarker
        if !@_dateMarkers[i]?

          # create new
          @_dateMarkers[i] =
            div: @_domElemCreator.create 'div', 'tl-year_' + year, 'tl-datemarker'
            year: year
            months: []
          @_dateMarkers[i].div.innerHTML = year + '<div class="tl-months"></div>'
          @_dateMarkers[i].div.style.left = @_dateToPosition(@_yearToDate(year)) + "px"

          @_tlSlider.appendChild @_dateMarkers[i].div

          # show and create months
          if @_millisToYears(interval) == 1
            for month_name, key in MONTH_NAMES
              month =
                div: @_domElemCreator.create 'div', null, 'tl-month'
                startDate: moment()
                endDate: moment()
                name: month_name
              month.startDate.year(year, key, 1)
              month.endDate.year(year, key + 1, 0)
              month.div.innerHTML = month.name
              month.div.style.left = ((month.startDate.valueOf() - @_yearToDate(year).valueOf()) / @_millisPerPixel()) + "px"
              month.div.style.width = (@_dateToPosition(month.endDate) - @_dateToPosition(month.startDate)) + "px"
              $("#tl-year_" + year + " > .tl-months" ).append month.div
              @_dateMarkers[i].months[key] = month

          # hide and delete months
          else
            for months in @_dateMarkers[i].months
              $(month.div).fadeOut(FADE_ANIMATION_TIME, `function() { $(this).remove(); }`)
            @_dateMarkers[i].months.length = 0
          $(@_dateMarkers[i].div).fadeIn FADE_ANIMATION_TIME
        else

          # update existing datemarker and his months
          @_dateMarkers[i].div.style.left = @_dateToPosition(@_yearToDate(year)) + "px"
          if @_millisToYears(interval) == 1

            # show months, create new month divs
            if @_dateMarkers[i].months.length == 0
              for month_name, key in MONTH_NAMES
                month =
                  div: @_domElemCreator.create 'div', null, 'tl-month'
                  startDate: moment()
                  endDate: moment()
                  name: month_name
                month.startDate.year(year, key, 1)
                month.endDate.year(year, key + 1, 0)
                month.div.innerHTML = month.name
                month.div.style.left = ((month.startDate.valueOf() - @_yearToDate(year).valueOf()) / @_millisPerPixel()) + "px"
                month.div.style.width = (@_dateToPosition(month.endDate) - @_dateToPosition(month.startDate)) + "px"
                $("#tl-year_" + year + " > .tl-months" ).append month.div
                @_dateMarkers[i].months[key] = month

            # update existing month divs
            else
              for month in @_dateMarkers[i].months
                month.div.style.left = ((month.startDate.valueOf() - @_yearToDate(year).valueOf()) / @_millisPerPixel()) + "px"
                month.div.style.width = (@_dateToPosition(month.endDate) - @_dateToPosition(month.startDate)) + "px"

          # hide and delete months
          else
            for month in @_dateMarkers[i].months
              $(month.div).fadeOut(FADE_ANIMATION_TIME, `function() { $(this).remove(); }`)
            @_dateMarkers[i].months.length = 0

      # hide and delete datemarker and their months
      else
        if @_dateMarkers[i]?
          @_dateMarkers[i].div.style.left = @_dateToPosition(@_yearToDate(year)) + "px"
          $(@_dateMarkers[i].div).remove()
          @_dateMarkers[i] = null


  ##############################################################################
  #                            STATIC CONSTANTS                                #
  ##############################################################################

  MIN_INTERVAL_INDEX = 0      # 0 = 1 Year | 1 = 2 Year | 2 = 5 Years | 3 = 10 Years | ...
  INTERVAL_SCALE = 0.05       # higher value makes greater intervals between datemarkers
  FADE_ANIMATION_TIME = 200   # fade in time for datemarkers and so

  MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]