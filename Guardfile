# A sample Guardfile
# More info at https://github.com/guard/guard#readme

## Uncomment and set this to only include directories you want to watch
# directories %w(app lib config test spec feature)

## Uncomment to clear the screen before every task
# clearing :on

## Make Guard exit when config is changed so it can be restarted
#
## Note: if you want Guard to automatically start up again, run guard in a
## shell loop, e.g.:
#
#  $ while bundle exec guard; do echo "Restarting Guard..."; done
#
## Note: if you are using the `directories` clause above and you are not
## watching the project directory ('.'), the you will want to move the Guardfile
## to a watched dir and symlink it back, e.g.
#
#  $ mkdir config
#  $ mv Guardfile config/
#  $ ln -s config/Guardfile .
#
# and, you'll have to watch "config/Guardfile" instead of "Guardfile"
#
watch ("Guardfile") do
  UI.info "Exiting because Guard must be restarted for changes to take effect"
  exit 0
end

guard 'livereload', port: 9999, grace_period: 0.5 do
  watch(%r{app/views/.+\.(erb|haml|slim)$})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+))\.opalerb.*}) { |m| "/assets/#{m[3]}.js" }
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|js|html|png|jpg))).*}) { |m| "/assets/#{m[3]}" }
end

guard 'rails', timeout: 60, host: "0.0.0.0" do
  watch('Gemfile.lock')
  watch(%r{^(config|lib)/.*})
end