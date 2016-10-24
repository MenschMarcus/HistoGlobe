window.HG ?= {}

class HG.AreasOnHistoGraph

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

  # ============================================================================
  hgInit: (@_hgInstance) ->

    # add areasOnMap to HG instance
    @_hgInstance.areasOnHistoGraph = @

    # error handling
    if not @_hgInstance.areaController
      console.error "Unable to show areas on HistoGraph: AreaController module not detected in HistoGlobe instance!"

    # init variables
    @_canvas = @_hgInstance.histoGraph.getCanvas()
    @_selectedAreas = []

    # event handling
    @_hgInstance.onAllModulesLoaded @, () =>

      # @_hgInstance.areaController.onSelect @, (area) =>
      #   @_selectedAreas.push area
      #   @_hgInstance.histoGraph.updateHeight 1

      # @_hgInstance.areaController.onDeselect @, (area) =>
      #   idx = @_selectedAreas.indexOf area
      #   @_selectedAreas.splice idx, 1
      #   @_hgInstance.histoGraph.updateHeight -1

      # @_hgInstance.areaController.onToggleSelect @, (oldArea, newArea) =>
      #   idx = @_selectedAreas.indexOf oldArea
      #   @_selectedAreas[idx] = newArea
      #   # do not update height of HistoGraph
      #   # => call immediately
      #   @_updateHistory()

      # @_hgInstance.histoGraph.onHeightChanged @, () =>
      #   @_updateHistory()



  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _updateHistory: () ->

    areaData = []
    hiventData = []

    for area, idx in @_selectedAreas

      areaData.push {
        'shortName':  area.getShortName()
        'formalName': area.getFormalName()
        'startPos':   @_hgInstance.timeline.getDatePos area.getStartDate()
        'endPos':     @_hgInstance.timeline.getDatePos area.getEndDate()
        'heightPos':  @_hgInstance.histoGraph.getHeight() / (@_selectedAreas.length+1) * (idx+1)
      }

      startHivent = area.getStartHivent().getHivent()
      hiventData.push {
        'hiventName': startHivent.name
        'hiventPos':  @_hgInstance.timeline.getDatePos startHivent.date
        'heightPos':  @_hgInstance.histoGraph.getHeight() / (@_selectedAreas.length+1) * (idx+1)
      }

      # end hivent (if exists)
      if area.getEndHivent()
        endHivent = area.getEndHivent().getHivent()
        hiventData.push {
          'hiventName': endHivent.name
          'hiventPos':  @_hgInstance.timeline.getDatePos endHivent.date
          'heightPos':  @_hgInstance.histoGraph.getHeight() / (@_selectedAreas.length+1) * (idx+1)
        }

    # visualize!
    @_initArea areaData
    @_initHivents hiventData

  # ============================================================================
  _showOnGraph: (area) ->

    # a line and a text (label for the line) for each area
    if not @_initHistory
      @_initLines areaData
      @_initHistory = yes
    else
      @_updateLines areaData

  # ============================================================================
  _initArea: (areaData) ->
    # for duration of area
    @_canvas.selectAll 'line.graph-area'
      .data areaData
      .enter()
      .append 'line'
      .classed 'graph-area', true
      .attr 'x1', (currArea) -> currArea.startPos
      .attr 'x2', (currArea) -> currArea.endPos
      .attr 'y1', (currArea) -> currArea.heightPos
      .attr 'y2', (currArea) -> currArea.heightPos
      .on 'mouseover', () -> d3.select(@).style 'stroke', HGConfig.color_highlight.val
      .on 'mouseout', ()  -> d3.select(@).style 'stroke', HGConfig.color_white.val
      .on 'click', ()     -> d3.select(@).style 'stroke', HGConfig.color_active.val

    # for short name
    @_canvas.selectAll 'text.graph-area-short-name'
      .data areaData
      .enter()
      .append 'text'
      .classed 'graph-area-short-name', true
      .attr 'x', (currArea) -> currArea.startPos  + 80
      .attr 'y', (currArea) -> currArea.heightPos - 8
      .text (areaData) -> areaData.shortName

    # for formal name
    @_canvas.selectAll 'text.graph-area-formal-name'
      .data areaData
      .enter()
      .append 'text'
      .classed 'graph-area-formal-name', true
      .attr 'x', (currArea) -> currArea.startPos  + 80
      .attr 'y', (currArea) -> currArea.heightPos + 17
      .text      (areaData) -> areaData.formalName

  # ----------------------------------------------------------------------------
  _initHivents: (hiventData) ->
    # for hivent date
    @_canvas.selectAll 'circle.graph-hivent'
      .data hiventData
      .enter()
      .append 'circle'
      .classed 'graph-hivent', true
      .attr 'r', HGConfig.histograph_hivent_circle_radius.val
      .attr 'cx', (currHivent) -> currHivent.hiventPos
      .attr 'cy', (currHivent) -> currHivent.heightPos
      .on 'mouseover', () -> d3.select(@).style 'fill', HGConfig.color_highlight.val
      .on 'mouseout', ()  -> d3.select(@).style 'fill', HGConfig.color_white.val
      .on 'click', ()     -> d3.select(@).style 'fill', HGConfig.color_active.val

    # for hivent name
    names = @_canvas.selectAll 'text.graph-hivent-name'
      .data hiventData
      .enter()
      .append 'text'
      .classed 'graph-hivent-name', true
      # TODO: horizontal centering
      .attr 'x', (currHivent) -> currHivent.hiventPos
      .attr 'y', (currHivent) -> currHivent.heightPos + HGConfig.histograph_hivent_circle_radius.val + 13
      .text      (currHivent) -> currHivent.hiventName

    # update hivent name position
    for name in names
      newPos = $(name).attr('x') - $(name).width()/2
      $(name).attr 'x', newPos


  # ============================================================================

  _updateLines: (d) ->
    @_canvas.selectAll 'line'

  _updateLabels: (d) ->
    @_canvas.selectAll 'text'
      .data d
      .transition()
      .duration 200
      .text (d) -> d.name