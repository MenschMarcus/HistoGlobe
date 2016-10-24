window.HG ?= {}

# ============================================================================
# node in a tree for setting up hierarchical structure of holes in polygons
# N.B.: input must be HG.Polyline - not Polygon!
# ============================================================================

class HG.WithinTreeNode

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  constructor: (@_id, @_polyline) ->
    # error handling: except for the ROOT node (contains all) each geometry must be a HG.Polyline
    if (not (@_polyline instanceof HG.Polyline) and @_id isnt 'ROOT')
      return console.error "The geometry of a WithinTreeNode must be a HG.Polyline"

    @_parent = null
    @_children = []

  # ============================================================================
  getId: () ->              @_id
  getPolyline: () ->        @_polyline

  # ----------------------------------------------------------------------------
  setParent: (nodeId) ->    @_parent = nodeId
  getParent: () ->          @_parent

  # ----------------------------------------------------------------------------
  addChild: (nodeId) ->     @_children.push nodeId
  removeChild: (nodeId) ->  @_children.splice((@_children.indexOf nodeId), 1)

  # ----------------------------------------------------------------------------
  getChildren: () ->        @_children