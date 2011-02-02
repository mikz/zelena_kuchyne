# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_zelena_kuchyne_session',
  :secret      => 'bd2b7f255566dab2d7b92d86ad897055d4c06519f533fb0abeff385bed9365ebe1fd585d2f29b34a264a778b623300d7bc154feb5888e72fc1be8b3d0326e40d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
