-- mpv's sub-blur softens the subtitle border, or the letters themselves when
-- there's no border. Keep it to the border: with no border the blur is held
-- back (and remembered), and it comes back with the border.
local border_blur = {}

function border_blur.new(args)
  local mp = args.mp
  local service = {held = nil}

  local function sync()
    local border = mp.get_property_number("sub-outline-size", 0) or 0
    local blur = mp.get_property_number("sub-blur", 0) or 0
    if border <= 0 and blur > 0 then
      service.held = blur
      mp.set_property_number("sub-blur", 0)
    elseif border > 0 and service.held then
      local held = service.held
      service.held = nil
      if blur == 0 then mp.set_property_number("sub-blur", held) end
    end
  end
  mp.observe_property("sub-outline-size", "number", sync)
  mp.observe_property("sub-blur", "number", sync)

  -- the blur that applies with a border, even while it's held back
  function service:value(current)
    return self.held or current
  end

  return service
end

return border_blur
