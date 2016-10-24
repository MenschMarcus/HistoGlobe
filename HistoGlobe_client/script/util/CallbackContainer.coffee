window.HG ?= {}

# ==============================================================================
# Mixin class to add callback functionality. Any other class may add the
# functions specified in CallbackContainer to their interface. For a basic
# example, please see the lines below the class definition.
# ==============================================================================
class HG.CallbackContainer

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  # Adds a callback with the specified "callbackName" to the object. Other
  # objects may now register for notifications.
  # ============================================================================
  addCallback: (callbackName) ->

    # add an array which will contain the callbacks to the object
    arrayName = "_#{callbackName}Callbacks"
    @[arrayName] = []

    # add a function to register callbacks to the object
    @[callbackName] = (obj, callbackFunc) ->
      if callbackFunc and typeof(callbackFunc) == "function"
        for i in [0...@[arrayName].length]
          if @[arrayName][i]?[0] == obj
            @[arrayName][i][1].push callbackFunc
            return

        # if arrayName is "_onDestructionCallbacks"
        #   console.log arrayName
        #   console.log obj
        @[arrayName].push [obj, [callbackFunc]]

  # ============================================================================
  # Notifies a specific listener (objectToBeNotified), registered for the
  # callback named "callbackName" and pass parameters to the listener's
  # registered function.
  # ============================================================================
  notify: (callbackName, objectToBeNotified, parameters...) ->
    arrayName = "_#{callbackName}Callbacks"

    @[arrayName] = @[arrayName].filter (item) -> item isnt null

    for i in [0...@[arrayName].length]
      if @[arrayName][i][0] == objectToBeNotified
        for j in [0...@[arrayName][i][1].length]
          @[arrayName][i][1][j].apply @[arrayName][i][0], parameters
        break

  # ============================================================================
  # Notifies all but a specific listener (objectNotToBeNotified), registered
  # for the callback named "callbackName" and pass parameters to the listener's
  # registered function.
  # ============================================================================
  notifyAllBut: (callbackName, objectNotToBeNotified, parameters...) ->
    arrayName = "_#{callbackName}Callbacks"

    @[arrayName] = @[arrayName].filter (item) -> item isnt null

    for i in [0...@[arrayName].length]
      if @[arrayName][i][0] != objectNotToBeNotified
        for j in [0...@[arrayName][i][1].length]
          @[arrayName][i][1][j].apply @[arrayName][i][0], parameters

  # ============================================================================
  # Notifies all listeners, registered for the callback named "callbackName"
  # and pass parameters to the listeners' registered functions.
  # ============================================================================
  notifyAll: (callbackName, parameters...) ->
    arrayName = "_#{callbackName}Callbacks"

    @[arrayName] = @[arrayName].filter (item) -> item isnt null

    for i in [0...@[arrayName].length]
      for j in [0...@[arrayName][i][1].length]
        @[arrayName][i][1][j].apply @[arrayName][i][0], parameters


  # ============================================================================
  # Removes a specific listener (listenerToBeRemoved) from among all objects
  # listening on the callback named "callbackName".
  # ============================================================================
  removeListener: (callbackName, listenerToBeRemoved) ->
    arrayName = "_#{callbackName}Callbacks"
    for i in [0...@[arrayName].length]
      if @[arrayName][i]?[0] == listenerToBeRemoved
        @[arrayName][i] = null
        break

  # ============================================================================
  # Removes all listeners listening on the callback named "callbackName".
  # ============================================================================
  removeAllListeners: (callbackName) ->
    arrayName = "_#{callbackName}Callbacks"
    @[arrayName] = []


################################################################################
#                            BASIC EXAMPLE                                     #
################################################################################
"""
# This example has not been tested, but it should help to get the basic idea ;)

# Class that contains callback.
class HG.CountDown

  constructor: () ->

    # Add callback functionality
    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    # Add a callback
    @addCallback "onCounterValueDecreased"

    @_counterValue = 10

  # Member function that decreases the internal counter's value and notifies all
  # listeners.
  decreaseCounter: () ->
    @_counterValue = @_counterValue - 1
    @notifyAll "onCounterValueDecreased", @_counterValue

# Class that listens.
class HG.CountDownInformer

  constructor: () ->

    # Create new CountDown object.
    @_countDown = new HG.CountDown

    # Register this object for changes and specify a function to be called every
    # time "notifyAll" or "notify" is being called
    @_countDown.onCounterValueDecreased @, (counterValue) =>
      console.log counterValue

    # Decrease the counter to 0
    for i in [0...10]
      @_countDown.decreaseCounter()

# Start everything by creating an object of type CountDownInformer
informer = new HG.CountDownInformer
"""
