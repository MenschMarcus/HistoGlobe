window.HG ?= {}

# ============================================================================
# MODEL class
# contains data about an AreaName associated to an Area
# ============================================================================

class HG.AreaName

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (data) ->

    @id           = data.id

    # main properties
    @shortName    = data.shortName      # String
    @formalName   = data.formalName     # String

    # superordinate object
    @area         = null                # HG.Area

    # historical context
    @startChange  = null                # HG.AreaChange
    @endChange    = null                # HG.AreaChange