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
      localChange: function(editor, event){
        this.ws.write('change', { file: editor.getTitle(), patch: event })
      }
    },

    remoteChanging : {
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
      localSelection: function(editor, event){
        console.log("sending selection")
        this.ws.write('selection', { file: editor.getTitle(), range: event.newBufferRange })
      }
    },

    remoteSelecting : {
      remoteSelection: function(editor, event){
        editor.setSelectedBufferRange(event.range)
      }
    }
  }
} );
