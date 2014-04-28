chai = require 'chai'
should = chai.should()
expect = chai.expect
request = require 'request'
log4js = require 'log4js'
logger = log4js.getLogger 'test/provider'

InMemProvider = require '../example/in-memory/in-memory-provider.coffee'

users = {
  'adw12asd23': {
    username: 'admin'
    password: 'admin'
    name: 'Admin'
    id: 'adw12asd23'
  }
}
clients = {
  'awesome-app': {
    clientId: 'awesome-app'
    clientSecret: 'awesome-secret'
    redirectURI: 'http://awesome.com/callback'
    name: 'Awesome'
  }
}

initApp = (provider) ->
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

  app.post "/login", passport.authenticate "local",
    successReturnToOrRedirect: "/"
    failureRedirect: "/login"

  return app

describe 'Provider', ->
  describe 'Exchanges', ->
    PROVIDER_PORT = 19015 ## my employee number, yay!
    ## mockup testing data
    provider = new InMemProvider
    provider.db.user = users
    provider.db.client = clients

    ## init app
    app = initApp provider
    app.listen PROVIDER_PORT
    logger.info "Test Provider started on port: #{PROVIDER_PORT} - mode: #{app.get('env')}"

    ## request
    PROVIDER_BASEURL = "http://localhost:#{PROVIDER_PORT}"

    client = clients['awesome-app']
    user = users['adw12asd23']

    request = request.defaults {jar: true}

    ## make sure user has logged in
  #  before (done)->
  #    request.post {
  #      uri: "#{PROVIDER_BASEURL}/login"
  #      form:
  #        username: user.username
  #        password: user.password
  #    }, (err, r, body)->
  #      logger.debug 'body', body
  #      done()

    it 'should exchange client credentials for access token', (done)->
      query = {
        grant_type: 'client_credentials'
        client_id: client.clientId
        client_secret: client.clientSecret
        scope: '*'
      }

      request.post {
        uri: "#{PROVIDER_BASEURL}/oauth/token"
        json: query
      }, (err, resp, body)->
        resp.statusCode.should.equal 200
        body.access_token.should.be.a 'string'
        body.token_type.should.equal 'Bearer'
        done()


