window.HG ?= {}

# ==============================================================================
# A leaflet LabelLayer for an area name
# will be created and destructed by AreasOnMap
# listens to callbacks from AreaHandle directly
# ==============================================================================

class HG.AreaNameLayerOnMap

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # create a LabelLayer given the information extracted from the Area
  # ============================================================================

  constructor: (@_areaHandle, @_map, @_labelManager) ->

    ### INTERACTION ###

    ## AreaHandle -> THIS

    # actual show / hide / update behaviour is managed by a LabelManager
    @_areaHandle.onAddName @,         @_addLayer
    @_areaHandle.onUpdateName @,      @_updateLayer
    @_areaHandle.onRemoveName @,      @_removeLayer



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################


  # ============================================================================
  # add / update / remove the LabelLayer for the area
  # ============================================================================

  _addLayer: () ->

    # get data from model
    shortName =           @_areaHandle.getArea().name.shortName
    representativePoint = @_areaHandle.getArea().territory.representativePoint.latLng()
    priority = Math.round(@_areaHandle.getArea().territory.geometry.getArea()*1000)

    # create label with name and position
    @_areaHandle.labelLayer = new L.Label()
    @_areaHandle.labelLayer.setContent shortName
    @_areaHandle.labelLayer.setLatLng  representativePoint
    @_areaHandle.labelLayer.priority = priority

    # create double-link: leaflet label knows HG area and HG area knows leaflet label
    @_areaHandle.labelLayer.hgArea = @_areaHandle

    @_labelManager.insert @_areaHandle.labelLayer

  # ----------------------------------------------------------------------------
  _updateLayer: () ->

    # get updated data from model
    shortName =           @_areaHandle.getArea().name.shortName
    representativePoint = @_areaHandle.getArea().territory.representativePoint.latLng()
    priority = Math.round(@_areaHandle.getArea().territory.geometry.getArea()*1000)

    # update label information
    @_areaHandle.labelLayer.setContent shortName
    @_areaHandle.labelLayer.setLatLng  representativePoint
    @_areaHandle.labelLayer.priority = priority

    @_labelManager.update @_areaHandle.labelLayer

  # ----------------------------------------------------------------------------
  _removeLayer: () ->
    @_labelManager.remove @_areaHandle.labelLayer
    @_areaHandle.labelLayer = null


  # ============================================================================
  # long area names save space by adding linebreaks for each whitespace
  # just in case it is ever needed again...
  # ============================================================================

  _addLinebreaks : (name) =>
    # 1st approach: break at all whitespaces and dashed lines
    name = name.replace /\s/gi, '<br\>'
    name = name.replace /\-/gi, '-<br\>'

    # # find all whitespaces in the name
    # len = name.length
    # regEx = /\s/gi  # finds all whitespaces (\s) globally (g) and case-insensitive (i)
    # posWhite = []
    # while result = regEx.exec name
    #   posWhite.push result.index
    # for posW in posWhite

    name
