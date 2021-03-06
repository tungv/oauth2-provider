_ = require 'lodash'
oauth2orize = require 'oauth2orize'
ensureLogin = require 'connect-ensure-login'
util = require './util.coffee'

initPassport = require './passport-middlewares.coffee'

passport = null

passby = (req, res, next) ->
  next()

class Provider

  @uid = util.uid

  defaultRenderFunction = (req, res)->
    console.log "render Function on abstract provider"
    res.render('dialog', { transactionID: req.oauth2.transactionID, user: req.user, client: req.oauth2.client })

  constructor: (config, deps)->
    ## normalize parameters
    throw  new Error 'Your argument is invalid: need config object' unless config?
    @renderFunction = config.renderFunction or defaultRenderFunction


    @passport = passport = deps.passport
    throw new Error 'passport instance must be provided' unless passport

    ## init oauth server
    @server = oauth2orize.createServer()

    ## register serialize/deserialize functions (easier for inheritance)
    @server.serializeClient ()=>
      @serializeClient arguments...

    @server.deserializeClient ()=>
      @deserializeClient arguments...

    ## register grant code
    @server.grant oauth2orize.grant.code (client, redirectURI, user, ares, done)=>
      @issueGrantCode client, redirectURI, user, ares, done

    ## grant implicit token
    @server.grant oauth2orize.grant.token (client, user, ares, done)=>
      @issueImplicitToken client, user, ares, done

    ## exchange grant for access token
    @server.exchange oauth2orize.exchange.code (client, code, redirectURI, done)=>
      @exchangeCodeForToken client, code, redirectURI, done

    ## exchange client credentials for access token
    @server.exchange oauth2orize.exchange.clientCredentials (client, scope, done)=>
      @exchangeClientCredentialsForToken client, scope, done

    ## exchange id/password for access token
    @server.exchange oauth2orize.exchange.password (client, username, password, scope, done)=>
      @exchangePasswordForToken client, username, password, scope, done

    ## init passport
    initPassport passport, this

  authorization: ->
    [
      ensureLogin.ensureLoggedIn()
      @server.authorization (clientId, redirectURI, done)=>
        @findClient clientId, redirectURI, done

      if typeof @autoApprove is 'function' then @autoApprove.bind(this) else passby
      @renderFunction.bind(this)
    ]

  decision: ->
    [
      ensureLogin.ensureLoggedIn()
      @server.decision()
    ]

  token: ->
    [
      passport.authenticate(@exchangeMethods or ['basic'], { session: false }),
      @server.token(),
      @server.errorHandler()
    ]

module.exports = Provider
