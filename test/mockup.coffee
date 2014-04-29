request = require 'request'

module.exports =
  data:
    users :
      'adw12asd23':
        username: 'admin'
        password: 'admin'
        name: 'Admin'
        id: 'adw12asd23'

    clients :
      'awesome-app':
        clientId: 'awesome-app'
        clientSecret: 'awesome-secret'
        redirectURI: 'http://awesome.com/callback'
        name: 'Awesome'

  config:
    PROVIDER_PORT: 19015 ## my employee number, yay!
    PROVIDER_BASEURL : "http://localhost:19015"

  methods:
    initApp : (provider) ->
      passport = require 'passport'
      app = require('express')()

      app.use require('cookie-parser')()
      app.use require('body-parser')()
      app.use require('express-session')({ secret: 'keyboard cat' })

      app.use passport.initialize()
      app.use passport.session()

      app.get "/dialog/authorize", provider.authorization()
      app.post "/dialog/authorize/decision", provider.decision()
      app.post "/oauth/token", provider.token()

      app.get '/api/me', passport.authenticate("bearer", session: false), (req, res)->
        res.json {name: 'correct'}


      app.post "/login", passport.authenticate "local",
        successReturnToOrRedirect: "/"
        failureRedirect: "/login"

      return app

    apiRequest:  (token, cb)->
      headers = {
        Authorization: "#{token.token_type} #{ token.access_token }"
      }

      request.get {
        uri: "#{module.exports.config.PROVIDER_BASEURL}/api/me"
        json: true
        headers,
      }, cb