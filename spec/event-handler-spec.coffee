EventHandler = require '../lib/event_handler.coffee'
WebSocket    = require('ws');

describe "EventHandler", ->

  beforeEach ->
    @ws = new WebSocket("http://localhost:3000")
    @event_handler = new EventHandler(@ws)
    @event_handler.listen()
    console.log( "sdafdsf" )

  describe "onopen", ->
    it "should open the given file", ->
      data = { a: 'meta', type:'open', data: { file: "lib/main.coffee" } }
      @ws.emit 'message', JSON.stringify data
