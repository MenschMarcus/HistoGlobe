window.HG ?= {}

# ==============================================================================
# This class knows the current date of the HistoGlobe instance (nowDate)
# it accepts all kinds of date strings, JS date objects and moment objects
# internally it uses the moment() library to store the date and returns only it
# each listener to onNowChanged needs to work with the moment.js object
# documentation: http://momentjs.com/docs/
# ==============================================================================

class HG.TimeController

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onNowChanged'


    # handle config
    defaultConfig = {}
    @_config = $.extend {}, defaultConfig, config

    # init members
    @_nowDate = null              # current date of HistoGlobe instance
    @_minDate = null              # minimum date of HistoGlobe instance
    @_maxDate = null              # maximum date of HistoGlobe instance

  # ============================================================================
  hgInit: (@_hgInstance) ->

    # add module to HG instance
    @_hgInstance.timeController = @

    # init members
    @_minDate = moment(@_hgInstance.config.minYear, 'YYYY')
    @_maxDate = moment(@_hgInstance.config.maxYear, 'YYYY')
    @_nowDate = @_cropToMinMax moment(@_hgInstance.config.nowYear, 'YYYY')


  # ============================================================================
  setNowDate: (sourceModule, inDate) ->

    dateObj = null

    ## validate different input formats and convert to moment() date object

    # 1) moment() date object
    if inDate._isAMomentObject
      dateObj = inDate

    # 2) JavaScript Date() object
    else if inDate instanceof Date
      dateObj = moment(inDate)

    # 3) date string
    else if moment(inDate, IN_DATE_FORMATS, true).isValid()
      dateObj = moment(inDate)

    ## use as internal date and tell everybody

    if dateObj
      @_nowDate = @_cropToMinMax dateObj
      # tell every module except for the one that initiated the date change
      # -> so it does not override its own changes, does things multiple times
      #    or even ends up in an infinite loop
      @notifyAllBut 'onNowChanged', sourceModule, @_nowDate


  # ============================================================================
  getNowDate: () ->    @_nowDate
  getMinDate: () ->    @_minDate
  getMaxDate: () ->    @_maxDate


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _cropToMinMax: (date) ->
    date = moment.max date, @_minDate
    date = moment.min date, @_maxDate
    date


  ##############################################################################
  #                            STATIC INTERFACE                                #
  ##############################################################################

  IN_DATE_FORMATS = [
    moment.ISO_8601,    # RFC 3339
    "YYYY"              # only year
    "DD.MM.YYYY",       # most parts of the world (.)
    "DD/MM/YYYY",       # most parts of the world (/)
    "YYYY-MM-DD",       # East Asia, Iran, Hungary and Lithuania
    "YYYY.MM.DD",       # East Asia, Iran, Hungary and Lithuania
    "MM/DD/YYYY",       # f*ck**g USA format
  ]