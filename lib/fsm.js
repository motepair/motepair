var machina = require('machina');


module.exports = machina.Fsm.extend( {

  namespace : 'remote',

  initialState : "localChanging",

  states : {
    idle: {
      _onEnter: function(){
        this.localChange = false
        console.log("Funcionando corretamente.", this.localChange)
      }
    },

    localChanging : {
      _onEnter: function(){
        console.log("[FSM] LocalChaging")
      },
      localChange: function(editor, event){
        this.ws.write('change', { file: editor.getTitle(), patch: event })
      }
    },

    remoteChanging : {
      _onEnter: function(){
        console.log("[FSM] RemoteChaging")
      },
      remoteChange: function(editor, args){
        editor.getSelections()[0].clear()

        buffer = editor.getBuffer()

        if(args.oldText.length > 0 && args.newText.length === 0){
          buffer.delete(args.oldRange)
        }else if (args.oldText.length > 0 && args.newText.length > 0){
          buffer.delete(args.oldRange)
          buffer.insert(args.newRange.start, args.newText)
        }else if (args.oldText.length === 0 && args.newText.length > 0){
          buffer.insert(args.newRange.start, args.newText)
        }
      }
    },

    localSelecting : {
      _onEnter: function(){
        console.log("[FSM] LocalSelection")
      },
      localSelection: function(editor, event){
        this.ws.write('selection', { file: editor.getTitle(), range: event.newBufferRange })
      }
    },

    remoteSelecting : {
      _onEnter: function(){
        console.log("[FSM] RemoteSelection")
      },
      remoteSelection: function(editor, event){
        editor.setSelectedBufferRange(event.range)
      }
    }
  }
} );
