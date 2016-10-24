window.HG ?= {}

class HG.MultimediaController

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->
    @_multimedia = {}
    @_multimediaLoaded = false
    @_onMultimediaLoadedCallbacks = []

    defaultConfig =
      dsvPaths: []
      rootDirs: []
      delimiter: "|"
      ignoredLines: [] # line indices starting at 1
      indexMappings: [
        id          : 0
        type        : 2
        description : 3
        link        : 1
        author      : 4
        source      : 5
        crop        : 6
      ]

    @_config = $.extend {}, defaultConfig, config

    @loadMultimediaFromDSV()

  # ============================================================================
  hgInit: (@_hgInstance) ->
    @_hgInstance.multimediaController = @

  # ============================================================================
  onMultimediaLoaded: (callbackFunc) ->
    if callbackFunc and typeof(callbackFunc) == "function"
      if @_multimediaLoaded
        callbackFunc()
      else
        @_onMultimediaLoadedCallbacks.push callbackFunc

  getMultimediaById: (id) ->
    if @_multimedia.hasOwnProperty id
      return @_multimedia[id]

    console.error "A muldimedia object with the id \"#{id}\" does not exist!"
    return undefined

  ############################### INIT FUNCTIONS ###############################

  # ============================================================================
  loadMultimediaFromDSV: (config) ->

    if @_config.dsvPaths?
      parse_config =
        delimiter: @_config.delimiter
        header: false

      pathIndex = 0
      for dsvPath in @_config.dsvPaths
        $.get dsvPath,
          (data) =>
            parse_result = $.parse data, parse_config
            for result, i in parse_result.results
              unless i+1 in @_config.ignoredLines
                mm = @_createMultiMedia(
                  result[@_config.indexMappings[pathIndex].description],
                  result[@_config.indexMappings[pathIndex].link],
                  result[@_config.indexMappings[pathIndex].source],
                  result[@_config.indexMappings[pathIndex].crop]?.toUpperCase() is "TRUE",
                  result[@_config.indexMappings[pathIndex].type].toUpperCase(),
                  pathIndex
                )

                @_multimedia[result[@_config.indexMappings[pathIndex].id]] = mm

            if pathIndex == @_config.dsvPaths.length - 1
              @_multimediaLoaded = true
              for callback in @_onMultimediaLoadedCallbacks
                callback()
              @_onMultimediaLoadedCallbacks = []

            else pathIndex++

##############################################################################
#                            PRIVATE INTERFACE                               #
##############################################################################

# ============================================================================
  _createMultiMedia: (description, link, source, crop, type, pathIndex) ->

    mm =
      "description": description
      "link": @_config.rootDirs[pathIndex] + "/" + link
      "thumbnail": @_config.rootDirs[pathIndex] + "/" + link
      "video": link
      "source": source
      "crop": crop
      "type": type

    # hack: if link is an image or video on the web
    # use the absolute path do not set local root directory prefix
    if type is "WEBIMAGE"
      mm.link = link

    if type is "VIDEO"
      mm.video = link

    mm

  #   linkData = link.split(".")
  #   if linkData[linkData.length-1] in VIDEO_CRITERIA
  #     mm.type = 1
  #     # mm.link += "?iframe=true"
  #     # mm.thumbnail = "data/video.png"

  #   if link.indexOf('youtube') > -1
  #     mm.type = 1
  #     mm.link = link
  #     # mm.thumbnail = "data/video.png"

  #   mm

  # VIDEO_CRITERIA = ['flv', 'ogv', 'mp4', 'ogg']
