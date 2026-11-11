-- the conexant sn6140 (intel sof) gets two ucm profiles for one output, one
-- with headphones and one with the speaker. wireplumber picks headphones by
-- priority even with the jack empty, and the speaker vanishes. so pick by
-- the jack, again on every plug

cutils = require ("common-utils")
log = Log.open_topic ("s-device")

-- this laptop's card only, never a usb interface or another alsa card
local function affectedDevice (device)
  local props = device.properties
  return props["device.api"] == "alsa"
      and props["api.alsa.card.longname"] == "LENOVO-21SYS1AB00-ThinkPadE14Gen7"
      and props["device.name"] == "alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"
end

-- nil when there's no such pair, or one profile carries both
function findPair (device)
  if not affectedDevice (device) then
    return nil
  end
  local hp, spk
  for p in device:iterate_params ("EnumProfile") do
    local profile = cutils.parseParam (p, "EnumProfile")
    if profile and profile.name then
      local has_hp = profile.name:find ("Headphones", 1, true) ~= nil
      local has_spk = profile.name:find ("Speaker", 1, true) ~= nil
      if has_hp and has_spk then
        return nil
      elseif has_hp then
        hp = profile
      elseif has_spk then
        spk = profile
      end
    end
  end
  if hp and spk then
    return hp, spk
  end
end

function headphonesPlugged (device)
  for p in device:iterate_params ("EnumRoute") do
    local route = cutils.parseParam (p, "EnumRoute")
    if route and route.direction == "Output" and route.name
        and route.name:find ("Headphones", 1, true) then
      return route.available == "yes"
    end
  end
  return false
end

function activeProfileIndex (device)
  for p in device:iterate_params ("Profile") do
    local profile = cutils.parseParam (p, "Profile")
    if profile then
      return tonumber (profile.index)
    end
  end
end

SimpleEventHook {
  name = "device/find-jack-profile",
  after = "device/find-calling-profile",
  before = "device/find-stored-profile",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-profile" },
    },
  },
  execute = function (event)
    if event:get_data ("selected-profile") then
      return
    end

    local device = event:get_subject ()
    if device.properties ["device.api"] ~= "alsa" then
      return
    end

    local hp, spk = findPair (device)
    if not hp then
      return
    end

    -- leave a hand-picked profile (pro-audio) alone. not off (0): a card
    -- starts there before anything picks
    local active = activeProfileIndex (device)
    if active and active ~= 0 and active ~= tonumber (hp.index)
        and active ~= tonumber (spk.index) then
      return
    end

    local profile = headphonesPlugged (device) and hp or spk
    if profile.available == "no" then
      return
    end

    log:info (device, "jack picks profile " .. profile.name)
    event:set_data ("selected-profile", profile)
  end
}:register ()

-- a plug changes routes, not profiles, so nothing else reselects. the last
-- state per device keeps other route changes from reselecting
jack_state = {}

SimpleEventHook {
  name = "device/jack-profile-trigger",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-params-changed" },
      Constraint { "event.subject.param-id", "=", "EnumRoute" },
    },
    EventInterest {
      Constraint { "event.type", "=", "device-removed" },
    },
  },
  execute = function (event)
    local device = event:get_subject ()
    if event:get_properties () ["event.type"] == "device-removed" then
      jack_state [device ["bound-id"]] = nil
      return
    end
    if device.properties ["device.api"] ~= "alsa" or not findPair (device) then
      return
    end

    local plugged = headphonesPlugged (device)
    local id = device ["bound-id"]
    if jack_state [id] == plugged then
      return
    end
    jack_state [id] = plugged
    event:get_source ():call ("push-event", "select-profile", device, nil)
  end
}:register ()

-- this loads after the cards already have a profile, so pick again
alsa_devices_om = ObjectManager {
  Interest {
    type = "device",
    Constraint { "device.api", "=", "alsa" },
  }
}
alsa_devices_om:connect ("object-added", function (_, device)
  local source = Plugin.find ("standard-event-source")
  if source and findPair (device) then
    source:call ("push-event", "select-profile", device, nil)
  end
end)
alsa_devices_om:activate ()
