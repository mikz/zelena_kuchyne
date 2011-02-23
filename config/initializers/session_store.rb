# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_zelena_kuchyne_session',
  :secret      => '1f24eb3923fb15e4896d03d14459f73ae0066dd19c7f275bab402511dad2ed8ddfd96e694efb09ae2a4cce6c1afc7f9671c0c04aee358043f563c7af30ebc11d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
