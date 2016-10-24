window.HG ?= {}

# ==============================================================================
# manages the labels on the map, decides which ones are to be shown / hidden
# work with a priority list for labels
# ==============================================================================

class HG.LabelManager

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_map) ->
    @_labelList = new HG.DoublyLinkedList # ordering: descending label priority

  # ============================================================================
  insert: (newLabel) ->

    # error handling
    return if not newLabel

    # initially show the label to know how much space it occupies on the map
    # => retrieve geometric properties
    @_show newLabel

    # init members
    newLabel.isVisible = yes    # status variable to check if a label is shown or hidden
    newLabel.coveredBy = []     # all labels that cover the current label (passice)
    newLabel.covers = []        # all labels covered by the current label (active)
    newLabel.center = @_map.project newLabel._latlng
    newLabel.width = newLabel._container.offsetWidth * LABEL_PADDING
    newLabel.height = newLabel._container.offsetHeight * LABEL_PADDING


    # in case of empty list, put it as first element
    if @_labelList.isEmpty()
      @_labelList.addFront newLabel

    # otherwise find its position in labelList
    else

      # start with first element
      currNode = @_labelList.head.next

      # check for each label (until the tail of the list is reached)
      while not currNode.isTail()

        currLabel = currNode.data

        # current label has definitely higher priority than new label
        # => if they overlap, new label will be hidden
        if @_labelsOverlap newLabel, currLabel
          newLabel.coveredBy.push currLabel
          currLabel.covers.push newLabel
          @_hide newLabel

        # find the first label with a lower priority
        # => break, because current node is the one we want to add it after
        break if newLabel.priority > currLabel.priority

        # label priority is smaller than priority of current node
        # => check next node
        currNode = currNode.next

      # insert node into label list
      @_labelList.addBefore newLabel, currNode

      # if label has not overlapped => it stays visible
      if newLabel.isVisible
        # check for all lower priority labels if they overlap with it
        # currNode = node for new label
        # => start search with next label
        currNode = currNode.next

        # error handling: stop if already at the tail
        return if not currNode

        # check for each label (until the tail of the list is reached)
        # TODO: make more efficient
        while not currNode.isTail()

          currLabel = currNode.data

          # current label has definitely lower priority than new label
          # => if they overlap, current label will be hidden
          if @_labelsOverlap newLabel, currLabel
            currLabel.coveredBy.push newLabel
            newLabel.covers.push currLabel
            @_hide currLabel

          # go to next label
          currNode = currNode.next

    # @DEBUG()


  # ============================================================================
  remove: (removeLabel) ->

    # error handling
    return if not removeLabel

    # remove label from the map
    @_hide removeLabel

    # idea: each label that was covered by this label and has space now => show
    for coveredLabel, idx in removeLabel.covers

      # update coveredBy list of covered label
      removeIdx = coveredLabel.coveredBy.indexOf removeLabel
      coveredLabel.coveredBy.splice removeIdx, 1

      # check if covered label can be to be shown now
      # = if no more other label covers it
      @_show coveredLabel if (coveredLabel.coveredBy.length is 0)

    # removeLabel does not cover any other label anymore
    removeLabel.covers = []

    # unlink label from all labels that it is covered by
    # -> no other action required, because this does not influence other labels
    for coveringLabel, idx in removeLabel.coveredBy

      # update covers list of covering label
      removeIdx = coveringLabel.covers.indexOf removeLabel
      coveringLabel.covers.splice removeIdx, 1

    # removeLabel is not covered by any other label anymore
    removeLabel.coveredBy = []

    # finally remove the label from the list
    @_labelList.removeElement removeLabel

    # @DEBUG()


  # ============================================================================
  update: (label) ->
    # simple solution: remove and insert again
    # -> not so nice, but I guess it will work ;)
    @remove label
    @insert label

    # TODO: if time, make it nicer:
    # update member variables
    # if it got larger or position has changed
      # check with all higher priority labels if it gets covered by them now
    # if it got smaller or position has changed
      # check with all lower priority labels if it covers them now


  # ============================================================================
  zoomIn: () ->
    # idea: no label has to be removed, some only can potentially be added
    # approach: for each label, update the geometric properties
    # and then determine which labels can be shown now

    # update geometries of all labels to get current data for label collission test
    currNode = @_labelList.head.next
    while not currNode.isTail()
      @_updateGeometry currNode.data
      currNode = currNode.next

    # check for each label
    currNode = @_labelList.head.next
    while not currNode.isTail()

      currLabel = currNode.data

      # check for each label that it originally covered if they can be shown now
      currIdx = 0
      currLen = currLabel.covers.length
      while currIdx < currLen

        lowerLabel = currLabel.covers[currIdx]

        if not @_labelsOverlap currLabel, lowerLabel

          # update cover links
          currLabel.covers.splice currIdx, 1
          lowerIdx = lowerLabel.coveredBy.indexOf currLabel
          lowerLabel.coveredBy.splice lowerIdx, 1

          currLen-- # IMP! array has one element less now!
          currIdx-- # VERY IMP!!! in order to check each element

          # check if current label can be to be shown now
          # = if no more other label covers it
          @_show lowerLabel if (lowerLabel.coveredBy.length is 0)

        # go to next label in list of all covered labels
        currIdx++

      # go to next label in list of all labels
      currNode = currNode.next


  # ============================================================================
  zoomOut: () ->
    # idea: no label has to be be added, some only can potentially be removed
    # approach: for each label, update the geometric properties
    # and then determine which labels can be shown now

    # update geometries of all labels to get current data for label collission test
    currNode = @_labelList.head.next
    while not currNode.isTail()
      @_updateGeometry currNode.data
      currNode = currNode.next

    # check for each visible label
    currNode = @_labelList.head.next
    while not currNode.isTail()

      currLabel = currNode.data

      # invisible labels can not cover others
      # because they are invisible. logical, eh ;)
      if currLabel.isVisible

        # check for each label with lower priority
        lowerNode = currNode.next
        while not lowerNode.isTail()

          lowerLabel = lowerNode.data

          # check if lower priority label needs to be hidden now
          if @_labelsOverlap lowerLabel, currLabel
            lowerLabel.coveredBy.push currLabel
            currLabel.covers.push lowerLabel
            @_hide lowerLabel

          # go to next load with lower priority
          lowerNode = lowerNode.next

      # go to next node
      currNode = currNode.next


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  # main decision function: collission or not?
  # ============================================================================

  _labelsOverlap: (labelA, labelB) ->
    # error handling: if one label does not exist -> abort check
    return false if not labelA? or not labelB?

    # error handling: if labels are the same -> abort check
    return false if @_areEqual labelA, labelB

    # On each axis, check if the centers of the boxes intersect
    # -> If they intersect on both axes, then the boxes intersect => collission
    # -> If they don't => no collission
    return  (Math.abs(labelA.center.x - labelB.center.x) * 2 < (labelA.width +  labelB.width)) and
            (Math.abs(labelA.center.y - labelB.center.y) * 2 < (labelA.height + labelB.height))


  # ============================================================================
  _updateGeometry: (label) ->

    # label must be on the map in order to determine geometric properties
    if not label.isVisible
      @_map.showLabel label
      @_recenter label

    # update properties
    label.center = @_map.project label._latlng
    label.width = label._container.offsetWidth * LABEL_PADDING
    label.height = label._container.offsetHeight * LABEL_PADDING

    # hide again, if necessary
    if not label.isVisible
      @_map.removeLayer label


  # ============================================================================
  # SHOW / HIDE

  # ----------------------------------------------------------------------------
  _show: (label) ->
    if not label.isVisible
      # update model
      label.isVisible = yes
      # update view
      @_map.showLabel label
      @_recenter label

  # ----------------------------------------------------------------------------
  _hide: (label) ->
    if label.isVisible
      # update model
      label.isVisible = no
      # update view
      @_map.removeLayer label

  # ----------------------------------------------------------------------------
  _recenter: (label) ->
    # put text in center of label
    label.options.offset = [
      -(label._container.offsetWidth/2),
      -(label._container.offsetHeight/2)
    ]
    label._updatePosition()


  # ============================================================================
  # UTILS

  # ----------------------------------------------------------------------------
  _areEqual: (labelA, labelB) ->
    (labelA._content?="").localeCompare(labelB._content) is 0



  ##############################################################################
  #                            STATIC INTERFACE                                #
  ##############################################################################

  LABEL_PADDING = 1.15

  # ============================================================================
  DEBUG: () ->
    console.log "=============================================================="
    cn = @_labelList.head.next
    i = 0
    while cn.data
      data =
        curr: if cn.data then cn.data._content + "(" + cn.data.priority + ")"
        prev: if cn.prev.data then cn.prev.data._content + "(" + cn.prev.data.priority + ")"
        next: if cn.next.data then cn.next.data._content + "(" + cn.next.data.priority + ")"
      console.log i, ":", data.curr, "| prev:", data.prev, "| next:", data.next
      cn = cn.next
      i++