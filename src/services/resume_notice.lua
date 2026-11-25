-- When mpv continues a file from a position saved with quit-watch-later,
-- briefly shows "Resumed at 12:34" and offers a Start over action.
local resume_notice = {}

-- seconds the Start over action stays available
local OFFER_SECONDS = 10

function resume_notice.new(args)
  local mp = args.mp
  local service = {}
  local pending, restarted, position, timer = false, false, nil, nil

  local function clear()
    if timer then timer:kill() end
    timer, position = nil, nil
    args.render()
  end

  local function show()
    pending = false
    if not args.opts.resume_notice then return end
    local time = mp.get_property_number("time-pos")
    if not time or time < 1 then return end
    position = time
    -- a moment later, so the subtitle notice shown when a subtitle track gets
    -- selected as the file starts doesn't replace it
    mp.add_timeout(0.5, function()
      if position ~= time or not args.opts.resume_notice then return end
      args.indicator:show_pill("history", "Resumed at " .. args.format_time(time),
        mp.get_time(), {duration = 2})
      args.render()
    end)
    if timer then timer:kill() end
    timer = mp.add_timeout(OFFER_SECONDS, clear)
    args.render()
  end

  -- mpv has no property for a resumed file; it logs this line when it loads
  -- the saved position, before playback starts at it
  mp.enable_messages("info")
  mp.register_event("log-message", function(event)
    if event.prefix == "cplayer" and
      tostring(event.text):find("^Resuming playback") then
      pending = true
      if restarted then show() end
    end
  end)
  mp.register_event("start-file", function()
    pending, restarted = false, false
    if position then clear() end
  end)
  mp.register_event("playback-restart", function()
    if restarted then return end
    restarted = true
    if pending then show() end
  end)

  function service:actions()
    if not position or not args.opts.resume_notice then return {} end
    return {
      {name = "resume-start-over", icon = "replay", label = "Start over",
        tooltip = "Resumed at " .. args.format_time(position) ..
          ", play from the beginning",
        on_click = function()
          mp.commandv("seek", 0, "absolute")
          clear()
        end},
      {name = "resume-dismiss", icon = "close", label = "", compact = true,
        tooltip = "Dismiss", on_click = clear}
    }
  end

  return service
end

return resume_notice
