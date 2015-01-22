EventHandler = require '../lib/event_handler.coffee'
WebSocket    = require('ws')

describe "EventHandler", ->

  beforeEach ->
    @ws = new WebSocket("http://localhost:3000")
    @event_handler = new EventHandler(@ws)
    @event_handler.listen()

  describe "onopen", ->
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
      spyOn(@event_handler.project, 'getPaths').andReturn([root_path])
      spyOn(@event_handler.workspace, 'open').andCallThrough()

      data = { a: 'meta', type:'open', data: { file: "lib/main.coffee" } }
      @ws.emit 'message', JSON.stringify data
      expect(@event_handler.workspace.open).toHaveBeenCalledWith("#{root_path}/lib/main.coffee")

  describe "onclose", ->
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

  describe "onsave", ->
    it "should save the file", ->
      pane = jasmine.createSpyObj('pane', ['save'])
      pane.getPath = ->
        return "lib/main.coffee"

      spyOn(@event_handler.workspace, 'getPaneItems').andReturn([pane])

      data = { a: 'meta', type:'save', data: { file: "lib/main.coffee" } }
      @ws.emit 'message', JSON.stringify data

      expect(pane.save).toHaveBeenCalled()





