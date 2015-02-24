{Point} = require 'atom'
{View} = require 'atom-space-pen-views'
crypto = require 'crypto'

class RemoteCursorView extends View

  initialize: (@editor, position, userEmail) ->
    @marker = @editor.markBufferPosition Point.fromObject(position)
    @decoration = @editor.decorateMarker @marker,
      type: 'overlay',
      item: this,
      position: 'head'

    @lineHeightInPixels = @editor.getLineHeightInPixels()

    @height @lineHeightInPixels

    @setCursorPosition(position)

    @setGravatar(userEmail, Math.round(1.5*@lineHeightInPixels))

  setCursorPosition: (newPosition) ->
    position      = Point.fromObject(newPosition)
    pixelPosition = @editor.pixelPositionForScreenPosition(position, true)
    itemHeight    = @element.offsetHeight
    top           = pixelPosition.top + @lineHeightInPixels

    if top + itemHeight - @editor.getScrollTop() > @editor.getHeight() and
       top - itemHeight - @lineHeightInPixels >= @editor.getScrollTop()
      @css transform: 'translate(0, 100%)'
    else
      @css transform: 'translate(0, -100%)'

    @marker.setHeadBufferPosition position

  setGravatar: (email, size) ->
    return unless email.length>0
    
    md5 = crypto.createHash('md5')
    emailHash = md5.update(email).digest('hex')
    @gravatar.attr src: "https://s.gravatar.com/avatar/#{emailHash}?s=#{size}"
    @gravatar.attr alt: email
    @gravatar.show()

  @content: ->
    @div class: 'mp-cursor', =>
      @img class: 'mp-gravatar', outlet: 'gravatar'

module.exports = RemoteCursorView
