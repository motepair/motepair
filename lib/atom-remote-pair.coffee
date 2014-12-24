{Emitter} = require 'event-kit'
WebSocket = require('ws')

module.exports =
  activate: ->
    @localChange = true
    @emitter = new Emitter
    @ws = new WebSocket('ws://localhost:4444')

    @ws.on 'open', ->
      console.log('Connected!')

    @ws.on 'message', (data) =>
      event = JSON.parse(data)
      if event.session?
        console.log("Session code received: " + event.session)
        @uid = event.session
      else
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
          data = JSON.stringify({ sessionToken: @uid, file: editor.getTitle(), patch: event })
          @ws.send(data)

          @old = buffer.getText()
