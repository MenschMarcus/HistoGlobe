window.HG ?= {}

class HG.ABTest

  constructor: (config)->
    @config = config

  hgInit: (hgInstance) ->
    hgInstance.abTest = @
