// Generated by CoffeeScript 1.9.3
(function() {
  var publishSubscribe;

  publishSubscribe = {
    moduleName: "publishSubscribe",
    broadcast: function(ev, data) {
      var _callbackList;
      if (!this.hasOwnProperty('_callbacks')) {
        this._callbacks = {};
      }
      _callbackList = this._callbacks[ev];
      if (!this.hasOwnProperty('_callbacks') || !_callbackList) {
        return this;
      }
      _callbackList.forEach((function(_this) {
        return function(fn) {
          return fn.call(_this, data);
        };
      })(this));
      return this;
    },
    listen: function(ev, fn) {
      if (!this.hasOwnProperty('_callbacks')) {
        this._callbacks = {};
      }
      (this._callbacks[ev] || (this._callbacks[ev] = [])).push(fn);
      return this;
    },
    removeAllListenersOn: function(ev) {
      if (this._callbacks && this._callbacks[ev]) {
        return delete this._callbacks[ev];
      }
    }
  };

  module.exports = publishSubscribe;

}).call(this);