window.HG ?= {}

# ==============================================================================
# VIEW class
# set up and handle manipulating the geometry of one area
# approach:
#   use only leaflet draw and style the buttons
#   set up my own ButtonArea and move leaflet buttons in there
# ==============================================================================

class HG.NewTerritoryTool

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_hgInstance, restoreLayer, @_firstStep) ->

    @_hgInstance.newTerritoryTool = @

    # handle callbacks
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback 'onSubmit'

    # includes
    @_map = @_hgInstance.map.getMap()
    @_histoGraph = @_hgInstance.histoGraph
    @_geometryReader = new HG.GeometryReader
    @_geometryOperator = new HG.GeometryOperator
    @_domElemCreator = new HG.DOMElementCreator

    iconPath = @_hgInstance.config.graphicsPath + 'buttons/'


    ### SETUP LEAFLET DRAW ###

    # group that contains all drawn territories
    @_featureGroup = new L.FeatureGroup

    # add initial geometry to feature group, if it exists
    if restoreLayer
      @_featureGroup.addLayer layer for layer in restoreLayer

    @_map.addLayer @_featureGroup


    ### SETUP UI ###

    # leaflets draw control
    @_drawControl = new L.Control.Draw {
        position: 'topright',
        draw: {
          polyline: no
          polygon: {
            shapeOptions : {
              # = focus mode on -> selected -> unfocused
              'className':    'new-geom-area'
              'fillColor':    HGConfig.color_active.val
              'fillOpacity':  HGConfig.area_half_opacity.val
              'color':        HGConfig.color_bg_dark.val
              'opacity':      HGConfig.border_opacity.val
              'weight':       HGConfig.border_width.val
            }
          }
          rectangle: no
          circle: no
          marker: no
        },
        edit: {
          featureGroup: @_featureGroup
        }
      }
    @_map.addControl @_drawControl


    # PROBLEM:
    # leaflet already has buttons to control the draw action
    # but I want them to behave just like any other HG Button
    # SOLUTION:
    # extend the HG.Button class to also accept existing HG.DOMElements as
    # parent divs for the button
    # -> very hacky, but elegant solution ;)

    # get the three leaflet control buttons
    # [0]: new polygon
    # [1]: edit polygon
    # [2]: delete polygon
    leafletButtons = $('.leaflet-draw a')

    # get the action tooltips from the control to align them to the new buttons
    # -> this is actually really really hacky hacky hacky
    $($('.leaflet-draw ul')[0]).attr 'id', 'leaflet-new-button-action'
    $($('.leaflet-draw ul')[1]).attr 'id', 'leaflet-edit-button-action'


    ## button area
    # -> leaflet buttons to be moved in there

    @_buttonArea = new HG.ButtonArea @_hgInstance,
      {
        'id':           'newGeomButtons'
        'posX':         'right'
        'posY':         'top'
        'orientation':  'vertical'
      }
    @_hgInstance.getTopArea().appendChild @_buttonArea.getDOMElement()


    ## buttons themselves

    @_newGeomBtn = new HG.Button @_hgInstance,
        'newGeom', ['tooltip-left'],
        [
          {
            'id':             'normal'
            'tooltip':        "Add new territory"
            'iconOwn':        iconPath + 'geom_add.svg'
            'callback':       'onClick'
          }
        ], @_makeHGButton leafletButtons[0]    # use existing leaflet "add polygon" button
    @_buttonArea.addButton @_newGeomBtn, 'new-geom-add-group'

    @_reuseGeomBtn = new HG.Button @_hgInstance,
        'reuseGeom', ['tooltip-left'],
        [
          {
            'id':             'normal'
            'tooltip':        "Reuse territory from other times"
            'iconOwn':        iconPath + 'geom_reuse.svg'
            'callback':       'onClick'
          }
        ]
    # TODO: implement
    # @_buttonArea.addButton @_reuseGeomBtn, 'new-geom-add-group'

    @_importGeomBtn = new HG.Button @_hgInstance,
        'importGeom', ['tooltip-left'],
        [
          {
            'id':             'normal'
            'tooltip':        "import territory from file"
            'iconOwn':        iconPath + 'geom_import.svg'
            'callback':       'onClick'
          }
        ]
    # TODO: implement
    # @_buttonArea.addButton @_importGeomBtn, 'new-geom-add-group'

    @_buttonArea.addSpacer()

    @_editGeomBtn = new HG.Button @_hgInstance,
        'editGeom', ['tooltip-left'],
        [
          {
            'id':             'normal'
            'tooltip':        "edit territory on the map"
            'iconFA':         'edit'
            'callback':       'onClick'
          }
        ], @_makeHGButton leafletButtons[1]    # use existing leaflet "edit polygon" button
    @_buttonArea.addButton @_editGeomBtn, 'new-geom-edit-group'

    @_deleteGeomBtn = new HG.Button @_hgInstance,
        'deleteGeom', ['tooltip-left'],
        [
          {
            'id':             'normal'
            'tooltip':        "delete territory on the map"
            'iconFA':         'trash-o'
            'callback':       'onClick'
          }
        ], @_makeHGButton leafletButtons[2]  # use existing leaflet "delete polygon" button
    @_buttonArea.addButton @_deleteGeomBtn, 'new-geom-edit-group'

    @_buttonArea.addSpacer()

    @_submitGeomBtn = new HG.Button @_hgInstance,
        'submitGeom', ['tooltip-left'],
        [
          {
            'id':             'normal'
            'tooltip':        "Accept current selection"
            'iconFA':         'check'
            # 'iconOwn':        iconPath + 'polygon_rest.svg'
            'callback':       'onClick'
          }
        ]
    @_buttonArea.addButton @_submitGeomBtn, 'new-geom-finish-group'

    # init configuration: only add buttons are available
    if not restoreLayer
      @_editGeomBtn.disable()
      @_deleteGeomBtn.disable()
      @_submitGeomBtn.disable()

    # TODO: implement functionality for import and reuse buttons
    # until then -> disable forever
    @_importGeomBtn.disable()
    @_reuseGeomBtn.disable()


    ### INTERACTION ###

    # handle change events on polygons
    @_map.on 'draw:created', @_createPolygon
    @_map.on 'draw:deleted', @_deletePolygon


    # after first iteration, it is possible to select the leftover area and
    # select it as the leftover geometry
    # precondition: there is certainly only one unselected area in edit mode!
    if not @_firstStep

      @_initFeatureGroup = null

      # select leftover area: make this one the selected
      # => listen to select event of all areas
      @_hgInstance.areaController.onSelectArea @, (areaHandle) =>

        # clear feature group
        # CAUTION! potential usability flaw
        for layer in @_featureGroup
          # populate initial feature group to restore it later onClick
          @_initFeatureGroup.addLayer layer
          # empty feature
          @_featureGroup.removeLayer layer

        # make this one the selected "drawn" area
        @_featureGroup.addLayer areaHandle.multiPolygonLayer

        @_submitGeomBtn.enable()


      # deselect leftover area: restore layeers drawn before
      @_hgInstance.areaController.onDeselectArea @, (areaHandle) =>

        # make this one the selected "drawn" area
        @_featureGroup.removeLayer areaHandle.multiPolygonLayer

        # restore feature group
        # CAUTION! potential usability flaw
        for layer in @_initFeatureGroup
          # populate feature group
          @_featureGroup.addLayer layer
          # empty init feature group to populate on next use
          @_initFeatureGroup.removeLayer layer

        @_submitGeomBtn.disable() if @_featureGroup.length is 0



    # click OK => submit geometry
    @_submitGeomBtn.onClick @, () =>

      # immediately stop listening to on(De)SelectArea, to avoid weird behaviour
      if not @_firstStep
        @_hgInstance.areaController.removeListener 'onSelectArea', @
        @_hgInstance.areaController.removeListener 'onDeselectArea', @

      geometries = []
      geometries.push @_geometryReader.read layer for layer in @_featureGroup.getLayers()
      finalGeometry = @_geometryOperator.merge geometries
      finalGeometry.fixHoles()

      # merge all of them together
      # -> only works if they are (poly)polygons, not for polylines or points
      @notifyAll 'onSubmit', finalGeometry, @_featureGroup.getLayers()


  # ============================================================================
  destroy: () ->

    # remove interaction: detach event handlers from map
    @_map.off 'draw:created', @_createPolygon
    @_map.off 'draw:deleted', @_deletePolygon

    # remove interaction: stop listening to AreaController
    @_hgInstance.areaController.removeListener 'onSelectArea', @
    @_hgInstance.areaController.removeListener 'onDeselectArea', @

    # cleanup UI
    @_buttonArea.destroy()
    @_map.removeControl @_drawControl
    @_map.removeLayer @_featureGroup



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _createPolygon: (e) =>
    type = e.layerType
    layer = e.layer

    # put on the map
    @_featureGroup.addLayer layer

    # geometry can now be edited/deleted/submitted
    if @_featureGroup.getLayers().length > 0
      @_editGeomBtn.enable()
      @_deleteGeomBtn.enable()
      @_submitGeomBtn.enable()

  # ----------------------------------------------------------------------------
  _deletePolygon: (e) =>
    # geometry can not be edited/deleted/submitted anymore
    if @_featureGroup.getLayers().length is 0
      @_editGeomBtn.disable()
      @_deleteGeomBtn.disable()
      @_submitGeomBtn.disable()

  # ============================================================================
  _makeHGButton: (inButton) ->
    $(inButton).removeClass()
    $(inButton).detach()        # removes element from DOM to place it somewhere else
    $(inButton).addClass 'button'
    inButton




