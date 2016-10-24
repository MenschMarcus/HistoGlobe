window.HG ?= {}

class HG.CategoryIconMapping

  # TODO: Find a better way of dealing with categories and items...
  # - hierarchical categories

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->
    defaultConfig =
      default:
        default: "data/hivent_icons/icon_default.png"
        highlighted: "data/hivent_icons/icon_default_highlight.png"

    @_config = $.extend {}, defaultConfig, config

  # ============================================================================
  hgInit: (hgInstance) ->
    hgInstance.categoryIconMapping = @

    # idea: each category that does not have an IconMapping gets the default one

    # get all categories from IconMapping
    mappingCategories = []
    for category of @_config
      if (mappingCategories.indexOf category) is -1
        mappingCategories.push category

    # get all categories from hivents that should get the default values
    defaultCategories = []
    for handle in hgInstance.hiventController.getHivents()
      category = handle.getHivent().category
      # if category is not given in IconMapping and is unique
      if (mappingCategories.indexOf category) is -1 and
         (defaultCategories.indexOf category) is -1
        defaultCategories.push category

    # for each category, create default object
    for category in defaultCategories
      @_config[category] = @_config.default

  # ============================================================================
  getCategories: () ->
    return Object.keys @_config

  # ============================================================================
  getIcons: (category) ->
    if @_config.hasOwnProperty category
      return @_config[category]
    return @_config.default

window.HG ?= {}
