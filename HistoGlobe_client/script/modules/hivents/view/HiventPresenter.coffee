window.HG ?= {}

class HG.HiventPresenter

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  # ============================================================================
  hgInit: (hgInstance) ->
    hgInstance.hiventPresenter = @

    hgInstance.onAllModulesLoaded @, () =>
      @_timeline            = hgInstance.timeline
      @_hiventController    = hgInstance.hiventController
      @_hiventInfoPopovers  = hgInstance.hiventInfoPopovers

  # ============================================================================
  present: (id) ->
    if @_hiventController?
      @_hiventController.getHivents @, (handle) =>
        if handle.getHivent().id is id
          @_timeline.moveToDate handle.getHivent().date, 0.5
          @_hiventController.removeListener "onHiventAdded", @

    if @_hiventInfoPopovers?
      @_hiventInfoPopovers.getPopovers @, (marker) =>
        handle = marker.getHiventHandle()
        hivent = handle.getHivent()
        if hivent.id is id
          handle.focusAll()
          handle.activeAll()
          @_hiventInfoPopovers.removeListener "onPopoverAdded", @