# OLD CODE: snapping tools

  #   ## 4. line: snapping options
  #   # snap to points?, snap to lines? and snap tolerance

  #   # horizontal wrapper containing all three options
  #   snapOptionWrapper = @_domElemCreator.create 'div', 'tt-snap-option-wrapper-out', null
  #   @_wrapper.appendChild snapOptionWrapper

  #   # wrapper for each option containing input box + description
  #   snapToPointsWrapper = @_domElemCreator.create 'div', null, ['tt-snap-option-wrapper-in']
  #   snapOptionWrapper.appendChild snapToPointsWrapper
  #   snapToLinesWrapper = @_domElemCreator.create 'div', null, ['tt-snap-option-wrapper-in']
  #   snapOptionWrapper.appendChild snapToLinesWrapper
  #   snapToleranceWrapper = @_domElemCreator.create 'div', null, ['tt-snap-option-wrapper-in']
  #   snapOptionWrapper.appendChild snapToleranceWrapper

  #   # snap to points
  #   snapToPointsSwitch = new HG.Switch @_hgInstance, 'snapToPoints', ['tt-snap-option-switch']
  #   snapToPointsWrapper.appendChild snapToPointsSwitch
  #   snapToPointsText = @_domElemCreator.create 'div', null, ['tt-snap-option-text']
  #   $(snapToPointsText).html "snap to <br/>points"
  #   snapToPointsWrapper.appendChild snapToPointsText

  #   # snap to lines
  #   snapToLinesSwitch = new HG.Switch @_hgInstance, 'snapToLines', ['tt-snap-option-switch']
  #   snapToLinesWrapper.appendChild snapToLinesSwitch
  #   snapToLinesText = @_domElemCreator.create 'div', null, ['tt-snap-option-text']
  #   $(snapToLinesText).html "snap to <br/>lines"
  #   snapToLinesWrapper.appendChild snapToLinesText

  #   # snap tolerance
  #   snapToleranceInput = new HG.NumberInput @_hgInstance, 'snapTolerance', ['tt-snap-option-input']
  #   snapToleranceInput.getDOMElement().setAttribute 'value', 5.0
  #   snapToleranceInput.getDOMElement().setAttribute 'maxlength', 3
  #   snapToleranceInput.getDOMElement().setAttribute 'step', 0.1
  #   snapToleranceInput.getDOMElement().setAttribute 'min', 0.0
  #   snapToleranceInput.getDOMElement().setAttribute 'max', 10.0
  #   snapToleranceWrapper.appendChild snapToleranceInput
  #   snapToleranceText = @_domElemCreator.create 'div', null, ['tt-snap-option-text']
  #   $(snapToleranceText).html "snap <br/>tolerance"
  #   snapToleranceWrapper.appendChild snapToleranceText