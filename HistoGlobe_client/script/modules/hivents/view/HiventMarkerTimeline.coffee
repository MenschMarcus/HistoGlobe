
#include Extendable.coffee
#include HiventMarker.coffee

window.HG ?= {}

class HG.HiventMarkerTimeline extends HG.HiventMarker

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (hgInstance, timeline, hiventHandle, parent, posX, rowPosition=0, id) ->
    HG.HiventMarker.call @, hiventHandle, parent

    @_hgInstance = hgInstance
    @_timeline = timeline
    @_id = id

    time = hiventHandle.getHivent().date.getTime()

    yRow=
      0: HGConfig.timeline_row0_position.val + 25    # main topic
      0.5: HGConfig.timeline_row0_position.val + 55  # subtopic
      1: HGConfig.timeline_row1_position.val + 25    # main topic
      1.5: HGConfig.timeline_row1_position.val + 55  # subtopic

      # TODO: get the hack out of here !!!
      # 0: HGConfig.timeline_row0_position.val + HGConfig.hivent_marker_timeline_main_topic_offset_y.val    # main topic
      # 0.5: HGConfig.timeline_row0_position.val + HGConfig.hivent_marker_timeline_sub_topic_offset_y.val  # subtopic
      # 1: HGConfig.timeline_row1_position.val + HGConfig.hivent_marker_timeline_main_topic_offset_y.val    # main topic
      # 1.5: HGConfig.timeline_row1_position.val + HGConfig.hivent_marker_timeline_sub_topic_offset_y.val  # subtopic

    Y_OFFSETS[time] ?= 0
    @_yOffset = Y_OFFSETS[time]
    @_position =
      x: posX,
      y: yRow[rowPosition + ""]

    @rowPosition = rowPosition

    Y_OFFSETS[time] += 1

    @_classDefault     = "hivent_marker_timeline_#{hiventHandle.getHivent().category}_default"
    @_classHighlighted = "hivent_marker_timeline_#{hiventHandle.getHivent().category}_highlighted"

    @_div = document.createElement "div"
    @_div.setAttribute "class", @_classDefault
    @_div.setAttribute "width", 50+"px";
    @_div.style.left = @_position.x + "px"
    @_div.style.bottom = @_position.y + "px"  # attention position from bottom!
    @_div.style.display = "none" if !@_timeline.topicsloaded

    # new
    '''if hiventHandle.getHivent().date.getTime() isnt hiventHandle.getHivent().endDate.getTime()
      xDiff = @_timeline.dateToPosition(hiventHandle.getHivent().endDate) - @_timeline.dateToPosition(hiventHandle.getHivent().date)
      @_div.style.width = xDiff + "px"
      @_div.style.background = "rgba(255, 0, 0, 1)"'''

    parent.appendChild @_div

    @_div.onmouseover = (e) =>
      @getHiventHandle().markAll @_position

    @_div.onmouseout = (e) =>
      if !@getHiventHandle()._activated
        @getHiventHandle().unUnMarkAll @_position

    @_div.onclick = (e) =>
      e.preventDefault()
      @_hgInstance.hiventInfoAtTag?.setOption 'event', hiventHandle.getHivent().id

    @getHiventHandle().onMark @, (mousePos) =>
      @_div.setAttribute "class", @_classHighlighted

    @getHiventHandle().onUnMark @, (mousePos) =>
      @_div.setAttribute "class", @_classDefault

    @getHiventHandle().onLink @, (mousePos) =>
      @_div.setAttribute "class", @_classHighlighted

    @getHiventHandle().onUnLink @, (mousePos) =>
      @_div.setAttribute "class", @_classDefault

    @getHiventHandle().onActive @, (mousePos) =>
      @_div.setAttribute "class", @_classHighlighted

    @getHiventHandle().onInActive @, (mousePos) =>
      @_div.setAttribute "class", @_classDefault

    @getHiventHandle().onDestruction @, @_destroy
    @getHiventHandle().onInvisible @, @_destroy

    @_timeline.OnTopicsLoaded @, () =>
      rowPosition = @_timeline.getRowFromTopicId(@_id)
      @_position.y = yRow[rowPosition + ""]
      @_div.style.bottom = @_position.y + "px"
      $(@_div).fadeIn()


    # HACK: create labels
    '''hiventName = hiventHandle.getHivent().name
    labelClass = "hivent_marker_timeline_label"
    width = 500
    rotation = -30
    labelX = -20
    labelY = -140

    @_labelDiv = document.createElement "div"
    @_labelDiv.innerHTML = hiventName
    @_labelDiv.setAttribute "class", labelClass
    @_labelDiv.style.width = width + "px"
    @_labelDiv.style.left = labelX + "px"
    @_labelDiv.style.top = labelY + "px"
    @_labelDiv.style.webkitTransform = 'rotate('+rotation+'deg)';
    @_labelDiv.style.mozTransform    = 'rotate('+rotation+'deg)';
    @_labelDiv.style.msTransform     = 'rotate('+rotation+'deg)';
    @_labelDiv.style.oTransform      = 'rotate('+rotation+'deg)';
    @_labelDiv.style.transform       = 'rotate('+rotation+'deg)';

    @_div.appendChild @_labelDiv'''


  # ============================================================================
  categoryChanged: (c) ->

  # ============================================================================
  getPosition: ->
    return @_position

  # ============================================================================
  setPosition: (posX) =>
    @_position.x = posX
    @_div.style.left = @_position.x + "px"

  # ============================================================================
  getDiv: ->
    return @_div


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _setDivPos: (pos) ->
    @_div.style.left = pos.x + "px"
    @_div.style.top = pos.y + "px"

  # ============================================================================
  _destroy: =>
    # @notifyAll "onMarkerDestruction"

    Y_OFFSETS[@getHiventHandle().getHivent().date.getTime()] -= 1
    @getHiventHandle().unMarkAll()
    @_div.parentNode.removeChild @_div

    @_hiventHandle.removeListener "onMark", @
    @_hiventHandle.removeListener "onUnMark", @
    @_hiventHandle.removeListener "onLink", @
    @_hiventHandle.removeListener "onUnLink", @
    @_hiventHandle.removeListener "onInvisible", @
    @_hiventHandle.removeListener "onDestruction", @

    super()

    delete @
    return

  ##############################################################################
  #                             STATIC MEMBERS                                 #
  ##############################################################################

  Y_OFFSETS = {}
