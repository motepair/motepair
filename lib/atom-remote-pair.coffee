{Emitter} = require 'event-kit'
WsEmitClient = require('./ws/ws-emit-client.js')

module.exports =

  activate: ->
    atom.workspaceView.command "remote-pair:action", => @action()
    @project = atom.project
    @localChange = true
    @localSelection = false
    @localOpening = true

    @ws = new WsEmitClient('ws://localhost:3000')

    @ws.on 'open', ->
      console.log('Connected!')

    @ws.on 'save-file', (event) => @remoteSaveFile(event)

    @ws.on 'close-file', (event) => @remoteCloseFile(event)

    @ws.on 'change-file', (event) => @remoteOpenFile(event)

    @ws.on 'open-file', (event) => @remoteOpenFile(event)

    @ws.on 'change', (event) => @remoteChange(event)

    @ws.on 'selection', (event) => @remoteSelection(event)
    
    atom.workspace.observeTextEditors (editor) => @setupEditorObservers(editor)

    atom.workspace.onDidOpen (event) => @localOpenDestroyChange('open-file', event.uri)

    atom.workspace.onWillDestroyPaneItem (event) => @localOpenDestroyChange('close-file', event.item.getPath())

    atom.workspace.onDidChangeActivePaneItem (event) => @localOpenDestroyChange('change-file', event.getPath())
    
  remoteSaveFile: (event) ->
    @localSave = false
    for item in atom.workspace.getPaneItems() when item.getPath().indexOf(event.path) >= 0
      item.save()

  remoteOpenFile: (event) ->
    @localOpening = false
    atom.workspace.open("#{@project.getPaths()[0]}/#{event.path}")

  remoteCloseFile: (event) ->
    @localOpening = false
    closedItem = null

    for item in atom.workspace.getPaneItems() when item.getPath().indexOf(event.path) >= 0
      closedItem = item

    activePane = atom.workspace.getActivePane() 

    activePane.destroyItem(closedItem)

  remoteChange: (event) ->
    console.log("remote change", event)

    editors = atom.workspace.getTextEditors()

    for editor in editors when editor.getTitle() is event.file
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

      editor.getSelections()[0].clear()

  remoteSelection: (event) ->
    editors = atom.workspace.getTextEditors()

    for editor in editors when editor.getTitle() is event.file
      @localSelection = false
      editor.setSelectedBufferRange(event.range)
      @localSelection = true

  localOpenDestroyChange: (event, path) ->
    if @localOpening
        @ws.write event, {path: @project.relativize(path)}

      @localOpening = true
  setupEditorObservers: (editor) ->
    editor.onDidSave (event) =>
      if @localSave
        @ws.write 'save-file', {path: @project.relativize(event.path)}

      @localSave = true

    editor.onDidChangeCursorPosition (event) =>
      @localSelection = !event.textChanged

    editor.onDidChangeSelectionRange (event) =>
      if @localSelection
        @ws.write 'selection', { file: editor.getTitle(), range: event.newBufferRange }

    editor.onWillInsertText (event) =>
      @localSelection = false
      @old = buffer.getText()
      @localChange = true

    buffer = editor.getBuffer()
    @old = buffer.getText()

    buffer.onDidChange (event) =>
      if @localChange
        @localSelection = false
        console.log("local change", event)
        newBuffer = buffer.getText()
        @ws.write 'change', { file: editor.getTitle(), patch: event }
        @old = buffer.getText()


  


