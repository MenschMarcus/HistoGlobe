window.HG ?= {}

# ==============================================================================
# Class for displaying popovers with arbitrary content.
# ==============================================================================
class HG.Popover

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback "onResize"
    @addCallback "onClose"

    defaultConfig =
      hgInstance: undefined
      hiventHandle: undefined
      placement: "top"
      content: undefined
      contentHTML: ""
      title: ""
      container: "body"
      showArrow: false
      fullscreen: false

    @_config = $.extend {}, defaultConfig, config

    @_hgInstance = @_config.hgInstance
    @_hiventHandle = @_config.hiventHandle
    @_multimediaController = @_config.hgInstance.multimediaController
    @_multimedia = @_hiventHandle.getHivent().multimedia
    # @_mode = @_hgInstance.abTest?.config.hiventMarkerMode
    @_mode = 'A'  # hardcode, bitch!!!

    # ============================================================================
    @_screenWidth = @_config.hgInstance.getSpatialCanvasSize().x
    @_screenHeight = @_config.hgInstance.getSpatialCanvasSize().y

    @_width = HGConfig.popover_body_default_width.val
    @_height = HGConfig.popover_body_default_height.val

    @_map_size = @_config.hgInstance.getSpatialCanvasSize()

    @_widthFSBox = @_map_size.x - HGConfig.hiventlist_offset.val #- FULLSCREEN_BOX_LEFT_OFFSET
    @_heightFSBox = 0.82 * @_map_size.y

    @_mainDiv = document.createElement 'div'
    @_mainDiv.className = "guiPopover"

    @_mainDiv.style.position = "absolute"
    @_mainDiv.style.top = "#{HGConfig.window_to_anchor_offset_y.val}"
    @_mainDiv.style.visibility = "hidden"

    if @_config.fullscreen
      $(@_mainDiv).addClass("fullscreen")
    else
      @_mainDiv.style.left = "#{HGConfig.window_to_anchor_offset_x.val}"

    # YouTube div slide ===============================================
    @_videoDiv = document.createElement 'div'
    @_videoDiv.className = "guiPopoverVideo"

    @_videoDivBig = document.createElement 'div'
    @_videoDivBig.className = "guiPopoverVideoBig"

    # Big HiventBox ===================================================
    @_bodyDivBig = document.createElement 'div'
    @_bodyDivBig.className = "guiPopoverBodyBig"
    @_bodyDivBig.style.width = "#{0.6 * @_widthFSBox}px"
    @_bodyDivBig.style.height = "#{@_heightFSBox}px"

    contentBig = document.createElement 'div'
    contentBig.className = "guiPopoverContentBig"
    contentBig.style.width = "#{0.4 * @_widthFSBox}px"
    contentBig.style.height = "#{@_heightFSBox}px"

    sourceBig = document.createElement "span"
    sourceBig.className = "source-big"
    #sourceBig.innerHTML = 'Quelle: ' + @_imgSource

    linkListBig = document.createElement 'div'
    linkListBig.className = "info-links-big"

    linkListBig.appendChild sourceBig
    @_bodyDivBig.appendChild linkListBig

    # generate content for big HiventBox ==============================
    bodyBig = document.createElement 'div'
    bodyBig.className = "hivent-body-big"

    titleDivBig = document.createElement "h4"
    titleDivBig.className = "guiPopoverTitleBig"
    titleDivBig.innerHTML = @_config.hiventHandle.getHivent().name
    bodyBig.appendChild titleDivBig

    textBig = document.createElement 'div'
    textBig.className = "hivent-content-big"

    descriptionBig = @_config.hiventHandle.getHivent().description
    textBig.innerHTML = descriptionBig

    bodyBig.appendChild textBig
    contentBig.appendChild bodyBig

    locationStringBig = @_config.hiventHandle.getHivent().locationName[0] + ', '

    dateBig = document.createElement "span"
    dateBig.innerHTML = ' - ' + locationStringBig + @_config.hiventHandle.getHivent().displayDate #+ ' '
    textBig.appendChild dateBig

    gotoDateBig = document.createElement "i"
    gotoDateBig.className = "fa fa-clock-o"
    $(gotoDateBig).tooltip {title: "Springe zum Ereignisdatum", placement: "right", container:"#histoglobe"}
    gotoDateBig.addEventListener 'mouseup', () =>
    @_hgInstance.timeline.moveToDate @_config.hiventHandle.getHivent().date, 0.5
    dateBig.appendChild gotoDateBig

    # =================================================================
    @_bodyDiv = document.createElement 'div'
    @_bodyDiv.className = "guiPopoverBodyV1"

    source = document.createElement "span"
    source.className = "source"
    #source.innerHTML = 'Quelle: ' + @_imgSource

    linkList = document.createElement 'div'
    linkList.className = "info-links"

    linkList.appendChild source
    @_bodyDiv.appendChild linkList

    closeDiv = document.createElement 'div'
    closeDiv.className = "close-button"

    # closeDiv = document.createElement "span"
    # closeDiv.className = "close-button"
    # closeDiv.innerHTML = "×"
    # closeDiv.style.color = "#D5C900"

    @_expandBox = document.createElement 'div'
    @_expandBox.className = "expand2FS"
    @_expandBox.innerHTML = '<i class="fa fa-expand"></i>'
    # $(expandBox).tooltip {title: "Box vergrößern", placement: "left", container:"#histoglobe"}

    @_compressBox = document.createElement 'div'
    @_compressBox.className = "compress2Normal"
    @_compressBox.innerHTML = '<i class="fa fa-compress"></i>'
    # $(compressBox).tooltip {title: "Zurück zur normalen Ansicht", placement: "left", container:"#histoglobe"}

    @_switch2Video = document.createElement 'div'
    @_switch2Video.className = "go2Video"
    @_switch2Video.innerHTML = '<i class="fa fa-youtube-play"></i>'
    # $(expandBox).tooltip {title: "Zum Video", placement: "left", container:"#histoglobe"}

    @_switch2Normal = document.createElement 'div'
    @_switch2Normal.className = "back2Normal"
    @_switch2Normal.innerHTML = '<i class="fa fa-picture-o"></i>'
    # $(compressBox).tooltip {title: "Zurück zur normalen Ansicht", placement: "left", container:"#histoglobe"}

    # ============================================================================

    if @_config.fullscreen
      $(@_bodyDiv).addClass("fullscreen")

    if @_config.content? or @_config.contentHTML isnt ""

      content = document.createElement 'div'
      content.className = "guiPopoverContent"

      if @_config.content?
        content.appendChild @_config.content
      else
        content.innerHTML = @_config.contentHTML

      @_bodyDiv.appendChild content
      if content.offsetHeight < @_height
        @_bodyDiv.setAttribute "height", "#{@_height}px"

      if content.offsetWidth > @_width
        @_width = Math.min content.offsetWidth, HGConfig.popover_body_max_width.val
        @_height = Math.min @_height, HGConfig.popover_body_max_height.val

    @_mainDiv.appendChild closeDiv
    @_mainDiv.appendChild @_bodyDiv

    #@_mainDiv.appendChild @_switch2Video
    #@_mainDiv.appendChild @_switch2Normal

    @_bodyDivBig.appendChild contentBig

    # remove gradient if description is empty
    if descriptionBig is ""
      @_bodyDivBig.style.display = "none"
      @_bodyDiv.style.display = "none"

    @_parentDiv = $(@_config.container)[0]
    @_parentDiv.appendChild @_mainDiv

    @_centerPos =
      x: 0
      y: 0

    @_updateCenterPos()

    if @_config.fullscreen
      size = @_config.hgInstance.getSpatialCanvasSize()
      @_onContainerSizeChange size

      $(window).on 'resize', () =>
        @updateSize() if @_mainDiv.style.visibility is "visible"

  # ============================================================================

    $(".guiPopover").draggable()

    $(@_mainDiv).fadeIn(1000)

    @_mainDiv.style.height = "250px"  # #{@_height}"

    @_mainDiv.style.background = "#fff"
    @_bodyDiv.style.color = "#000"

  # ============================================================================
  # Create multimedia content

    if @_multimedia != "" and @_multimediaController?
      mmids = @_multimedia.split ","

      @_multimediaController.onMultimediaLoaded () =>

          for id in mmids
            id = id.trim() # removes whitespaces
            mm = @_multimediaController.getMultimediaById id

            if mm?

              if mm.type is "WEBIMAGE"
              # set background image and attributes
                link = mm.link
                imgSource = mm.source
                textSource = @_config.hiventHandle.getHivent().link
                wikiLink = '<a href="' + textSource + '" target="_blank">Link zum Artikel</a>'

                @_mainDiv.style.height = "350px"
                @_mainDiv.style.backgroundImage = "url( #{link} )"
                @_mainDiv.style.backgroundSize = "cover"
                @_mainDiv.style.backgroundRepeat = "no-repeat"
                @_mainDiv.style.backgroundPosition = "center center"
                @_bodyDiv.className = "guiPopoverBodyV2"
                @_bodyDiv.style.height = "250px"
                @_bodyDiv.style.color = "#fff"

                source.innerHTML = 'Quelle: ' + imgSource + ' -' + wikiLink
                sourceBig.innerHTML = 'Quelle: ' + imgSource + ' -' + wikiLink

                @_mainDiv.appendChild @_expandBox
                @_bodyDivBig.style.color = "#fff"

              if mm.type is "VIDEO"
                # display video icon with funtionality
                @_mainDiv.appendChild @_switch2Video
                videoLink = mm.video # set video

                @_videoDiv.innerHTML = "<iframe width='100%' height='#{@_height}' src='#{videoLink}' allowfullscreen frameborder='0'> </iframe>"
                @_videoDivBig.innerHTML = "<iframe width='100%' height='#{@_heightFSBox}' src='#{videoLink}' allowfullscreen frameborder='0'> </iframe>"

  # ============================================================================
    # expand button
    @_expandBox.addEventListener 'mouseup', () =>
      @expand() # expand box to big version
      @_mainDiv.replaceChild @_compressBox, @_expandBox

    # compress button
    @_compressBox.addEventListener 'mouseup', () =>
      @compress() # switch back to small box version
      @_mainDiv.replaceChild @_expandBox, @_compressBox

    # video button - removes text, background image and shows video
    @_switch2Video.addEventListener 'mouseup', () =>
      # to do: für große Box anpassen
      if document.contains(@_bodyDivBig)
        @_mainDiv.removeChild @_bodyDivBig
        @_mainDiv.appendChild @_videoDivBig
        @_mainDiv.style.pointerEvents = "none"
        @_videoDivBig.style.pointerEvents = "all"

      else
        @_mainDiv.removeChild @_bodyDiv
        @_mainDiv.appendChild @_videoDiv

      if document.contains(@_expandBox)
        @_mainDiv.removeChild @_expandBox

      if document.contains(@_compressBox)
        @_mainDiv.removeChild @_compressBox

      @_mainDiv.removeChild @_switch2Video
      @_mainDiv.appendChild @_switch2Normal

    # image button - removes video and switches back to normal box
    @_switch2Normal.addEventListener 'mouseup', () =>
      if document.contains(@_videoDivBig) # if big Hivent-Box is active
        @_mainDiv.removeChild @_videoDivBig
        @_mainDiv.appendChild @_bodyDivBig
        @_mainDiv.appendChild @_compressBox

      else
        @_mainDiv.removeChild @_videoDiv
        @_mainDiv.appendChild @_bodyDiv
        @_mainDiv.appendChild @_expandBox

      @_mainDiv.removeChild @_switch2Normal
      @_mainDiv.appendChild @_switch2Video
      @_mainDiv.style.pointerEvents = "all"

    closeDiv.addEventListener 'mouseup', () =>
      @hide()
      @close()
      @notifyAll "onClose"
    , false

  # ============================================================================
  expand: () ->
    @_mainDiv.className = "guiPopoverBig"
    @_mainDiv.style.pointerEvents = "none"
    @_mainDiv.style.width = "#{@_widthFSBox}px"
    @_mainDiv.style.height = "#{@_heightFSBox}px"
    @_mainDiv.style.top = "#{HGConfig.fullscreen_box_top_offset.val}"
    @_mainDiv.style.left = "#{HGConfig.fullscreen_box_left_offset.val}"
    $(@_mainDiv).unbind('drag')

    @_mainDiv.replaceChild @_bodyDivBig, @_bodyDiv

  # ============================================================================
  compress: () ->
    @_mainDiv.className = "guiPopover"
    @_mainDiv.style.pointerEvents = "all"
    @_mainDiv.style.width = "#{@_width}px"
    @_mainDiv.style.height = "#{@_height}px"

    $(@_mainDiv).bind('drag')

    @_mainDiv.replaceChild @_bodyDiv, @_bodyDivBig

    canvasOffset = $(@_parentDiv).offset()
    $(@_mainDiv).offset
      left: @_position.x + canvasOffset.left +
            @_placement.x * (HGConfig.hivent_marker_2D_width.val / 2) +
            @_placement.x * ((@_width - @_width * @_placement.x) / 2) -
            Math.abs(@_placement.y) *  @_width / 2

      top:  @_position.y + canvasOffset.top - WINDOW_TO_ANCHOR_OFFSET_Y +
            @_placement.y * (HGConfig.hivent_marker_2D_height.val / 2) +
            @_placement.y * ((@_mainDiv.offsetHeight - @_mainDiv.offsetHeight * @_placement.y) / 2) -
            Math.abs(@_placement.x) * @_mainDiv.offsetHeight / 2

  # ============================================================================
  close: () ->
    if document.contains(@_bodyDivBig)
      @_mainDiv.removeChild @_bodyDivBig
      @_mainDiv.appendChild @_bodyDiv
      @_mainDiv.replaceChild @_expandBox, @_compressBox

    if document.contains(@_videoDiv)
      @_mainDiv.removeChild @_videoDiv
      @_mainDiv.appendChild @_bodyDiv

      @_mainDiv.removeChild @_switch2Normal
      @_mainDiv.appendChild @_switch2Video
      @_mainDiv.appendChild @_expandBox

    if document.contains(@_videoDivBig)
      @_mainDiv.removeChild @_videoDivBig
      @_mainDiv.appendChild @_bodyDiv

      @_mainDiv.removeChild @_switch2Normal
      @_mainDiv.appendChild @_switch2Video
      @_mainDiv.appendChild @_expandBox

    @_mainDiv.className = "guiPopover"
    @_mainDiv.style.pointerEvents = "all"
    @_mainDiv.style.width = "#{@_width}px"
    @_mainDiv.style.height = "#{@_height}px"




  # ============================================================================
  toggle: (position) =>
    if @_mainDiv.style.visibility is "visible"
      @hide position
    else
      @show position

  # ============================================================================
  show: (position) =>
    if @_config.fullscreen
      @updateSize()
    @_mainDiv.style.visibility = "visible"
    @_mainDiv.style.opacity = 1.0

    @updatePosition position

  # ============================================================================
  hide: =>
    # hideInfo = =>
      # @_mainDiv.style.visibility = "hidden"

    # window.setTimeout hideInfo, 200
    @_mainDiv.style.visibility = "hidden"
    @_mainDiv.style.opacity = 0.0
    @_placement = undefined

    if document.contains(@_bodyDivBig)
      @_mainDiv.removeChild @_bodyDivBig
      @_mainDiv.appendChild @_bodyDiv
      @_mainDiv.className = "guiPopover"
      @_mainDiv.style.width = "#{@_width}px"
      @_mainDiv.style.height = "#{@_height}px"
      @_mainDiv.replaceChild @_expandBox, @_compressBox


  # ============================================================================
  updatePosition: (@_position) ->
    @_updateCenterPos()
    @_updateWindowPos()

  # ============================================================================
  updateSize:() ->
    size = @_config.hgInstance.getSpatialCanvasSize()
    @_onContainerSizeChange size

  # ============================================================================
  destroy: () ->
    @_mainDiv.parentNode.removeChild @_mainDiv

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _onContainerSizeChange:(size) =>
    @_mainDiv.style.width = size.x-150 + "px"
    @_bodyDiv.style.maxHeight = size.y-200 + "px"

    @notifyAll "onResize"

  # ============================================================================
  _onContainerWidthChange:(width) =>
    @_mainDiv.style.width = width-150 + "px"

    @notifyAll "onResize"

  # ============================================================================
  _updateWindowPos: ->

    canvasOffset = $(@_parentDiv).offset()

    unless @_placement?
      if @_config.placement is "top"
        @_placement = {x:0, y:-1}

      else
        @_placement = {x:0, y:-1}
        console.warn "Invalid popover placement: ", @_config.placement

    if @_mode is "A"
      # default behavior
      $(@_mainDiv).offset
        left: @_position.x + canvasOffset.left +
              @_placement.x * (HGConfig.hivent_marker_2D_width.val / 2) +
              @_placement.x * ((@_width - @_width * @_placement.x) / 2) -
              Math.abs(@_placement.y) *  @_width / 2

        top:  @_position.y + canvasOffset.top - WINDOW_TO_ANCHOR_OFFSET_Y +
              @_placement.y * (HGConfig.hivent_marker_2D_height.val / 2) +
              @_placement.y * ((@_mainDiv.offsetHeight - @_mainDiv.offsetHeight * @_placement.y) / 2) -
              Math.abs(@_placement.x) * @_mainDiv.offsetHeight / 2

    if @_mode is "B"
    # marker: center ~ 2/3 horizontally and ~ 2/3 vertically; hivent box above marker
      $(@_mainDiv).offset
        left: @_screenWidth / 2 - 0.74 * @_width
        top: @_screenHeight / 2 - 0.73 * @_height

    # unless @_config.fullscreen
    #   ...

    # else
    #   $(@_mainDiv).offset
    #     top:  5 + canvasOffset.top

  # ============================================================================
  _updateCenterPos: ->
    parentOffset = $(@_parentDiv).offset()
    @_centerPos =
      x:@_mainDiv.offsetLeft + @_mainDiv.offsetWidth/2 - parentOffset.left
      y:@_mainDiv.offsetTop  + @_mainDiv.offsetHeight/2 - parentOffset.top
