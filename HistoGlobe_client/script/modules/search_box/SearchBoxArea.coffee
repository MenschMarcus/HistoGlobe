window.HG ?= {}

class HG.SearchBoxArea

  ##############################################################################
  #                            PUBLIC INTERFACE                                #
  ##############################################################################

  constructor: (config) ->

    HG.mixin @, HG.CallbackContainer
    HG.CallbackContainer.call @

    @addCallback "onSearchBoxChanged"

    @props =
      active: false
      height: 0

    window.list_items = []
    window.mouse_hover_active = true
    window.current_active_element = -1

  # ============================================================================

  hgInit: (@_hgInstance) ->
    @_hgInstance.searchBoxArea = @

    @_container = document.createElement 'div'
    @_container.className = "search-box-area"
    @_hgInstance.getTopArea().appendChild @_container
    @_allTopics = @_hgInstance.timeline._config.topics

    @_hgInstance.hg_logo = @

    @_logo_container = document.createElement 'div'
    @_logo_container.className = "logo-area"
    @_hgInstance.getTopArea().appendChild @_logo_container

    @_search_results = null
    @_search_opt_event = false
    @_search_opt_place = false
    @_search_opt_person = false
    @_search_opt_year = false
    @_input_text = null


    @_hgInstance.onAllModulesLoaded @, () =>
      @_hgInstance.hivent_list_module?.onHiventListChanged @, (list_props) =>
        if @props.active
          if list_props.active
            @props.height = (window.innerHeight - 190 - 53)
          else
            @props.height = (window.innerHeight - 190)
        # console.log "SB" + @props.active
        $(@_search_results).css({'max-height': (@props.height) + "px"}) # max height of list with timelin height

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # handle key up and down on list to highlight the different items
    # 1. if up and down is pressed dehighlight all items
    # 2. get index of new element (next, prev, first or last)
    # 3. set element at index to highlighted
    # 4. scroll to element

    $(window).mousemove (e) =>
      window.mouse_hover_active = true
      for item, index in window.list_items
        if index != window.current_active_element
          $("#" + item + " > li").removeClass("itemhover_list")

    $(window).keyup (e) =>
      if e.which is 40 or e.which is 38
        window.mouse_hover_active = false
      if window.list_items[window.current_active_element]? and (e.which is 40 or e.which is 38)
        $("#" + window.list_items[window.current_active_element] + " > li").removeClass("itemhover_list")
      if e.which is 40 # down
        if window.current_active_element is window.list_items.length - 1
          window.current_active_element = 0
        else
          window.current_active_element++
      if e.which is 38 # up
        if window.current_active_element is -1 or window.current_active_element is 0
          window.current_active_element = window.list_items.length - 1
        else
          window.current_active_element--

      $("#" + window.list_items[window.current_active_element] + " > li").addClass("itemhover_list")

      sr = document.getElementById("search-results")
      if(sr.scrollTop > window.current_active_element * 44)
        sr.scrollTop = window.current_active_element * 44
      else if(sr.scrollTop + sr.offsetHeight < (window.current_active_element * 44) + 50)
        sr.scrollTop = (window.current_active_element * 44) - sr.offsetHeight + 150
        #$("#search-results").animate({ scrollTop: (window.current_active_element * 43) + "px" });

  # ============================================================================

  addLogo: (config) ->
    @_addLogo config

  addSearchBox: (config) ->
    @_addSearchBox config

  ##############################################################################
  #                            PRIVATE INTERFACE                               #
  ##############################################################################

  # ============================================================================
  _addLogo: () ->

    logo = document.createElement 'div'
    logo.className = "logo"
    logo.innerHTML = '<img class = "hg-logo" src = "data/png/logo-normal-farbe.png">';
    @_logo_container.appendChild logo

    return logo

  # ============================================================================
  _addSearchBox: () ->

    box = document.createElement 'div'
    box.className = "search-box"

    form = document.createElement "form"
    form.className = "search-form"

    box.appendChild form

    # Input =======================================================================
    input = document.createElement "input"
    input.type = "text"
    input.placeholder = "Suchbegriff eingeben"
    input.id = "search-input"
    input.autocomplete = "off"
    form.appendChild input

    # Clear Icon ==================================================================
    clear = document.createElement 'div'
    clear.className = "clear"
    clear.innerHTML = '<span>x</span>' #'<i class="fa fa-times"></i>'
    form.appendChild clear
    $(clear).hide()

    # Search Icon =================================================================
    icon = document.createElement 'div'
    icon.className = "search-icon"
    icon.innerHTML = '<i class="fa fa-search"></i>'
    form.appendChild icon
    $(icon).show()

    # add options if input is clicked
    # $(input).click () =>
    #   box.appendChild options
    #   options.appendChild selection

    # remove options if input is not clicked
    # $(document).click (e) ->
    #   if $(e.target).closest(input).length is 0
    #     options.removeChild selection
    #     box.removeChild options

    # Options =====================================================================
    # options = document.createElement 'div'
    # options.id = "options"
    # options.innerHTML = '<span class="msg">Was möchtest du finden?</span>'

    # selection = document.createElement "form"
    # selection.className = "selection"
    # selection.innerHTML = '<input type="checkbox" name="search_option" value="Ereignisse"/>Ereignisse
    #                        <input type="checkbox" name="search_option" value="Orte"/>Orte
    #                        <input type="checkbox" name="search_option" value="Personen"/>Personen
    #                        <input type="checkbox" name="search_option" value="Jahr"/>Jahr'

    # Results =====================================================================
    $(input).keyup () =>
      @_input_text = document.getElementById("search-input").value
      @_input_text = @_input_text.toLowerCase()
      #options_input = document.getElementsByName("search_option")

      # if options_input?
      #   @_search_opt_event = options_input[0].checked
      #   @_search_opt_place = options_input[1].checked
      #   @_search_opt_person = options_input[2].checked
      #   @_search_opt_year = options_input[3].checked

      if !@_search_results?
        @_search_results = document.createElement 'div'
        @_search_results.id = "search-results"

      curr_category = @_hgInstance.categoryFilter._categoryFilter[0]

      result_list = []
      epoch_result_list = []
      window.list_items = []

      found_in_location = false
      if @_hgInstance.hiventController._hiventHandles
        for hivent in @_hgInstance.hiventController._hiventHandles
          if hivent._hivent.startYear <= @_input_text && hivent._hivent.endYear >= @_input_text
            if curr_category == hivent._hivent.category
              epoch_result_list.push hivent._hivent
              continue
            else
              result_list.push hivent._hivent
              continue

          for location in hivent._hivent.locationName
            if location.toLowerCase() == @_input_text
              if curr_category == hivent._hivent.category
                epoch_result_list.push hivent._hivent
                found_in_location = true
                continue
              else
                result_list.push hivent._hivent
                found_in_location = true
                continue

          if found_in_location
            continue

          if hivent._hivent.description.toLowerCase().indexOf(@_input_text) > -1
            if curr_category == hivent._hivent.category
              epoch_result_list.push hivent._hivent
              continue
            else
              result_list.push hivent._hivent
              continue

          if hivent._hivent.name.toLowerCase().indexOf(@_input_text) > -1
            if curr_category == hivent._hivent.category
              epoch_result_list.push hivent._hivent
              continue
            else
              result_list.push hivent._hivent
              continue

      live_ticker = 0
      epoch_search_output = ''
      for epoch_result in epoch_result_list

        yearString = ''
        if epoch_result.startYear == epoch_result.endYear
          yearString = epoch_result.startYear
        else
          yearString = epoch_result.startYear + ' bis ' + epoch_result.endYear

        window.list_items.push epoch_result.id
        epoch_search_output = epoch_search_output + '<a onmouseout="if(window.mouse_hover_active) { this.firstChild.className = \'\'; window.current_active_element = -1; }" onmouseover="if(window.mouse_hover_active) { this.firstChild.className = \'itemhover_list\'; window.current_active_element = ' + live_ticker + '; }" id="' + epoch_result.id + '" href="#categories=' + epoch_result.category + '&event=' + epoch_result.id + '"><li>' +
        '<div class="wrap"><div class="res_name">' + epoch_result.name + '</div>' +
        '<div class="res_location">' + epoch_result.locationName[0] + '</div><div class="res_year">' + yearString + '</div></div><i class="fa fa-map-marker"></i></li></a>'
        live_ticker++

      search_output = ''
      for result in result_list

        yearString = ''
        if result.startYear == result.endYear
          yearString = result.startYear
        else
          yearString = result.startYear + ' bis ' + result.endYear

        window.list_items.push result.id
        search_output = search_output + '<a onmouseout="if(window.mouse_hover_active) { this.firstChild.className = \'\'; window.current_active_element = -1; }" onmouseover="if(window.mouse_hover_active) { this.firstChild.className = \'itemhover_list\'; window.current_active_element = ' + live_ticker + '; }" id="' + result.id + '" href="#categories=' + result.category + '&event=' + result.id + '"><li>' +
        '<div class="wrap"><div class="res_name">' + result.name + '</div>' +
        '<div class="res_location">' + result.locationName[0] + '</div><div class="res_year">' + yearString + '</div></div><i class="fa fa-map-marker"></i></li></a>'
        live_ticker++

      aktualleCath = ""

      for topic in @_allTopics
        if topic.id == @_hgInstance.categoryFilter.getCurrentFilter()[0]
          aktualleCath = topic.name

      search_result_with_categ_einteilung = ''
      if epoch_search_output.length > 0
        search_result_with_categ_einteilung = '<span>Suchergebnisse in "' + aktualleCath + '": </span></br><ul>' +
        epoch_search_output + '</ul>'

      if epoch_search_output.length > 0 &&  search_output.length > 0
        search_result_with_categ_einteilung = search_result_with_categ_einteilung + '<br>'

      if search_output.length > 0
        search_result_with_categ_einteilung = search_result_with_categ_einteilung +
        '<span>Suchergebnisse in anderen Epochen: </span></br><ul>' + search_output + '</ul>'

      @_search_results.innerHTML = search_result_with_categ_einteilung

      form.appendChild @_search_results

      # calc height
      if @_hgInstance.hivent_list_module.props.active
        @props.height = (window.innerHeight - 190 - 53)
      else
        @props.height = (window.innerHeight - 190)

      $(@_search_results).css({'max-height': (@props.height) + "px"}) # max height of list with timelin height

    #=============================================================================
      if @_input_text?
        #form.appendChild clear # add clear icon
        $(clear).show()
        $(icon).hide()
      else
        #form.removeChild clear # remove clear icon
        $(clear).hide()
        $(icon).show()

      # remove results if input string is empty
      if @_input_text < 1
        form.removeChild @_search_results
        #form.removeChild clear
        $(clear).hide()
        $(icon).show()
        @props.active = false
        @notifyAll "onSearchBoxChanged", @props
      else
        @props.active = true
        @notifyAll "onSearchBoxChanged", @props

      $(clear).click () =>
        #form.removeChild clear
        $(clear).hide()
        $(icon).show()
        document.getElementById("search-input").value = "" #Clear input text
        form.removeChild @_search_results
        @props.active = false
        @notifyAll "onSearchBoxChanged", @props


    #=============================================================================
    #@notifyAll "onSearchBoxChanged", @props
    $(input).keyup (e) =>
      if e.which is 13  #Enter key pressed
        e.preventDefault()

    $(input).keydown (e) =>
      if e.which is 13  #Enter key pressed
        e.preventDefault()

    @_container.appendChild box

    return box
