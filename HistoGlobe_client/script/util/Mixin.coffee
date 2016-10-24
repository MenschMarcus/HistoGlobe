window.HG ?= {}

# ==============================================================================
# Copies all function definitions specified in object "mixin" to object
# "object". As a result, the copied functions may now be called on "object".
# ==============================================================================
HG.mixin = (object, mixin) ->

  for name, method of mixin.prototype
    object[name] = method

  for name, method of mixin
    object[name] = method

