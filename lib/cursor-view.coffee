{View, Point} = require 'atom'

class CursorView extends View

  initialize: (@editor) ->
    @marker = @editor.markScreenPosition [0,0]
    @decoration = @editor.decorateMarker @marker,
      type: 'overlay',
      item: this,
      position: 'head'

    @lineHeightInPixels = @editor.getLineHeightInPixels()

    @height @lineHeightInPixels

    @editor.onDidChangeCursorPosition (event) => @setCursorPosition(event)

  setCursorPosition: (event) ->
    pixelPosition = @editor.pixelPositionForScreenPosition(event.newScreenPosition, true)
    itemHeight    = @element.offsetHeight
    top           = pixelPosition.top + @lineHeightInPixels

    if top + itemHeight - @editor.getScrollTop() > @editor.getHeight() and
       top - itemHeight - @lineHeightInPixels >= @editor.getScrollTop()
      @css transform: 'translate(0, 100%)'
    else
      @css transform: 'translate(0, -100%)'

    @marker.setHeadScreenPosition event.newScreenPosition

  @content: ->
    @div class: 'mp-cursor'

module.exports = CursorView
