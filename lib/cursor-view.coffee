{View, Point} = require 'atom'

class CursorView extends View

  initialize: (@editor) ->
    @editor.onDidChangeCursorPosition (event) =>
      buffer = @editor.getBuffer()

      marker = buffer.markPosition [0,19]
      @decoration = @editor.decorateMarker marker,
        type: 'overlay',
        item: this,
        position: 'head'

    

  @content: ->
    @div class: 'mp-cursor'
      


module.exports =
  CursorView: CursorView