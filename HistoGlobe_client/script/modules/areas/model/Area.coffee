window.HG ?= {}

# ==============================================================================
# MODEL class
# contains data about each Area (territory + name + attributes)
# DTO => no functionality
# ==============================================================================

class HG.Area

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (id) ->

    @id             = id

    # properties (can change over time)
    @territory      = null            # HG.AreaTerritory
    @name           = null            # HG.AreaName

    # superordinate object
    @handle         = null            # HG.AreaHandle

    # historical changes
    @startChange    = null            # HG.AreaChange
    @updateChanges  = []              # HG.AreaChange
    @endChange      = null            # HG.AreaChange

    # historical context
    @predecessors   = []              # HG.Area
    @successors     = []              # HG.Area
