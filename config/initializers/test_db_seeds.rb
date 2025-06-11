# This initializer runs every time the Rails app starts,
# but only in the 'test' environment.

# Ensure the Rails application has fully initialized and models are loaded
# before attempting to interact with them.
Rails.application.config.after_initialize do
  if Rails.env.test?
    Language.find_or_create_by!(name: "English")
    Language.find_or_create_by!(name: "German")
    Language.find_or_create_by!(name: "Persian")
    Language.find_or_create_by!(name: "Italian")
    Language.find_or_create_by!(name: "Spanish")


  end
end