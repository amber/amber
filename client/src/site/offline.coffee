class OfflineServer extends amber.util.Base
  @property 'app', apply: (app) ->
    if not @app.initialized
      @app.go location.hash.substr 1
      @app.initialized = true

@module 'amber.site', { OfflineServer }
