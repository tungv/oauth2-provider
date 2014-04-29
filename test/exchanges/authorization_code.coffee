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