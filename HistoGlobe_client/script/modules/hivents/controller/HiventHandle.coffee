window.HG ?= {}

# ==============================================================================
# HiventHandle encapsulates states that are necessary for and triggered by the
# interaction with Hivents through map, timeline and so on. Other
# objects may register listeners for changes and/or trigger state changes.
# Every HiventHandle is responsible for exactly one Hivent.
# ==============================================================================
class HG.HiventHandle

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # Constructor
  # Initializes member data and stores a reference to the passed Hivent object.
  # ============================================================================
  constructor: (@_hgInstance, hivent) ->

    @_hivent = hivent

    # Internal states
    @_activated = false
    @_marked = false
    @_focused = false
    @_age = 0.0

    @_state = 0
    # 0 --> invisible
    # 1 --> visiblePast
    # 2 --> visibleFuture

    @sortingIndex = -1

    # Add callback functionality
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    # Add callbacks for all states. These are triggered by the corresponding
    # function specified below.
    @addCallback "onActive"
    @addCallback "onInActive"
    @addCallback "onMark"
    @addCallback "onUnMark"
    @addCallback "onLink"
    @addCallback "onUnLink"
    @addCallback "onFocus"
    @addCallback "onUnFocus"
    @addCallback "onDestroy"
    @addCallback "onAgeChanged"

    @addCallback "onVisiblePast"
    @addCallback "onVisibleFuture"
    @addCallback "onInvisible"

  # ============================================================================
  # Returns the assigned Hivent.
  # ============================================================================

  getHivent: ->
    @_hivent


  # ============================================================================
  # Returns whether or not the HiventHandle is active.
  # ============================================================================

  isActive: () ->
    @_activated


  # ============================================================================
  # Returns whether or not the Hivent happened between two given dates
  # N.B. > and <= !!!
  # ============================================================================

  happenedBetween: (dateA, dateB) ->
    (@_hivent.date > dateA) and (@_hivent.date <= dateB)


  # ============================================================================
  # Notifies listeners that the HiventHandle is now active. Usually, this is
  # triggered when a map or timeline icon belonging to a Hivent is being
  # clicked. "mousePixelPosition" may be passed and should be the click's
  # location in device coordinates.
  # ============================================================================

  activeAll: (mousePixelPosition) ->
    @_activated = true
    ACTIVE_HIVENTS.push @
    @notifyAll "onActive", mousePixelPosition, @

  # ----------------------------------------------------------------------------
  active: (obj, mousePixelPosition) ->
    @_activated = true
    ACTIVE_HIVENTS.push @
    @notify "onActive", obj, mousePixelPosition, @


  # ============================================================================
  # Notifies all listeners that the HiventHandle is now inactive. Usually, this
  # is triggered when a map or timeline icon belonging to a Hivent is being
  # clicked. "mousePixelPosition" may be passed and should be the click's
  # location in device coordinates.
  # ============================================================================

  inActiveAll: (mousePixelPosition) ->
    @_activated = false
    index = $.inArray(@, ACTIVE_HIVENTS)
    if index >= 0 then delete ACTIVE_HIVENTS[index]
    @notifyAll "onInActive", mousePixelPosition, @

  # ----------------------------------------------------------------------------
  inActive: (obj, mousePixelPosition) ->
    @_activated = false
    index = $.inArray(@, ACTIVE_HIVENTS)
    if index >= 0 then delete ACTIVE_HIVENTS[index]
    @notify "onInActive", obj, mousePixelPosition, @


  # ============================================================================
  # Toggles the HiventHandle's active state and notifies all listeners according
  # to the new value of "@_activated".
  # ============================================================================

  toggleActiveAll: (mousePixelPosition) ->
    @_activated = not @_activated
    if @_activated
      @activeAll mousePixelPosition
    else
      @inActiveAll mousePixelPosition

  # ----------------------------------------------------------------------------
  toggleActive: (obj, mousePixelPosition) ->
    @_activated = not @_activated
    if @_activated
      @active obj, mousePixelPosition
    else
      @inActive obj, mousePixelPosition


  # ============================================================================
  # Notifies all listeners that the HiventHandle is now marked. Usually, this is
  # triggered when a map or timeline icon belonging to a Hivent is being
  # hovered. "mousePixelPosition" may be passed and should be the mouse's
  # location in device coordinates.
  # ============================================================================

  markAll: (mousePixelPosition) ->
    unless @_marked
      @_marked = true
      @notifyAll "onMark", mousePixelPosition

  # ----------------------------------------------------------------------------
  mark: (obj, mousePixelPosition) ->
    unless @_marked
      @_marked = true
      @notify "onMark", obj, mousePixelPosition


  # ============================================================================
  # Notifies all listeners that the HiventHandle is no longer marked. Usually,
  # this is triggered when a map or timeline icon belonging to a Hivent is being
  # hovered. "mousePixelPosition" may be passed and should be the mouse's
  # location in device coordinates.
  # ============================================================================

  unMarkAll: (mousePixelPosition) ->
    if @_marked
      @_marked = false
      @notifyAll "onUnMark", mousePixelPosition

  # ----------------------------------------------------------------------------
  unMark: (obj, mousePixelPosition) ->
    if @_marked
      @_marked = false
      @notify "onUnMark", obj, mousePixelPosition


  # ============================================================================
  # Notifies all listeners to focus on the Hivent associated with the
  # HiventHandle.
  # ============================================================================

  focusAll: () ->
    @_focused = true
    @notifyAll "onFocus"

  # ----------------------------------------------------------------------------
  focus: (obj) ->
    @_focused = true
    @notify "onFocus", obj

  # ============================================================================
  # Notifies all listeners that the Hivent associated with the HiventHandle
  # shall no longer be focussed.
  # ============================================================================

  unFocusAll: () ->
    @_focused = false
    @notifyAll "onUnFocus"

  # ----------------------------------------------------------------------------
  unFocus: (obj) ->
    @_focused = false
    @notify "onUnFocus", obj



  # ============================================================================
  # Notifies all listeners that the Hivent the HiventHandle is destroyed. This
  # is used to allow for proper clean up.
  # ============================================================================

  destroyAll: ->
    @notifyAll "onDestroy"
    delete @

  # ----------------------------------------------------------------------------
  destroy: (obj) ->
    @notify "onDestroy", obj
    delete @


  # ============================================================================
  # Sets the HiventHandle's visibility state.
  # ============================================================================
  setState: (state) ->
    if @_state isnt state

      if state is 0
        @notifyAll "onInvisible", @, @_state
      else if state is 1
        @notifyAll "onVisiblePast", @, @_state
      else if state is 2
        @notifyAll "onVisibleFuture", @, @_state
      else
        console.warn "Failed to set HiventHandle state: invalid state #{state}!"

      @_state = state


  # ============================================================================
  # Sets the HiventHandle's age.
  # what is the age?
  # ============================================================================

  setAge: (age) ->
    if @_age isnt age
      @_age = age
      @notifyAll "onAgeChanged", age, @


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################


  ##############################################################################
  #                             STATIC MEMBERS                                 #
  ##############################################################################
  ACTIVE_HIVENTS = []
  window.LINKED_HIVENT=0