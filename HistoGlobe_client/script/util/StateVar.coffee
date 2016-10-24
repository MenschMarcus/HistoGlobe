window.HG ?= {}

# ============================================================================
# variable with discrete amount of states named with a string
# e.g. 'direction' is either 'horizontal' or 'vertical'
# usage:
# 1)  initialize StateVar with an array of all possible states
#     whereas the first value is the default and fallback value
#       myVar = new HG.StateVar ['stateA', 'stateB']
# 2)  set the variable with any value
#     if value is available, take it, if not, take fallback value
#       myVar.set 'stateX'
# 3)  get the value of the variable
#       myVar.get()
# ============================================================================

class HG.StateVar

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_states) ->
    @_value = @_states[0]

  # ============================================================================
  set: (inValue) ->
    idx = @_states.indexOf inValue
    if idx isnt -1              # if value is a possible state
      @_value = @_states[idx]   # -> take it
    else                        # if not
      @_value = @_states[0]     # -> use fallback value

  # ============================================================================
  get: () ->
    @_value

  # ============================================================================
  getDefault: () ->
    @_states[0]