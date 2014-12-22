{Emitter} = require 'event-kit'
jsDiff = require 'diff'
io = require('socket.io-client')

module.exports =
  activate: ->
    @remoteChange = false
    @emitter = new Emitter
    @socket = io.connect('http://localhost:3000', {reconnect: true})

    @socket.on 'connect', (socket) ->
      console.log('Connected!')

    @socket.on 'change', (event) =>
      editors = atom.workspace.getTextEditors()
      # console.log("event", event)
      for editor in editors
        if editor.getTitle() is event.file
          buffer = editor.getBuffer()
          patched = jsDiff.applyPatch(buffer.getText(), event.patch)

          if patched isnt false
            buffer.setText(patched)
            # buffer.save()
          else
            console.log("Deu erro no patch")
            console.log(buffer.getText())
            console.log(event.patch)

          @remoteChange = true

    atom.workspace.observeTextEditors (editor) =>

      buffer = editor.getBuffer()
      @old = buffer.getText();

      editor.onWillInsertText (event) =>
        @old = buffer.getText();
        @remoteChange = false

      buffer.onDidChange (event) =>
        unless @remoteChange
          newBuffer = buffer.getText();
          patch = jsDiff.createPatch(editor.getTitle(), @old, newBuffer)
          @socket.emit 'change', { file: editor.getTitle(), patch: patch }

          @old = buffer.getText()

        @remoteChange = false
