window.HG ?= {}

class HG.ButtonArea

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor : (@_hgInstance, config) ->

    # include
    @_domElemCreator = new HG.DOMElementCreator

    # handle config
    defaultConfig =
      id:           null                    # id of the DOM element (no underscore)
      classes:      null                    # ['className'] array
      absPos:       true                    # false = relative position
      posX:         'center'                # 'left', 'right' or 'center'
      posY:         'center'                # 'top', bottom' or 'center'
      orientation:  'horizontal'            # 'horizontal' (default) or 'vertical'
      direction:    'append'                # 'append' (to back) or 'prepend' (to front)
                                            #   (next button added to the area will be
                                            #   appended to the back or prepended to the front)
    @_config = $.extend {}, defaultConfig, config

    # variables (read from config)
    @_posX = new HG.StateVar ['center', 'right', 'left']
    @_posX.set @_config.posX

    @_posY = new HG.StateVar ['center', 'top', 'bottom']
    @_posY.set @_config.posY

    @_orientation = new HG.StateVar ['horizontal', 'vertical']
    @_orientation.set @_config.orientation

    @_direction = new HG.StateVar ['append', 'prepend']
    @_direction.set @_config.direction

    @_groups = new HG.ObjectArray
    @_spacerCtr = 1

    # make button area
    classes = ['button-area']
    classes.push 'button-area-abs' if @_config.absPos
    classes.push 'button-area-' + @_posY.get()
    classes.push 'button-area-' + @_posX.get()
    if @_config.classes
      classes.push c for c in @_config.classes

    @_div = @_domElemCreator.create 'div', @_config.id, classes


  # ============================================================================
  getDOMElement: ()  -> @_div

  # ============================================================================
  # add button solo: leave out groupName (null) => will be put in single unnamed group
  # add button to group: set groupName
  addButton: (button, groupName) ->
    # select group (sets group name manually if no group name)
    name = if groupName then groupName else button.getDOMElement().id + '-group'

    # create button in group
    group = @_addGroup name
    group.appendChild button.getDOMElement()

  # ============================================================================
  addButtonGroup: (name) ->
    group = @_addGroup name

  removeButtonGroup: (name) ->
    @_removeGroup name

  # ============================================================================
  # usage 1: I want a spacer between two button groups =>   myButtonArea.addSpacer()
  # usage 2: I want a spacer inside a button group =>       myButtonArea.addSpacer 'group-name'
  addSpacer: (groupName) ->
    if groupName?
      group = @_addGroup groupName
    else
      group = @_addGroup 'spacer'+@_spacerCtr
    spacer = @_domElemCreator.create 'div', null, ['spacer']
    group.appendChild spacer
    @_spacerCtr++

  # ============================================================================
  moveVertical: (dist) ->
    if @_posY.get() is 'top'
      $(@_div).animate {'top': '+=' + dist}
    else if @_posY.get() is 'bottom'
      $(@_div).animate {'bottom': '+=' + dist}

  moveHorizontal: (dist) ->
    if @_posX.get() is 'left'
      $(@_div).animate {'left': '+=' + dist}
    else if @_posX.get() is 'right'
      $(@_div).animate {'right': '+=' + dist}

  # ============================================================================
  destroy: () -> $(@_div).remove()

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _addGroup: (id) ->
    group = @_groups.getById id
    # if group exists, take it
    if group
      return group
    # if group does not exist, create it
    else
      # add to UI
      classes = ['buttons-group']
      classes.push 'buttons-group-horizontal' if @_orientation.get() is 'horizontal'
      group = @_domElemCreator.create 'div', id, classes

      # append or prepend button (given in configuration of ButtonArea)
      if @_direction.get() is 'append'
        @_div.appendChild group
        @_groups.push group

      else if @_direction.get() is 'prepend'
        @_div.insertBefore group, @_div.firstChild
        @_groups.pushFront group

      # add to group list
      return group

  # ============================================================================
  _removeGroup: (id) ->
    # remove from group list
    @_groups.removeById id
    # remove from UI
    $('#'+id+'-group').remove()
