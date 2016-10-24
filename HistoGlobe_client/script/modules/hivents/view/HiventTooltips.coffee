window.HG ?= {}

class HG.HiventTooltips

  # TODO: merge into HiventMarker

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: () ->

  # ============================================================================
  hgInit: (hgInstance) ->
    @_hiventsOnTimeline = hgInstance.hiventsOnTimeline
    @_hiventsOnMap = hgInstance.hiventsOnMap
    @_hiventsOnGlobe = hgInstance.hiventsOnGlobe


    if @_hiventsOnTimeline
      @_hiventsOnTimeline.onMarkerAdded (marker) =>
        if marker.parentDiv
          @_addTimelineTooltip marker

    if @_hiventsOnMap
      @_hiventsOnMap.onMarkerAdded (marker) =>
        if marker.parentDiv
          @_addMapTooltip marker

    if @_hiventsOnGlobe
      @_hiventsOnGlobe.onMarkerAdded (marker) =>
        if marker.parentDiv
          @_addMapTooltip marker


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _addMapTooltip: (marker) =>
    hiventInfo = document.createElement("div")
    hiventInfo.class = "btn btn-default"
    hiventInfo.style.position = "absolute"
    hiventInfo.style.left = "0px"
    hiventInfo.style.top = "0px"
    hiventInfo.style.visibility = "hidden"
    hiventInfo.style.pointerEvents = "none"

    marker.parentDiv.appendChild hiventInfo

    handle = marker.getHiventHandle()
    hivent = handle.getHivent()
    $(hiventInfo).tooltip {title: "#{marker.locationName} - #{hivent.displayDate}<br />#{hivent.name}", html:true, placement: "top", container:"#histoglobe"}


    handle.onMark marker, @_showTooltip
    handle.onUnMark marker, @_hideTooltip
    handle.onActive marker, @_hideTooltip
    marker.onDestruction @, () =>
      hiventInfo.parentNode.removeChild hiventInfo

  # ============================================================================
  _addTimelineTooltip: (marker) =>
    hiventInfo = document.createElement("div")
    hiventInfo.class = "btn btn-default"
    hiventInfo.style.position = "absolute"
    hiventInfo.style.left = "0px"
    hiventInfo.style.bottom = "0px"
    hiventInfo.style.visibility = "hidden"
    hiventInfo.style.pointerEvents = "none"

    marker.parentDiv.appendChild hiventInfo

    handle = marker.getHiventHandle()
    hivent = handle.getHivent()
    $(hiventInfo).tooltip {title: "#{hivent.displayDate}<br />#{hivent.name}", html:true, placement: "top", container:"#histoglobe"}

    handle.onMark marker, @_showTooltip
    handle.onUnMark marker, @_hideTooltip
    handle.onActive marker, @_hideTooltip
    marker.onDestruction @, () =>
      hiventInfo.parentNode.removeChild hiventInfo

  # ============================================================================
  _showTooltip = (displayPosition) =>
    hiventInfo.style.left = displayPosition.x + "px"
    hiventInfo.style.top = displayPosition.y + 5 - HGConfig.hivent_marker_2D_height.val/2 + "px"
    #$(hiventInfo).tooltip "show"

  _hideTooltip = (displayPosition) =>
    $(hiventInfo).tooltip "hide"

  ##############################################################################
  #                             STATIC MEMBERS                                 #
  ##############################################################################

