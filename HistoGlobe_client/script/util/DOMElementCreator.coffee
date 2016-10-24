window.HG ?= {}

class HG.DOMElementCreator

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: () ->

  # ============================================================================
  # e.g. <i>, <span>, <
  create: (elemType=null, id=null, classes=[], attributes=[]) ->

    # error handling: element type must be given
    return if not elemType

    # error handling: if only one class as string given, make it an array
    classes = [classes] if typeof classes is 'string'

    elem = document.createElement elemType              # creates element
    elem.id = id if id                                  # sets id
    elem.classList.add c for c in classes               # adds all classes
    elem.setAttribute a[0], a[1] for a in attributes    # adds all attributes + values

    elem