window.HG ?= {}

class HG.Vector

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (data...) ->
    @_data = data

  # ============================================================================
  clone: ->
    newVec = new HG.Vector()
    for i in [0...@_data.length]
      newVec._data.push new Object @_data[i]
    return newVec

  # ============================================================================
  at: (index) ->
    unless index >= @_data.length or index < 0
      return @_data[index]
    console.error "Cannot access Vector at index #{index}: Index out of bounds!"
    return undefined

  # ============================================================================
  add: (other) ->
    unless @_data.length != other._data.length
      for i in [0...other._data.length]
        @_data[i] += other._data[i]
    else console.error "Cannot add Vector of size #{other._data.length} to Vector of size #{@_data.length}"
    return @

  # ============================================================================
  addScalar: (scalar) ->
    for i in [0...@_data.length]
      @_data[i] += scalar

  # ============================================================================
  sub: (other) ->
    unless @_data.length != other._data.length
      for i in [0...other._data.length]
        @_data[i] -= other._data[i]
    else console.error "Cannot subtract Vector of size #{other._data.length} from Vector of size #{@_data.length}"
    return @

  # ============================================================================
  subScalar: (scalar) ->
    for i in [0...@_data.length]
      @_data[i] -= scalar

  # ============================================================================
  mul: (other) ->
    unless @_data.length != other._data.length
      for i in [0...other._data.length]
        @_data[i] *= other._data[i]
    else console.error "Cannot multiply Vector of size #{other._data.length} with Vector of size #{@_data.length}"
    return @

  # ============================================================================
  mulScalar: (scalar) ->
    for i in [0...@_data.length]
      @_data[i] *= scalar

  # ============================================================================
  div: (other) ->
    unless @_data.length != other._data.length
      for i in [0...other._data.length]
        @_data[i] /= other._data[i]
    else console.error "Cannot divide Vector of size #{@_data.length} by Vector of size #{other._data.length}"
    return @

  # ============================================================================
  divScalar: (scalar) ->
    for i in [0...@_data.length]
      @_data[i] /= scalar

  # ============================================================================
  dot: (other) ->
    result = 0
    unless @_data.length != other._data.length
      for i in [0...other._data.length]
        result += @_data[i] * other._data[i]

    console.error "Cannot compute dot product of Vector of size #{other._data.length} and Vector of size #{@_data.length}"
    return result

  # ============================================================================
  lengthSquared: ->
    result = 0
    for i in [0...@_data.length]
      result += @_data[i] * @_data[i]

    return result

  # ============================================================================
  length: ->
    return Math.sqrt @lengthSquared()

  # ============================================================================
  normalize: ->
    @divScalar @length()
    return @

