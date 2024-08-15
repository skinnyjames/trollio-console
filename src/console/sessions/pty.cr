# {% unless flag?(:windows) %}
#   require "./posix/pty"
# {% else %}
#   raise "OS Not supported!"
# {% end %}
# 
require "./posix/pty"