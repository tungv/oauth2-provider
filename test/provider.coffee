log4js = require 'log4js'
logger = log4js.getLogger 'test/provider'

chai = require 'chai'
should = chai.should()
expect = chai.expect

request = require 'request'

mockup = require './mockup.coffee'
InMemProvider = require '../example/in-memory/in-memory-provider.coffee'




describe 'Provider', ->
  describe 'Exchanges', ->
    ## mockup testing data
    provider = new InMemProvider
    provider.renderFunction = (req, res)->
      res.json { transactionID: req.oauth2.transactionID, user: req.user, client: req.oauth2.client }

    provider.db.user = mockup.data.users
    provider.db.client = mockup.data.clients

    ## init app
    app = mockup.methods.initApp provider
    app.listen mockup.config.PROVIDER_PORT
    logger.info "Test Provider started on port: #{mockup.config.PROVIDER_PORT}
                  - mode: #{app.get('env')}"



    require('./exchanges/client_credentials.coffee')(mockup)
    require('./exchanges/authorization_code.coffee')(mockup)




