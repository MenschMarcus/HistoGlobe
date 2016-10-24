window.HG ?= {}

# ==============================================================================
# VIEW class
# set up and handle title + background at the top
# TODO: make this more generic... but no need to do this now ;)
# ==============================================================================

class HG.Title

  # ============================================================================
  constructor: (@_hgInstance, text=null) ->
    # add to HG instance
    @_hgInstance.editTitle = @

    # include
    domElemCreator = new HG.DOMElementCreator

    # create transparent title bar (insert as second child!, so it is background of everything)
    @_titleBar = domElemCreator.create 'div', 'titlebar', null
    @_hgInstance.getTopArea().insertBefore @_titleBar, @_hgInstance.getTopArea().firstChild.nextSibling

    # create actual title bar (insert as third child!, so it does not cover buttons)
    @_title = domElemCreator.create 'div', 'title', null
    $(@_title).html text if text?
    @_hgInstance.getTopArea().insertBefore @_title, @_hgInstance.getTopArea().firstChild.nextSibling.nextSibling

    @resize()

    # resize automatically
    $(window).on 'resize', @resize

  # ============================================================================
  set: (txt) ->   $(@_title).html txt
  clear: () ->    $(@_title).html ''

  # ============================================================================
  # TODO: make independent from edit mode
  resize: () =>
    width = $(window).width() -
      2 * HGConfig.element_window_distance.val -
      2 * HGConfig.title_distance_horizontal.val -
      HGConfig.logo_width.val -
      $('#editButtons').width()
    # PAIN IN THE AAAAAAAAAAASS!
    @_title.style.width = width + 'px'
    @_hgInstance.updateLayout()


  # ============================================================================
  destroy: () ->
    $(@_titleBar)?.remove()
    $(@_title)?.remove()