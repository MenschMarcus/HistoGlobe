window.HG ?= {}

# ==============================================================================
# AreaHandle encapsulates states that are necessary for and triggered by the
# interaction with Areas through Map, HistoGraph and so on. Other
# objects may register listeners for changes and/or trigger state changes.
# Every AreaHandle is responsible for exactly one Area.
# ==============================================================================

class HG.AreaHandle

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # Initializes member data and stores a reference to the passed Area object.
  # ============================================================================

  constructor: (@_hgInstance, @_area) ->

    # internal states                                           functions to toggle state
    @_visible = no    # is area currently on the map?           show()      hide()
    @_focused = no    # is area currently in focus (hovered)?   focus()     unfocus()
    @_selected = no   # is area currently active/selected?      select()    deselect()
    @_inEdit = no     # is area in edit mode?                   startEdit() endEdit()

    # handling of main properties
    @_hasTerritory =    @_area.territory? # model: does area have a territory?
    @_hasName =         @_area.name?      # model: does area have a name?
    @_territoryShown =  no                # view: is the territory shown?
    @_nameShown =       no                # view: is the name shown?

    @sortingIndex = -1

    # Add callback functionality
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    # Add callbacks for all states.
    # These are triggered by the corresponding function specified below.

    @addCallback 'onAddTerritory'
    @addCallback 'onUpdateTerritory'
    @addCallback 'onRemoveTerritory'
    @addCallback 'onAddName'
    @addCallback 'onUpdateName'
    @addCallback 'onRemoveName'

    @addCallback 'onFocus'
    @addCallback 'onUnfocus'
    @addCallback 'onSelect'
    @addCallback 'onDeselect'
    @addCallback 'onStartEdit'
    @addCallback 'onEndEdit'

    @addCallback 'onDestroy'

    # add myself to AreaController, so everybody knows about me
    @_hgInstance.areaController.addAreaHandle @


  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ### GET PROPERTIES OF THE AREA ###
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # ============================================================================
  # Return the actual Area associated to the handle.
  # ============================================================================

  getArea: ->       @_area


  # ============================================================================
  # Return start / end date of the Area.
  # ============================================================================

  getStartDate: () ->
    # startHivent must be given, so no error handling necessary
    @_area.startHivent.getHivent().date

  # ----------------------------------------------------------------------------
  getEndDate: () ->
    if @_area.endHivent # if it has an end hivent
      @_area.endHivent.getHivent().date
    else                # if it does nothave an end hivent, it is still valid
      moment()          # = now


  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ### GET STATE OF THE AREA ###
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  isVisible: () ->  @_visible
  isFocused: () ->  @_focused
  isSelected: () -> @_selected
  isInEdit: () ->   @_inEdit


  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ### CHANGE STATE OF THE AREA ###
  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # ============================================================================
  # Notifies all listeners that the Area associated with the AreaHandle is now
  # visible. This is triggered when an hivent occurs that makes this area valid.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  show: (obj=null) ->
    if not @_visible
      @_hasTerritory =  @_area.territory?
      @_hasName =       @_area.name?
      @_visible =       yes
      VISIBLE_AREAS.push @

      if @_hasTerritory
        if obj then @notify    'onAddTerritory', obj, @
        else        @notifyAll 'onAddTerritory', @
        @_territoryShown = yes

      if @_hasName
        if obj then @notify    'onAddName', obj, @
        else        @notifyAll 'onAddName', @
        @_nameShown = yes

  # ============================================================================
  # Notifies all listeners that the Area associated with the AreaHandle is now
  # invisible. This is triggered when an hivent occurs that makes this area invalid.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  hide: (obj=null) ->
    if @_visible

      if @_territoryShown
        if obj then @notify    'onRemoveTerritory', obj, @
        else        @notifyAll 'onRemoveTerritory', @
        @_territoryShown = no

      if @_nameShown
        if obj then @notify    'onRemoveName', obj, @
        else        @notifyAll 'onRemoveName', @
        @_nameShown = no

      @_removeFromArray(@, VISIBLE_AREAS)
      @_visible = no

  # ============================================================================
  # Notifies all listeners that the Area associated with the AreaHandle has
  # has changed (either its name or its territory). This is triggered when
  # the Area gets edited in EditMode.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # this became really complex. Please admire the complexity and pray that this
  # piece of code will never need to be changed again. Amen!
  # ============================================================================

  update: (obj=null) ->

    ## update territory
    hadTerritoryBefore    = @_hasTerritory
    hasTerritoryNow       = @_area.territory?
    @_hasTerritory        = hasTerritoryNow

    territoryShownBefore  = @_territoryShown
    territoryShownNow     = hasTerritoryNow and @_visible

    if not territoryShownBefore and territoryShownNow
      if obj then @notify    'onAddTerritory', obj, @
      else        @notifyAll 'onAddTerritory', @
      @_territoryShown = yes

    else if territoryShownBefore and territoryShownNow
      if obj then @notify    'onUpdateTerritory', obj, @
      else        @notifyAll 'onUpdateTerritory', @
      @_territoryShown = yes

    else if territoryShownBefore and not territoryShownNow
      if obj then @notify    'onRemoveTerritory', obj, @
      else        @notifyAll 'onRemoveTerritory', @
      @_territoryShown = no

    else # not territoryShownBefore and not territoryShownNow
      @_territoryShown = no


    ## update name
    hadNameBefore    = @_hasName
    hasNameNow       = @_area.name?
    @_hasName        = hasNameNow

    nameShownBefore  = @_nameShown
    nameShownNow     = hasNameNow and @_visible

    if not nameShownBefore and nameShownNow
      if obj then @notify    'onAddName', obj, @
      else        @notifyAll 'onAddName', @
      @_nameShown = yes

    else if nameShownBefore and nameShownNow
      if obj then @notify    'onUpdateName', obj, @
      else        @notifyAll 'onUpdateName', @
      @_nameShown = yes

    else if nameShownBefore and not nameShownNow
      if obj then @notify    'onRemoveName', obj, @
      else        @notifyAll 'onRemoveName', @
      @_nameShown = no

    else # not nameShownBefore and not nameShownNow
      @_nameShown = no




  # ============================================================================
  # Notifies all listeners to focus on the Area associated with the AreaHandle.
  # This is triggered when a map area layer is being hovered.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  focus: (obj=null) ->
    if not @_focused

      # edit mode: only selected areas in edit mode can be focused
      areaEditMode = @_hgInstance.editMode?.areaEditMode()
      if areaEditMode is on
        if (@_inEdit) and (not @_selected)
          @_focused = yes

      # normal mode: each area can be focused
      else  # areaEditMode is off
        @_focused = yes

      # update
      if @_focused
        if obj then @notify    'onFocus', obj, @
        else        @notifyAll 'onFocus', @

  # ============================================================================
  # Notifies all listeners to unfocus on the Area associated with the AreaHandle.
  # This is triggered when a map area layer is not being hovered anymore.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  unfocus: (obj=null) ->
    if @_focused
      @_focused = false
      if obj then @notify    'onFocus', obj, @
      else        @notifyAll 'onFocus', @


  # ============================================================================
  # Notifies listeners that the Area associated with the AreaHandle is now
  # selected. This is triggered when a map area layer belonging to a Area is
  # being clicked on.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  select: (obj=null) ->

    # status changes:         4 possible outcomes
    becameSelected = no     # yes = unselected -> selected    no = stays unselected
    becameDeselected = no   # yes = selected -> unselected    no = stays selected

    # area is selected => deselect
    if @_selected
      becameDeselected = yes

    # area is not selected => decide if it can be selected
    else

      # maximum number of areas that can be selected
      maxSelections = @_hgInstance.areaController.getMaxNumOfSelections()

      # single-selection mode: toggle selected area
      if maxSelections is 1
        SELECTED_AREAS[0].deselect(obj) if SELECTED_AREAS.length is 1
        becameSelected = yes


      # multi-selection mode: add to selected area if max limit is not reached
      else  # maxSelections > 1
        if SELECTED_AREAS.length < maxSelections
          becameSelected = yes

      # else: area not selected but selection limit reached => no selection

    # status change 1) deselected -> selected
    if becameSelected
      @_selected = yes
      SELECTED_AREAS.push @
      if obj then @notify    'onSelect', obj, @
      else        @notifyAll 'onSelect', @

    # status change 3) selected -> deselected
    if becameDeselected
      @deselect obj


  # ============================================================================
  # Notifies listeners that the Area associated with the AreaHandle is now not
  # selected anymore. This is triggered when a selected map area layer belonging
  # to a Area is being clicked on again.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  deselect: (obj=null) ->
    if @_selected
      @_selected = no
      @_removeFromArray(@, SELECTED_AREAS)
      if obj then @notify    'onDeselect', obj, @
      else        @notifyAll 'onDeselect', @


  # ============================================================================
  # Notifies listeners that the Area associated with the AreaHandle is now in
  # the EditMode. This is triggered when an area is set in this state by an
  # action in an EditOperationStep.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  startEdit: (obj=null) ->
    if not @_inEdit
      @_inEdit = yes
      EDIT_AREAS.push @
      if obj then @notify    'onStartEdit', obj, @
      else        @notifyAll 'onStartEdit', @


  # ============================================================================
  # Notifies listeners that the AreaHandle is now not selected anymore. This is
  # triggered when a selected map area layer belonging to a Area is being
  # clicked on again.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  endEdit: (obj=null) ->
    if @_inEdit
      @_inEdit = no
      @_removeFromArray @, EDIT_AREAS
      if obj then @notify    'onEndEdit', obj, @
      else        @notifyAll 'onEndEdit', @


  # ============================================================================
  # Notifies listeners that the Area in the AreaHandle is destroyed. This
  # is used to allow for proper clean up.
  # Notifies either a specific listener (by specifying an obj) or all listeners.
  # ============================================================================

  destroy: (obj=null) ->
    # clean cleanup
    @unfocus obj
    @deselect obj
    @endEdit obj
    @hide obj
    # tell everyone
    if obj then @notify    'onDestroy', obj, @
    else        @notifyAll 'onDestroy', @
    # really clean cleanup
    delete @_area
    # incredibly Mr. Proper clean cleanup
    delete @


  # ============================================================================
  # Returns the current style of the area based on its status.
  # This one function that does all the coloring was SO hard to come up with.
  # Please apply no major changes, it will be a f***ing p*in *n the a**
  # ============================================================================

  getStyle: () ->

    # --------------------------------------------------------------------------
    #   different vocabulary for leaflet layers and svg paths (animated by d3)
    #   property          leaflet       svg (d3)
    #   ------------------------------------------------
    #   areaColor         fillColor     fill
    #   areaOpacity       fillOpacity   fill-opacity
    #   borderColor       color         stroke
    #   borderOpacity     opacity       stroke-opacity
    #   bordeWidth        weight        stroke-width
    # --------------------------------------------------------------------------

    ## initial style configuration

    style = {
      'areaColor' :      HGConfig.color_white.val
      'areaOpacity' :    HGConfig.area_full_opacity.val
      'borderColor' :    HGConfig.color_bg_dark.val
      'borderOpacity' :  HGConfig.border_opacity.val
      'borderWidth' :    HGConfig.border_width.val
    }


    ## change certain style properties based on the area status

    # --------------------------------------------------------------------------
    # decision tree:        _________ inEdit? _________
    #                     1/                           \0
    #                 selected?                      selected?
    #             1/           \0                1/            \0
    #             |         focused?         focused?        focused?
    #             |       1/      \0       1/      \0      1/      \0
    #             x       x       x        x       x       x       x
    #           (ES)    (EF)     (E)     (NSF)   (NS)    (NF)     (N)
    # --------------------------------------------------------------------------

    if @_inEdit

      if @_selected
        # (ES)  in edit mode + selected + can not be focused => full active
        style.areaColor = HGConfig.color_active.val

      else # not selected

        if @_focused
          # (EF)  in edit mode + unselected + focused => full highlight
          style.areaColor = HGConfig.color_highlight.val

        else # not focused
          # (E)  in edit mode + unselected + not focused => half active
          style.areaColor =   HGConfig.color_active.val
          style.areaOpacity = HGConfig.area_half_opacity.val

    else # not in edit

      if @_selected

        if @_focused
          # (NSF) normal area + selected + focused => full highlight
          style.areaColor = HGConfig.color_highlight.val

        else # not focused
          # (NS) normal area + selected + not focused => half active
          style.areaColor =   HGConfig.color_active.val
          style.areaOpacity = HGConfig.area_half_opacity.val

      else # not selected

        if @_focused
          # (NF) normal area + unselected + focused => half highlight
          style.areaColor =   HGConfig.color_highlight.val
          style.areaOpacity = HGConfig.area_half_opacity.val

        # else not focused
          # (N) normal area + unselected + not focused => initial configuration
          # => no change

    return style


  ##############################################################################
  #                             PRIVATE MEMBERS                                #
  ##############################################################################

  # ============================================================================
  # clean way to remove an element from an array.
  # Should be implemented in Array, but this way it is much faster :D
  # ============================================================================

  _removeFromArray: (elem, array) ->
    idx = array.indexOf elem
    array.splice(idx, 1) if idx >= 0

  ##############################################################################
  #                             STATIC MEMBERS                                 #
  ##############################################################################

  VISIBLE_AREAS = []    # areas currently visible in the view
  SELECTED_AREAS = []   # areas currently selected in the view
  EDIT_AREAS = []       # areas currently in the edit mode
