var WebSocket = require('ws');

module.exports = Socket

var EventEmitter = require('events').EventEmitter
var inherits = require('inherits')
var once = require('once')

inherits(Socket, EventEmitter)
var emit = WebSocket.super_.prototype.emit

function Socket (url) {
  this._init(url)
}

Socket.prototype.send = function (message, ack) {
  if (this._ws && this._ws.readyState === WebSocket.OPEN) {
    this._ws.send(message, ack)
  }
}


Socket.prototype.destroy = function (onclose) {
  if (onclose) this.once('close', onclose)
  try {
    this._ws.close()
  } catch (err) {
    this._onclose()
  }
}

Socket.prototype._init = function (url) {
  this._errored = false;
  this._ws = new WebSocket(url)
  this._ws.onopen = this._onopen.bind(this)
  this._ws.onmessage = this._onmessage.bind(this)
  this._ws.onclose = this._onclose.bind(this)
  this._ws.onerror = once(this._onerror.bind(this))
}

Socket.prototype._onopen = function () {
  this.emit("open");
}

Socket.prototype._onerror = function (err) {
  this._errored = true;
  this.destroy();
  this.emit("error", err)
}


Socket.prototype._onmessage = function (event) {
  var json = JSON.parse(event.data),
      event = json.type,
      data = json.data;

  emit.apply(this, [event, data])
}

Socket.prototype._onclose = function () {
  if (this._ws) {
    this._ws.onopen = null;
    this._ws.onerror = null;
    this._ws.onmessage = null;
    this._ws.onclose = null
  }

  this._ws = null;

  if (!this._errored) this.emit("close")
}

Socket.prototype.write = function(event, message) {
  var data = { event: event, data: message}
  this.send(JSON.stringify(data), function ack(err){
    if(err !== undefined){
      this._onerror({code: "ECONNNOTOPENED", errno: "ECONNNOTOPENED"})
    }
  }.bind(this));

}
