mongoose = require 'mongoose'

schema = new mongoose.Schema {
  clientId: String
  clientSecret: String
  name: String
}

model = mongoose.model 'client',  schema