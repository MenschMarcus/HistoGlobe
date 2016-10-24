window.HG ?= {}

# ==============================================================================
# MODEL
# Hivent stores all information belonging to a specific historical event.
# DTO => no functionality
# ==============================================================================

class HG.Hivent

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  constructor: (data)  ->
    @handle             = null  # HG.HiventHandle

    @id                 = data.id
    @name               = data.name
    @date               = data.date
    @location           = data.location
    @description        = data.description
    @link               = data.link

    @historicalChanges  = []     # HG.HistoricalChange