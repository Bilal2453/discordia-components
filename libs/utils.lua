local utils = {}

function utils.errorf(err, lvl, ...)
  if select('#', ...) > 0 then
    error(err:format(...), lvl)
  else
    error(err, lvl)
  end
end

return utils
