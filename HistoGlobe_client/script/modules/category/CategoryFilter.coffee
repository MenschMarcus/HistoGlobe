window.HG ?= {}

class HG.CategoryFilter

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback "onFilterChanged"
    @addCallback "onPrefixFilterChanged"

    @_categoryFilter = []
    @_categoriesExcluded = []
    @_prefixesExcluded = []

    defaultConfig =
      initial: "noCategory"

    @_config = $.extend {}, defaultConfig, config

    @setCategory @_config.initial


  # ============================================================================
  hgInit: (hgInstance) ->
    hgInstance.categoryFilter = @

  # ============================================================================
  getCurrentFilter:() ->
    @_categoryFilter

  # ============================================================================
  exclusiveFilter: (category,outOfThese) ->

    for candidate in outOfThese
      @_categoryFilter = @_categoryFilter.filter (item) -> item isnt candidate
      @_categoriesExcluded = @_categoriesExcluded.filter (item) -> item isnt candidate

    @filter category


    for candidate in outOfThese
      #new:
      for prefix in @_prefixesExcluded
        for filter in @_categoryFilter
          if filter.indexOf(prefix) is 0
            @_categoryFilter = @_categoryFilter.filter (item) -> item isnt filter
            @_categoriesExcluded.push filter

      #console.log category, @_categoryFilter
      @notifyAll "onPrefixFilterChanged", @_categoryFilter


  # ============================================================================
  filter: (category) ->
    if @_isArray category
      for c in category
        @_categoryFilter.push c
    else
      @_categoryFilter.push category

    @notifyAll "onFilterChanged", @_categoryFilter

  # ============================================================================
  setCategory: (category) ->
    if @_isArray category
      @_categoryFilter = category
    else
      @_categoryFilter = [category]

    @notifyAll "onFilterChanged", @_categoryFilter

  # ============================================================================
  addCategory: (category) ->
    if @_isArray category
      for c in category
        @_categoryFilter.push c
    else
      @_categoryFilter.push category

    @notifyAll "onFilterChanged", @_categoryFilter

  # ============================================================================
  removeCategory: (category) ->
    if @_isArray category
      for c in category
        @_categoryFilter = @_categoryFilter.filter (item) -> item isnt c
    else
      @_categoryFilter = @_categoryFilter.filter (item) -> item isnt category

    @notifyAll "onFilterChanged", @_categoryFilter


  # ============================================================================
  checkFilter: (domElement,category) ->

    $(domElement).toggleClass "active"

    if $(domElement).hasClass("active")
      @_categoryFilter.push category
      #console.log "pushed2: ",category
    else
      @_categoryFilter = @_categoryFilter.filter (item) -> item isnt category

    #console.log "filtered: ", @_categoryFilter

    @notifyAll "onFilterChanged", @_categoryFilter

  # ============================================================================
  checkPrefixFilter: (domElement,prefix) ->

    $(domElement).toggleClass "active"

    if $(domElement).hasClass("active")
      #@_categoryFilter.push category
      #console.log "pushed2: ",category
      for filter in @_categoriesExcluded
        if filter.indexOf(prefix) is 0
          @_categoryFilter.push filter
          @_categoriesExcluded = @_categoriesExcluded.filter (item) -> item isnt filter
      @_prefixesExcluded = @_prefixesExcluded.filter (item) -> item isnt prefix

    else
      #@_categoryFilter = @_categoryFilter.filter (item) -> item isnt category
      for filter in @_categoryFilter
        if filter.indexOf(prefix) is 0
          #console.log prefix," is in ",filter
          @_categoryFilter = @_categoryFilter.filter (item) -> item isnt filter
          #console.log @_categoryFilter
          @_categoriesExcluded.push filter
      @_prefixesExcluded.push prefix


    #console.log "filtered: ", @_categoryFilter

    @notifyAll "onPrefixFilterChanged", @_categoryFilter


  # ============================================================================
  make_filterable:(domElement,config,className) ->

    if config.filterable
      #domElement.className = "legend-row legend-row-filterable active"
      domElement.className = domElement.className + " " + domElement.className + "-filterable active"
      @_categoryFilter.push config.category
      #console.log "pushed3: ",config.category
    else
      #domElement.className = "legend-row legend-row-non-filterable"
      domElement.className = domElement.className + " " + domElement.className + "-non-filterable"

  # ============================================================================
  _isArray:(value) ->
    (Object.prototype.toString.call value) is '[object Array]'



