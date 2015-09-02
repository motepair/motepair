EventHandler = require '../lib/event_handler.coffee'
WebSocket    = require 'ws'
{TextEditor} = require 'atom'

describe "EventHandler", ->

  beforeEach ->
    @ws = new WebSocket("http://localhost:3000")
    @event_handler = new EventHandler(@ws)
    @event_handler.listen()

  describe "Remote callbacks", ->
    describe "::onopen", ->
      beforeEach ->
        atom.config.set('motepair.syncTabs', true)
      afterEach ->
        atom.config.set('motepair.syncTabs', false)

      it "should call onopen method", ->
        spyOn(@event_handler, 'onopen')

        data = { a: 'meta', type:'open', data: { file: "lib/main.coffee" } }
        @ws.emit 'message', JSON.stringify data
        expect(@event_handler.onopen).toHaveBeenCalled()

      it "should open the file", ->
        spyOn(@event_handler.workspace, 'open').andCallThrough()

        data = { a: 'meta', type:'open', data: { file: "lib/main.coffee" } }
        @ws.emit 'message', JSON.stringify data
        expect(@event_handler.workspace.open).toHaveBeenCalled()

      it "should receive the file path correctly", ->
        root_path = "/home/user/project"
        @event_handler.projectPath = root_path
        spyOn(@event_handler.workspace, 'open').andCallThrough()

        data = { a: 'meta', type:'open', data: { file: "lib/main.coffee" } }
        @ws.emit 'message', JSON.stringify data
        expect(@event_handler.workspace.open).toHaveBeenCalledWith("#{root_path}/lib/main.coffee")

    describe "::onclose", ->
      beforeEach ->
        atom.config.set('motepair.syncTabs', true)
      afterEach ->
        atom.config.set('motepair.syncTabs', false)

      it "should call onclose method", ->
        spyOn(@event_handler, 'onclose')

        data = { a: 'meta', type:'close', data: { file: "lib/main.coffee" } }
        @ws.emit 'message', JSON.stringify data
        expect(@event_handler.onclose).toHaveBeenCalled()

      it "should close the file", ->
        pane = jasmine.createSpyObj('pane', ['destroyItem'])
        spyOn(@event_handler.workspace, 'getActivePane').andReturn(pane)

        data = { a: 'meta', type:'close', data: { file: "lib/main.coffee" } }
        @ws.emit 'message', JSON.stringify data
        expect(pane.destroyItem).toHaveBeenCalled()

    describe "::onsave", ->
      it "should save the file", ->
        pane = jasmine.createSpyObj('pane', ['save'])
        pane.getPath = ->
          return "lib/main.coffee"

        spyOn(@event_handler.workspace, 'getPaneItems').andReturn([pane])

        data = { a: 'meta', type:'save', data: { file: "lib/main.coffee" } }
        @ws.emit 'message', JSON.stringify data

        expect(pane.save).toHaveBeenCalled()

  describe "Local callbacks", ->

    beforeEach ->
      spyOn(@event_handler.project, 'relativize').andReturn('lib/main.coffee')
      spyOn(@ws, 'send')

      @event = jasmine.createSpyObj(event, ['uri', 'path', 'item', 'getPath'])

      @event_handler.projectPath = '/home/user/project'
      @event.uri = '/home/user/project/lib/main.coffee'

    describe "::onWillDestroyPaneItem", ->
      it "should send the proper data through the socket", ->
        @event.item.getPath = -> return "lib/main.coffee"
        @event.item.detachShareJsDoc = ->

        data = { a: 'meta', type:'close', data: { file: 'lib/main.coffee' } }

        @event_handler.workspace.paneContainer.emitter.emit 'will-destroy-pane-item', @event

        expect(@ws.send).toHaveBeenCalledWith(JSON.stringify(data))

      it "should not send untitled", ->
        @event.item.getPath = null

        @event_handler.workspace.paneContainer.emitter.emit 'will-destroy-pane-item', @event

        expect(@ws.send).not.toHaveBeenCalled()

      it "should not send atom config tabs", ->
        @event.item.getPath = -> return undefined

        @event_handler.workspace.paneContainer.emitter.emit 'will-destroy-pane-item', @event

        expect(@ws.send).not.toHaveBeenCalled()

    describe "::onDidChangeActivePaneItem", ->
      it "should send the proper data through the socket", ->
        @event.getPath = -> return '/home/user/project/lib/main.coffee'

        data = { a: 'meta', type:'open', data: { file: 'lib/main.coffee' } }

        @event_handler.workspace.paneContainer.emitter.emit 'did-change-active-pane-item', @event

        expect(@ws.send).toHaveBeenCalledWith(JSON.stringify(data))

      it "should return if not event is passed", ->
        @event_handler.workspace.paneContainer.emitter.emit 'did-change-active-pane-item'

        expect(@ws.send).not.toHaveBeenCalled()

      it "should not send atom config tabs", ->
        @event.getPath = null

        @event_handler.workspace.paneContainer.emitter.emit 'did-change-active-pane-item', @event

        expect(@ws.send).not.toHaveBeenCalled()

      it "should not send untitled", ->
        @event.getPath = -> return undefined

        @event_handler.workspace.paneContainer.emitter.emit 'did-change-active-pane-item', @event

        expect(@ws.send).not.toHaveBeenCalled()

      it "should not outside project files", ->
        @event.getPath = -> return '/etc/hosts'

        @event_handler.workspace.paneContainer.emitter.emit 'did-change-active-pane-item', @event

        expect(@ws.send).not.toHaveBeenCalled()
