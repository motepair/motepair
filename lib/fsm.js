var machina = require('machina');

module.exports = machina.Fsm.extend( {

  namespace : 'remote',

  initialState : "localChanging",

  states : {
    remoteFileChanging: {
      saveFile: function(event, atom){
        atom.workspace.getPaneItems().forEach(function(item){
          if(item.getPath().indexOf(event.path) >= 0){
            item.save()
          }
        });
      },
      closeFile: function(event, atom){
        var closedItem = null

        atom.workspace.getPaneItems().forEach(function(item){
          if(item.getPath().indexOf(event.path) >= 0){
            closedItem = item
          }
        });

        var activePane = atom.workspace.getActivePane()

        activePane.destroyItem(closedItem)
      },
      changeFile: function(event, atom){
        var path = atom.project.getPaths()[0] + '/' + event.path;
        atom.workspace.open(path)
      }
    },

    localChanging : {
      localChange: function(atom, editor, event){
        this.ws.write('change', {
          file: atom.project.relativize(editor.getPath()),
          change: event
        })
      },
      fileAction: function(event, path){
        this.ws.write(event, {path: path})
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
      localSelection: function(atom, editor, event){
        this.ws.write('selection', {
          file: atom.project.relativize(editor.getPath()),
          range: event.newBufferRange
        })
      },
      fileAction: function(event, path){
        this.ws.write(event, {path: path})
      }
    },

    remoteSelecting : {
      remoteSelection: function(editor, event){
        editor.setSelectedBufferRange(event.range)
      }
    }
  }
} );
