window.HG ?= {}

class HG.SearchBoxForm

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  #   --------------------------------------------------------------------------
  constructor: () ->
    defaultConfig =
      #method: "get"
      #action: "http://www.google.com"
      tooltip:  "Suchfeld - Demnächst verfügbar"

    @_config = $.extend {}, defaultConfig

  hgInit: (@_hgInstance) ->

    @_hgInstance.searchForm = @

    if @_hgInstance.searchBoxArea?
      searchForm =
        callback: ()-> console.log "Not implmented"

      @_hgInstance.searchBoxArea.addSearchBox searchForm

    else
      console.error "Failed to add search form: SearchBoxArea module not found!"