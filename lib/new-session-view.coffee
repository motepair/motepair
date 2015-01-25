{View, EditorView} = require 'atom'
crypto = require 'crypto'

module.exports =
  
class NewSessionView extends View

  initialize: ->
    @miniEditor.setText(crypto.randomBytes(8).toString('hex'))
    @miniEditor.focus()

    @on 'core:confirm', =>
      @detach()

  @content: ->
    @div class: 'firepad overlay from-top mini', =>
      @p 'Session ID'
      @subview 'miniEditor', new EditorView(mini: true)
      @div 'Enter a string to identify this share session'

  show: ->
    # editorView = new NewSessionView
    atom.workspaceView.append(this)
    @miniEditor.focus()
