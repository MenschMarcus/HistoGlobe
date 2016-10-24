window.HG ?= {}

# ============================================================================
# MODEL class
# contains data about an AreaName associated to an Area
# ============================================================================

class HG.AreaTerritory

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (data) ->

    @id                   = data.id

    # main properties
    @geometry             = data.geometry             # HG.Geometry
    @representativePoint  = data.representativePoint  # HG.Point

    # superordinate object
    @area                 = null                      # HG.Area

    # historical context
    @startChange          = null                      # HG.AreaChange
    @endChange            = null                      # HG.AreaChange


  # ============================================================================
  resetRepresentativePoint: () ->
    @representativePoint = @geometry.getCenter()