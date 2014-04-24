_ = require 'lodash'
oauth2orize = require 'oauth2orize'
fibrous = require 'fibrous'
ensureLogin = require 'connect-ensure-login'
passport = require('passport')
util = require './util.coffee'



class Provider

  @uid = util.uid

  defaultRenderFunction = (req, res)->
    res.render('dialog', { transactionID: req.oauth2.transactionID, user: req.user, client: req.oauth2.client })



  constructor: (config)->
    ## normalize parameters
    throw new Error 'Your argument is invalid: need config object' unless config?
    @renderFunction = config.renderFunction or defaultRenderFunction


    ## init oauth server
    @server = oauth2orize.createServer()

    ## register serialize/deserialize functions (easier for inheritance)
    @server.serializeClient ()=>
      @serialize arguments...

    @server.deserializeClient ()=>
      @deserialize arguments...

    ## register grant code
    @server.grant oauth2orize.grant.code (client, redirectURI, user, ares, done)=>
      @issueGrantCode client, redirectURI, user, ares, done

    ## grant implicit token
    @server.grant oauth2orize.grant.token (client, user, ares, done)=>
      @issueImplicitToken client, user, ares, done

    ## exchange grant for access token
    @server.exchange oauth2orize.exchange.code (client, code, redirectURI, done)=>
      @exchangeCodeForToken client, code, redirectURI, done

    ## exchange id/password for access token
    @server.exchange oauth2orize.exchange.password (client, username, password, scope, done)=>
      @exchangePasswordForToken client, username, password, scope, done

  authorization: ->
    [
      ensureLogin.ensureLoggedIn()
      @server.authorization (clientId, redirectURI, done)=> @findClient clientId, redirectURI, done
      @renderFunction
    ]

  decision: ->
    [
      ensureLogin.ensureLoggedIn()
      @server.decision()
    ]

  token: ->
    [
      passport.authenticate(@exchangeMethods, { session: false }),
      @server.token(),
      @server.errorHandler()
    ]

module.exports = Provider