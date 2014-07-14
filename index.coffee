module.exports = ->
  @then (cb) =>
    return cb() unless @server.sysctl?.params?
    @log "setting sysctl parameters..."
    flatten = (o) ->
      res = {}
      recurse = (obj, current) ->
        for own key, value of obj
          newKey = if current then "#{current}.#{key}" else key # join key with dot
          if typeof value is 'object'
            recurse value, newKey # it's a nested object, so do it again
          else
            res[newKey] = value # it's not an object, so set the property
      recurse o
      return res
    params = flatten @server.sysctl.params
    done = =>
      # reload sysctl.conf
      @execute "sysctl -q -p /etc/sysctl.conf", sudo: true, @mustExit 0, cb
    @each params, done, ([key, value], next) =>
      # remove any lines referring to the same key; this prevents duplicates
      @execute "sed -i '/^#{key}/d' /etc/sysctl.conf", sudo: true, =>
        # append ip and hostnames
        @execute "echo #{key} = #{value} | sudo tee -a /etc/sysctl.conf >/dev/null", @mustExit 0, next
