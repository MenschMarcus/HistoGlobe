window.HG ?= {}

# ============================================================================
# Array of objects
# [ {}, {}, ... ]
# assumption: each object in list is unique
# ============================================================================

class HG.ObjectArray

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_arr) ->
    # todo: only accept array of objects as initial input, otherwise empty
    @_arr = [] unless @_arr

    @_ids = []  # contains all ids of objects in the array to ensure they are unique
    @_ids.push o.id for o in @_arr

  # ============================================================================
  # get number of elements in ObjectArray
  length: () ->         @_arr.length
  num: () ->            @_arr.length

  # ============================================================================
  # push an element to the end of the ObjectArray
  push: (obj) ->        @_pushToBack obj
  pushBack: (obj) ->    @_pushToBack obj
  add: (obj) ->         @_pushToBack obj
  append: (obj) ->      @_pushToBack obj

  # ============================================================================
  # push an element to the front of the ObjectArray
  pushFront: (obj) ->   @_pushToFront obj
  addFront: (obj) ->    @_pushToFront obj
  prepend: (obj) ->     @_pushToFront obj

  # ============================================================================
  # empty the ObjectArray
  empty: () ->          @_arr = []
  clear: () ->          @_arr = []

  # ============================================================================
  # get an element in the ObjectArray by providing a name and a value of the property
  # usage: myObjArr.getByPropValue 'name', name_I_am_looking_for
  getByPropVal: (prop, val) ->        @_getByPropVal prop, val
  getByPropertyValue: (prop, val) ->  @_getByPropVal prop, val

  # ============================================================================
  # get an element in the ObjectArray by providing its id
  # usage: myObjArr.getById id_I_am_looking_for
  getById: (val) ->       @_getByPropVal 'id', val

  # ============================================================================
  # get an element by its position in the ObjectArray
  # usage: myObjArr.getByIdx 0                  -> first element
  # usage: myObjArr.getByIdx myObjArr.num()-1   -> last element
  getByIdx: (idx) ->      @_getByIdx idx
  getByIndex: (idx) ->    @_getByIdx idx

  # ============================================================================
  # find element whose property has this value and deletes it (multiple names for convenience)
  # usage: myObjArr.remove 'name', name_I_am_looking_for
  remove: (prop, val) ->  @_remove prop, val
  delete: (prop, val) ->  @_remove prop, val

  # ============================================================================
  # delete element by its id
  # usage: myObjArr.removeById, id
  removeById: (val) ->    @_remove 'id', val
  deleteById: (val) ->    @_remove 'id', val

  # ============================================================================
  # execute a function on each object of the array
  # usage: arr.foreach (elem) => console.log elem
  foreach: (cb) ->        cb el for el in @_arr
    # maaaagic!
    # executes given callback for each element in the array
    # hands element of array callback


  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _pushToBack: (obj) ->
    if @_check obj
      @_ids.push obj.id
      @_arr.push obj

  _pushToFront: (obj) ->
    if @_check obj
      @_ids.unshift obj.id
      @_arr.unshift obj

  # ============================================================================
  _remove: (prop, val) ->
    # get index of elem in arr
    idx = -1
    i = 0
    len = @_arr.length
    while i < len
      if @_arr[i][prop] == val
        idx = i
        break
      i++
    # remove elem of array by index
    unless idx is -1
      @_arr.splice idx, 1
    else
      console.error "The element with the property " + prop + " and the value " + val + " can not be deleted from the ObjectArray, because it does not exist."

  # ============================================================================
  _getByPropVal: (prop, val) ->
    res = $.grep @_arr, (r) ->
      r[prop] == val
    if res.length > 0
      return res[0]
    else
      # console.error "There is no element with the property " + prop + " and the value " + val + " in the ObjectArray"
      return null

  # ============================================================================
  _getByIdx: (idx) ->
    if idx < @_arr.length
      @_arr[idx]
    else
      console.error "The ObjectArray has no element at position " + idx + ", it only contains " + @_arr.length " elements"

  # ============================================================================
  # error handling: is id unique? returns yes / no
  _check: (o) ->
    if $.inArray o.id, @_ids is -1
      true
    else
      console.error "id " + o.id + " is already given!"
      false