{View, TextEditorView} = require 'atom-space-pen-views'
crypto = require 'crypto'

module.exports =

class NewSessionView extends View

  initialize: ->
    @miniEditor.setText(crypto.randomBytes(8).toString('hex'))
    @miniEditor.getModel().selectAll()
    @miniEditor.focus()

    atom.commands.add '.new-session-view',
      'core:confirm': => @detach()

    atom.commands.add '.new-session-view',
      'core:cancel': => @detach()

  @content: ->
    @div class: 'new-session-view overlay from-top mini', =>
      @p 'Session ID'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div 'Enter a string to identify this share session'

  show: ->
    workspaceView = atom.views.getView(atom.workspace)
    workspaceView.appendChild(@[0])
    @miniEditor.focus()
