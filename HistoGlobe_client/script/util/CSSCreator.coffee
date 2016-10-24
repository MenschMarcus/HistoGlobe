window.HG ?= {}

# ==============================================================================
# Dynamically adds new css selector named by the value of "selector" with the
# properties defined in "stye" to the document's style.
# This is mainly used for dynamically adding classes for different Hivent icons.
# ==============================================================================
HG.createCSSSelector = (selector, style) ->

  unless document.styleSheets
    return

  if document.getElementsByTagName("head").length is 0
    return

  styleSheet = undefined
  mediaType = undefined
  # if document.styleSheets.length > 0
  #   for sheet in document.styleSheets
  #     unless sheet.disabled
  #       media = sheet.media
  #       mediaType = typeof media

  #       if mediaType is "string"
  #         if media is "" or (media.indexOf("screen") isnt -1)
  #           styleSheet = sheet

  #       else if mediaType is "object"
  #         if media.mediaText is "" or (media.mediaText.indexOf("screen") isnt -1)
  #           styleSheet = sheet

  #       if styleSheet?
  #         break

  unless styleSheet?
    styleSheetElement = document.createElement "style"
    styleSheetElement.type = "text/css"
    document.getElementsByTagName("head")[0].appendChild styleSheetElement

    for sheet in document.styleSheets
      unless sheet.disabled
        styleSheet = sheet

    media = styleSheet.media
    mediaType = typeof media

  if mediaType is "string"
    for rule in styleSheet.rules
      if rule.selectorText and rule.selectorText.toLowerCase() is selector.toLowerCase()
        rule.style.cssText = style
        return

      styleSheet.addRule selector, style

  else if mediaType is "object"
    for rule in styleSheet.cssRules
      if rule.selectorText and rule.selectorText.toLowerCase() is selector.toLowerCase()
        rule.style.cssText = style
        return

    styleSheet.insertRule(selector + "{" + style + "}", 0)
