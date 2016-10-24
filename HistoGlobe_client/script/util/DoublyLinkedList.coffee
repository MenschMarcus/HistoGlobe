window.HG ?= {}

class HG.DoublyLinkedList


  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: () ->
    @head = new HG.DoublyLinkedListNode null   # head.next = pointer to first item
    @tail = new HG.DoublyLinkedListNode null   # tail.prev = pointer to last item

    # link head and tail together
    @head.next = @tail    # @head.prev is null
    @tail.prev = @head    # @tail.next is null

    @_length = 0    # length of list


  # ============================================================================
  # get number of elements / length / size of list
  # ============================================================================

  length: () ->     @_length
  size: () ->       @_length
  num: () ->        @_length

  isEmpty: () ->    @_length is 0


  # ============================================================================
  # add element in the list after another
  # ============================================================================

  addAfter: (element, predecessor) ->   @_addAfter  element, predecessor


  # ============================================================================
  # add element in the list after another
  # ============================================================================

  addBefore: (element, sucessor) ->     @_addBefore element, sucessor


  # ============================================================================
  # add an element to the front of the list
  # ============================================================================

  addFront: (element) ->                @_addAfter  element, @head
  pushFront: (element) ->               @_addAfter  element, @head
  prepend: (element) ->                 @_addAfter  element, @head


  # ============================================================================
  # add an element to the end of the list
  # ============================================================================

  addBack: (element) ->                 @_addBefore element, @tail
  pushBack: (element) ->                @_addBefore element, @tail
  append: (element) ->                  @_addBefore element, @tail

  # ============================================================================
  # remove a node or an element from the list
  # ============================================================================

  removeElement: (element) ->           @_remove @_getNode element
  removeNode: (node) ->                 @_remove node

  # ============================================================================
  # get the node associated to that element
  # ============================================================================

  getNode: (element) ->                 @_getNode element


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _addAfter: (element, predecessor) ->
    successor = predecessor.next

    # create new node
    newNode = new HG.DoublyLinkedListNode element

    # update predecessor
    newNode.prev = predecessor
    predecessor.next = newNode

    # update successor
    newNode.next = successor
    if successor  # predecessor is not the tail
      successor.prev = newNode
    else          # predecessor is the tail
      @tail = newNode

    @_length++

  # ----------------------------------------------------------------------------
  _addBefore: (element, successor) ->
    predecessor = successor.prev

    # create new node
    newNode = new HG.DoublyLinkedListNode element

    # update successor
    newNode.next = successor
    successor.prev = newNode

    # update predecessor
    newNode.prev = predecessor
    if predecessor  # sucessor is not the head
      predecessor.next = newNode
    else          # sucessor is the head
      @head = newNode

    @_length++


  # ============================================================================
  _remove: (node) ->

    # error handling
    return if not node

    # update node
    node.prev.next = node.next if node.prev
    node.next.prev = node.prev if node.next

    # update list
    @head = node.next if @head is node
    @tail = node.prev if @tail is node

    @_length--


  # ============================================================================
  _getNode: (element) ->

    currentNode = @head.next
    while currentNode.data
      return currentNode if currentNode.data is element
      currentNode = currentNode.next
    return null