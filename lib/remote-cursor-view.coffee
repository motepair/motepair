{Point} = require 'atom'
{View} = require 'atom-space-pen-views'

class RemoteCursorView extends View

  initialize: (@editor) ->
    @marker = @editor.markBufferPosition [0,0]
    @decoration = @editor.decorateMarker @marker,
      type: 'overlay',
      item: this,
      position: 'head'

    @lineHeightInPixels = @editor.getLineHeightInPixels()

    @height @lineHeightInPixels

    @setCursorPosition({row: 0, column: 0})

  setCursorPosition: (newPosition) ->
    position = Point.fromObject(newPosition)
    pixelPosition = @editor.pixelPositionForScreenPosition(position, true)
    itemHeight    = @element.offsetHeight
    top           = pixelPosition.top + @lineHeightInPixels

    if top + itemHeight - @editor.getScrollTop() > @editor.getHeight() and
       top - itemHeight - @lineHeightInPixels >= @editor.getScrollTop()
      @css transform: 'translate(0, 100%)'
    else
      @css transform: 'translate(0, -100%)'

    @marker.setHeadBufferPosition position

  @content: ->
    @div class: 'mp-cursor'

module.exports = RemoteCursorView
