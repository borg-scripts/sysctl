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

module.exports = ->
  @then @inject_flow => # allow all @define to be evaluated before entering here
    return unless @server.sysctl?.params
    
    @then @log "setting sysctl parameters..."
    for key, value in flatten @server.sysctl.params
      # remove any lines referring to the same key; this prevents duplicates
      @then @execute "sed -i '/^#{key}/d' /etc/sysctl.conf", sudo: true

      # append ip and hostnames
      @then @execute "echo #{key} = #{value} | sudo tee -a /etc/sysctl.conf >/dev/null"

    # reload sysctl.conf
    @then @execute "sysctl -q -p /etc/sysctl.conf", sudo: true
