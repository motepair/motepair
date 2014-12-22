{Emitter} = require 'event-kit'
io = require('socket.io-client')

module.exports =
  activate: ->
    @localChange = true
    @emitter = new Emitter
    @socket = io.connect('http://localhost:3000', {reconnect: true})

    @socket.on 'connect', (socket) ->
      console.log('Connected!')

    @socket.on 'change', (event) =>
      editors = atom.workspace.getTextEditors()
      for editor in editors
        if editor.getTitle() is event.file
          buffer = editor.getBuffer()
          args = event.patch

          @localChange = false
          if args.oldText.length > 0 and args.newText.length is 0
            buffer.delete(args.oldRange)
          else if args.oldText.length > 0 and args.newText.length > 0
            buffer.delete(args.oldRange)
            buffer.insert(args.newRange.start, args.newText)
          else if args.oldText.length is 0 and args.newText.length > 0
            buffer.insert(args.newRange.start, args.newText)


    atom.workspace.observeTextEditors (editor) =>

      buffer = editor.getBuffer()
      @old = buffer.getText()

      editor.onWillInsertText (event) =>
        @old = buffer.getText()
        @localChange = true

      buffer.onDidChange (event) =>
        if @localChange
          console.log(event)
          newBuffer = buffer.getText()
          @socket.emit 'change', { file: editor.getTitle(), patch: event }

          @old = buffer.getText()

