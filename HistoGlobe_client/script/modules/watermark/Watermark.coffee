window.HG ?= {}

class HG.Watermark

  # TODO: create "real" watermark (not draggable and selectable background image)

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (config) ->

    defaultConfig =
      id:           ''
      top:          null
      right:        null
      bottom:       null
      left:         null
      imageNormal:  null
      imageLight:   null
      text:         ""
      opacity: 1.0

    @_config = $.extend {}, defaultConfig, config

  # ============================================================================
  hgInit: (@_hgInstance) ->
    # add module to HG instance
    @_hgInstance.watermark = @

    # includes
    domElemCreator = new HG.DOMElementCreator

    # append pathes
    @_config.imageNormal = @_hgInstance.config.configPath + @_config.imageNormal
    @_config.imageLight = @_hgInstance.config.configPath + @_config.imageLight

    if @_config.imageNormal?
      @_image = domElemCreator.create 'img', @_config.id, ['watermark', 'no-text-select'], [['src', @_config.imageNormal]]
      @_image.style.top = @_config.top        if @_config.top?
      @_image.style.right = @_config.right    if @_config.right?
      @_image.style.bottom = @_config.bottom  if @_config.bottom?
      @_image.style.left = @_config.left      if @_config.left?
      @_hgInstance.getTopArea().appendChild @_image

    else
      @_text = domElemCreator.create 'div', null, 'watermark'
      $(@_text).html @_config.text

      @_text.style.top = @_config.top         if @_config.top?
      @_text.style.right = @_config.right     if @_config.right?
      @_text.style.bottom = @_config.bottom   if @_config.bottom?
      @_text.style.left = @_config.left       if @_config.left?

      @_hgInstance.getTopArea().appendChild @_text

  # ============================================================================
  makeLight: () ->
    if @_image
      $(@_image).attr 'src', @_config.imageLight

  # ============================================================================
  makeNormal: () ->
    if @_image
      $(@_image).attr 'src', @_config.imageNormal
