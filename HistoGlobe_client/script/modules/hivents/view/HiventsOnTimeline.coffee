window.HG ?= {}

class HG.HiventsOnTimeline

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

    defaultConfig =
      default_row_position: "0"
      marker_row_positions: []

    @_config = $.extend {}, defaultConfig, config

    @_hiventMarkers = []

    @_onMarkerAddedCallbacks = []
    @_markersNeedSorting = false
    @_positionsNeedUpdate = false
    @_markersLoaded = false

  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add to hg instance
    @_hgInstance.hiventsOnTimeline = @


    if @_hgInstance.categoryIconMapping
      for category in @_hgInstance.categoryIconMapping.getCategories()
        # position = @_config.default_position
        # for obj in @_config.marker_positions
        #   if obj.category == category
        #     position = obj.position
        icons = @_hgInstance.categoryIconMapping.getIcons(category)
        #iconsTimeLine = {default: "config/school/icons/marker_hivent-timeline.svg", highlighted: "config/school/icons/marker_hivent-timeline-active.svg"}
        #console.log icons
        #console.log iconsTimeLine
        for element of icons
          #console.log element
          HG.createCSSSelector ".hivent_marker_timeline_#{category}_#{element}",
          "width: #{HGConfig.hivent_marker_timeline_width.val}px !important;
           height: #{HGConfig.hivent_marker_timeline_height.val}px !important;
           cursor:pointer;
           z-index: 2;
           margin-top: 0px;
           margin-left: -#{HGConfig.hivent_marker_timeline_width.val/2}px;
           position: absolute !important;
           background-image: url(#{icons[element]}) !important;
           background-size: cover !important;"

    if @_hgInstance.hiventController
      @_hgInstance.hiventController.getHivents @, (handle) =>
        show = (self, oldState) =>
          if oldState is 0 # invisible
            hiventMarkerDate = self.getHivent().date
            #rowPosition = @_config.default_row_position

            # TODO: get topics from timeline and check hivent for mapping
            #       get row of topic and set Marker to it

            '''for obj in @_config.marker_row_positions
              if obj.category is self.getHivent().category
                rowPosition = obj.row_position
                break'''
            if self.getHivent().subTopic is ""
              rowPosition = @_hgInstance.timeline.getRowFromTopicId(self.getHivent().parentTopic)
              id = self.getHivent().parentTopic
              #console.log rowPosition + " and " + self.getHivent().parentTopic
            else
              rowPosition = @_hgInstance.timeline.getRowFromTopicId(self.getHivent().subTopic)
              id = self.getHivent().subTopic
              #console.log rowPosition + " and " + self.getHivent().subTopic
            marker = new HG.HiventMarkerTimeline @_hgInstance, @_hgInstance.timeline, self, @_hgInstance.timeline.getCanvas(), @_hgInstance.timeline.dateToPosition(hiventMarkerDate), rowPosition, id
            @_hiventMarkers.push marker
            marker.onDestruction @, ()=>
              index = $.inArray(marker, @_hiventMarkers)
              @_hiventMarkers.splice index, 1  if index >= 0
              @_positionsNeedUpdate = true

            @_markersLoaded = @_hgInstance.hiventController._hiventsLoaded
            @_sortMarkers()
            @_positionsNeedUpdate = true
            @_updateHiventMarkerPositions()
            callback marker for callback in @_onMarkerAddedCallbacks

        handle.onVisibleFuture @, show
        handle.onVisiblePast @, show

      @_hgInstance.timeController.onNowChanged @, @_updateHiventMarkerPositions
      #@_hgInstance.timeline.onIntervalChanged @, @_updateHiventMarkerPositions
      @_hgInstance.timeline.onZoom @, () =>
        @_positionsNeedUpdate = true

    else
      console.error "Unable to show hivents on Timeline: HiventController module not detected in HistoGlobe instance!"

    #new:
    # @_hgInstance.onAllModulesLoaded @, () =>
    #     @_hgInstance.timeController.onNowChanged @, @_updateHiventMarkerPositions
    #     @_hgInstance.timeline.onIntervalChanged @, @_updateHiventMarkerPositions


  # ============================================================================
  onMarkerAdded: (callbackFunc) ->
    if callbackFunc and typeof(callbackFunc) == "function"
      @_onMarkerAddedCallbacks.push callbackFunc

      if @_markersLoaded
        callbackFunc marker for marker in @_hiventMarkers

  # ============================================================================

  isInt: (n) ->
    return n % 1 is 0

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _updateHiventMarkerPositions: ->
    if @_positionsNeedUpdate
      @_positionsNeedUpdate = false
      minDistance = HGConfig.hivent_marker_timeline_min_distance.val
      previousMarkers = []

      currentZ = 2
      for marker, i in @_hiventMarkers
        marker.getDiv().style.zIndex = currentZ
        currentZ += 1
        hiventMarkerDate = marker.getHiventHandle().getHivent().date
        newPos = @_hgInstance.timeline.dateToPosition(hiventMarkerDate)
        previousMarker = @_hiventMarkers[i-1]

        if previousMarker?
          previousMarkers[previousMarker.rowPosition] = previousMarker
          if previousMarkers[marker.rowPosition]?
            unless hiventMarkerDate.getTime() is previousMarkers[marker.rowPosition].getHiventHandle().getHivent().date.getTime()
              if (newPos - minDistance) <= previousMarkers[marker.rowPosition].getPosition().x
                newPos = previousMarkers[marker.rowPosition].getPosition().x + minDistance

        marker.setPosition(newPos)


  # ============================================================================
  _sortMarkers: ->
    @_hiventMarkers.sort (a, b) =>
      hiventA = a.getHiventHandle()
      hiventB = b.getHiventHandle()
      if hiventA? and hiventB?
        unless hiventA.getHivent().date.getTime() is hiventB.getHivent().date.getTime()
            return hiventA.getHivent().date.getTime() - hiventB.getHivent().date.getTime()
          else
            if hiventA.getHivent().id > hiventB.getHivent().id
              return 1
            else if hiventA.getHivent().id < hiventB.getHivent().id
              return -1
      return 0


  ##############################################################################
  #                             STATIC MEMBERS                                 #
  ##############################################################################

