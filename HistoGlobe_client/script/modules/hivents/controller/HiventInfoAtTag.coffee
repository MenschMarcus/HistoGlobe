window.HG ?= {}

class HG.HiventInfoAtTag

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->
    defaultConfig =
      defaultHash: ""

    @_hashEntries = {}

    @_config = $.extend {}, defaultConfig, config

    if window.location.hash.length is 0
      window.location.hash = @_config.defaultHash

    @_readHash()

  # ============================================================================
  hgInit: (hgInstance) ->
    hgInstance.hiventInfoAtTag = @
    @_hgInstance = hgInstance

    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback "onHashChanged"

    hgInstance.onAllModulesLoaded @, () =>
      @_presenter       = hgInstance.hiventPresenter
      @_timeline        = hgInstance.timeline
      @_categoryFilter  = hgInstance.categoryFilter
      @_selfUpdate      = false

      $(window).on 'hashchange', () =>
        if @_selfUpdate
          @_selfUpdate = false
          return

        @_readHash()
        @_executeCallbacks()

      @_readHash()
      @_executeCallbacks()

  # ============================================================================
  setOption: (key, value) ->
    @_hashEntries[key] = value
    @_writeHash()

  # ============================================================================
  unsetOption: (key) ->
    delete @_hashEntries[key]
    @_selfUpdate = true
    @_writeHash()

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _readHash: () ->
    hash = window.location.hash.substring window.location.hash.indexOf("#") + 1

    if hash is ""
      return

    hash = hash.split('&')
    @_hashEntries = {}

    for h in hash
      target = h.split('=')
      if target.length is 2
        @_hashEntries[target[0]] = target[1]

  # ============================================================================
  _writeHash: () ->
    hash = "#"

    for target of @_hashEntries
      hash += target + "=" + @_hashEntries[target] + "&"

    hash = hash[0...hash.length-1]

    unless hash.length is 0
      window.location.hash = hash

  # ============================================================================
  _executeCallbacks: () ->
    for target of @_hashEntries
      switch target
        when "event"
          if @_presenter?
            @_presenter.present @_hashEntries[target]
        when "time"
          date = @_timeline.stringToDate @_hashEntries[target]
          @_timeline.moveToDate date, 0.5
        when "categories"
          categories = @_hashEntries[target].split '+'
          @_categoryFilter?.setCategory categories

      @notifyAll "onHashChanged", target, @_hashEntries[target]
