mongoose = require 'mongoose'

schema = new mongoose.Schema {
  code: String
  redirectURI: String
  client: String            ## client id
  user: String              ## user id
}


model = mongoose.model 'grant', schema