{Emitter} = require 'event-kit'
WsEmitClient = require('./ws/ws-emit-client.js')

module.exports =
  activate: ->
    @localChange = true
    @emitter = new Emitter
    @ws = new WsEmitClient('ws://localhost:3000')

    @ws.on 'open', ->
      console.log('Connected!')

    @ws.on 'change', (event) =>
      console.log("remote change", event)

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
          console.log("local change", event)
          newBuffer = buffer.getText()
          @ws.write 'change', { file: editor.getTitle(), patch: event }
          @old = buffer.getText()
