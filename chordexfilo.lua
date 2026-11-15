-- Chordex Filo
-- de la familia Chordex (U-MA): un sinte MONOFÓNICO lo-fi con una nube de
-- granos, roto, profundo y sucio. Una sola voz (última nota manda, con
-- glide); una nube de granos la repite con tamaño, densidad, memoria y
-- caos. Con el modo acorde cada grano elige un tono del acorde: una voz que
-- suena a acorde desarmado. 4 bancos x 8 presets: ROTO, ABISMO, CINTA, NUBE.
--
-- La pantalla (misma disposición que Chordex FM / ABNT):
--   izquierda: la voz. OSC, SUB, NUBE y POLVO (círculos, brillo = nivel)
--     mandan partículas al filtro; el punto adentro es el cutoff, el anillo
--     la resonancia. Abajo, los 10 faders.
--   centro: el anillo de puntos es la memoria (brillo = lo que sonó), la
--     raya marca el presente y los arcos son los granos: más afuera = más
--     agudo. Adentro, la onda seca y el acorde en la rueda de 12 notas.
--     Con ROTO todo se escalona y parpadea.
--   derecha: banco y preset, osciloscopio, espectro y la falla (animada
--     mientras K2 está apretado).
--
-- Controles (los de la familia):
--   E1: cutoff                    K3 + E1: preset (los 32 en fila)
--   E2: elige fader (muestra      K3 + E2: hall
--       su nombre un momento)
--   E3: ajusta fader              K3 + E3: tipo de acorde
--   faders: ataque, release, resonancia, tamaño del grano, densidad,
--           memoria, caos, roto, polvo, eco
--   K2 mantenido: FALLA (dura mientras se aprieta)
--   K2 + E2: tipo de falla        K2 + E1: profundidad
--   K2 + E3: velocidad (a tempo, del reloj MIDI si entra)
--   fallas: CAIDA (la cinta se frena: la afinación se desploma y se apaga),
--           TARTAMUDEO (repite el último pedacito), MORDIDA (roto al
--           máximo, con cortes a tempo), POZO (una octava abajo, se cierra
--           el filtro y se abre el hall)
--   K3 mantenido (sin girar nada): modo acorde on/off
--   K1 mantenido: retener on/off (rombo arriba a la derecha)
--   clock MIDI entrante: marca el tempo de la falla y del eco

engine.name = 'Filo'

local musicutil = require 'musicutil'
-- arc y crow (si no están conectados no cambia nada)
local ext = include("lib/chordex_ext")

local midi_in
local current_note = nil
local current_vel = 0.8
local last_note = nil
local held_stack = {}
local last_midi_clock = nil
local CLOCK_TIMEOUT = 0.5
local tick_sec = nil
local hold_on = false
local loading = false

local chord_types = {"maj", "min", "dim", "aug", "7", "maj7", "min7", "m7b5", "sus2", "sus4"}
local chord_suffix = {maj = "", min = "m", dim = "dim", aug = "+", ["7"] = "7",
  maj7 = "maj7", min7 = "m7", m7b5 = "m7b5", sus2 = "sus2", sus4 = "sus4"}
local chord_intervals = {
  maj = {0, 4, 7}, min = {0, 3, 7}, dim = {0, 3, 6}, aug = {0, 4, 8},
  ["7"] = {0, 4, 7, 10}, maj7 = {0, 4, 7, 11}, min7 = {0, 3, 7, 10},
  m7b5 = {0, 3, 6, 10}, sus2 = {0, 2, 7}, sus4 = {0, 5, 7},
}
local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
-- falla: tipos y velocidades (en negras por ciclo)
local FALLA_NAMES = {"DROP", "STUTTER", "BITE", "PIT"}
local FALLA_DIV = {2, 1, 0.5, 0.25, 0.125}
local FALLA_DIV_NAMES = {"1/2", "1/4", "1/8", "1/16", "1/32"}
local FALLA_DEF_DIV = {2, 4, 4, 2}   -- velocidad que trae cada tipo
-- tiempo del eco en negras
local ECO_DIV = {0.5, 0.75, 1, 1.5, 2}
local ECO_NAMES = {"1/8", "1/8.", "1/4", "1/4.", "1/2"}

-- ============================================================
-- familias y presets
-- ============================================================
-- a ataque, d decay, s sustain, r release, fo forma (0 sierra .. 1 pulso),
-- sb sub, gl glide, o octava, wo wow (cinta), dr saturación,
-- nu nube (0 seco .. 1 solo granos), sz tamaño del grano, dn densidad,
-- me memoria, ca caos, ro roto, po polvo, c cutoff, q reso, fe env del
-- filtro, e eco, ef repeticiones, et tiempo del eco (índice de ECO_DIV), h hall

local DEF = {a = 0.05, d = 1.2, s = 0.8, r = 1.5, fo = 0.2, sb = 0.4, gl = 0.06, o = 0,
  wo = 0.4, dr = 0.3, nu = 0.75, sz = 0.45, dn = 0.5, me = 0.3, ca = 0.3, ro = 0.25,
  po = 0.3, c = 0.5, q = 0.2, fe = 0.2, e = 0.25, ef = 0.5, et = 3, h = 0.35}

local FAMS = {
  {name = "ROTO", def = {ro = 0.6, ca = 0.6, dr = 0.5, sz = 0.2, dn = 0.6, nu = 0.7, a = 0.005,
      r = 0.8, h = 0.25, po = 0.35}, presets = {
    {n = "MODEM",     fo = 1, q = 0.7, c = 0.55, sz = 0.03, dn = 1, ca = 0.9, ro = 0.7, sb = 0},
    {n = "GLITCH"},
    {n = "8 BITS",    ro = 0.85, fo = 1, nu = 0.3, c = 0.7, ca = 0.2, wo = 0.1, po = 0.1, d = 0.4, s = 0.6},
    {n = "CD RAYADO", sz = 0.05, dn = 0.3, me = 0.05, ca = 0.3, nu = 1, ro = 0.45, c = 0.65},
    {n = "CORTO",     ro = 1, dr = 0.8, sb = 0.6, nu = 0.5, e = 0.35, ef = 0.65},
    {n = "ESQUIRLAS", sz = 0.02, dn = 0.8, me = 0.8, ca = 1, c = 0.8, h = 0.5, e = 0.4, nu = 1},
    {n = "FALLA",     gl = 0.25, wo = 1, ro = 0.5, sz = 0.35, me = 0.5, c = 0.45, q = 0.5, a = 0.1, r = 1.5},
    {n = "SIERRA",    fo = 0, dr = 0.9, ro = 0.35, nu = 0.4, c = 0.6, q = 0.35, fe = 0.5, gl = 0.08, o = -1},
  }},
  {name = "ABISMO", def = {o = -1, sb = 0.8, c = 0.32, a = 0.5, r = 4, h = 0.55, me = 0.6, sz = 0.75,
      dn = 0.45, nu = 0.75, dr = 0.4, e = 0.25, et = 5, po = 0.4}, presets = {
    {n = "FOSA"},
    {n = "SUBSUELO",  sb = 1, nu = 0.3, c = 0.25, q = 0.3, a = 0.05, r = 1.5, h = 0.3, gl = 0.12},
    {n = "CALDERA",   dr = 0.85, ro = 0.35, c = 0.3, q = 0.45, ca = 0.5},
    {n = "BALLENA",   gl = 0.6, ca = 0.6, c = 0.4, wo = 0.8, e = 0.5, ef = 0.7, h = 0.7, fo = 0.5},
    {n = "TUNEL",     q = 0.7, c = 0.28, fe = 0.5, e = 0.45, ef = 0.75, et = 3, sz = 0.3},
    {n = "LODO",      ro = 0.5, po = 0.7, c = 0.22, sz = 0.9, dn = 0.3, dr = 0.6},
    {n = "DRONE",     a = 2, s = 1, r = 6, me = 0.95, sz = 1, dn = 0.5, ca = 0.4, c = 0.36, o = -2, sb = 0.6},
    {n = "ECLIPSE",   ca = 0.9, me = 0.9, sz = 0.6, c = 0.45, h = 0.75, e = 0.4, fo = 0.3},
  }},
  {name = "CINTA", def = {wo = 0.6, po = 0.45, ro = 0.15, nu = 0.5}, presets = {
    {n = "VHS",       fo = 0.3, sz = 0.5, me = 0.2, ca = 0.15, wo = 0.7, e = 0.3},
    {n = "CASETE",    fo = 0.1, c = 0.42, q = 0.25, po = 0.6, sb = 0.5, nu = 0.4, dr = 0.45},
    {n = "WALKMAN",   fo = 0.6, c = 0.55, wo = 0.9, sz = 0.3, dn = 0.6, a = 0.01, d = 0.6, s = 0.5, r = 0.6, e = 0.35},
    {n = "BOBINA",    a = 0.6, r = 3, c = 0.4, nu = 0.7, sz = 0.7, me = 0.5, h = 0.5, e = 0.4, ef = 0.6},
    {n = "DICTAFONO", fo = 0.8, c = 0.38, q = 0.5, ro = 0.4, po = 0.7, sb = 0.1, dr = 0.6, nu = 0.35, h = 0.15},
    {n = "RADIO AM",  fo = 0.5, c = 0.45, q = 0.6, ro = 0.3, po = 0.8, sb = 0, dr = 0.5, sz = 0.2, dn = 0.7},
    {n = "DERRETIDO", wo = 1, gl = 0.3, sz = 0.6, ca = 0.4, me = 0.4, a = 0.3, r = 2.5, e = 0.3},
    {n = "TECLADO",   a = 0.005, d = 0.5, s = 0.4, r = 0.5, fo = 0.4, fe = 0.5, nu = 0.3, gl = 0.02, sb = 0.3},
  }},
  {name = "NUBE", def = {nu = 0.9, sz = 0.6, dn = 0.6, me = 0.55, ca = 0.45, a = 0.4, r = 3,
      h = 0.5, e = 0.3, ef = 0.55, et = 4, ro = 0.1}, presets = {
    {n = "NIEBLA"},
    {n = "ENJAMBRE",  sz = 0.12, dn = 0.95, ca = 0.7, me = 0.35, c = 0.62, q = 0.3},
    {n = "LLOVIZNA",  sz = 0.08, dn = 0.5, ca = 0.8, me = 0.7, c = 0.7, h = 0.6, a = 0.02},
    {n = "MAREA",     sz = 0.95, dn = 0.4, me = 0.9, ca = 0.3, a = 1.5, r = 5, c = 0.42, sb = 0.5},
    {n = "ESPEJO",    ca = 1, sz = 0.5, me = 0.6, c = 0.55, e = 0.45},
    {n = "CORO ROTO", fo = 0.7, sz = 0.4, dn = 0.75, ca = 0.55, ro = 0.3, q = 0.4},
    {n = "CENIZA",    po = 0.75, sz = 0.25, dn = 0.35, me = 0.85, c = 0.45, ro = 0.2, h = 0.6},
    {n = "AURORA",    fo = 0.1, sz = 0.7, dn = 0.7, ca = 0.6, c = 0.68, o = 1, h = 0.65, e = 0.4},
  }},
}
local fam_names = {}
for i, f in ipairs(FAMS) do
  fam_names[i] = f.name
  for _, p in ipairs(f.presets) do
    for k, v in pairs(f.def) do if p[k] == nil then p[k] = v end end
    for k, v in pairs(DEF) do if p[k] == nil then p[k] = v end end
  end
end

-- faders (E2 elige, E3 ajusta); el cutoff va en E1
local P = {
  {id = "atk", name = "ATTACK",   min = 0.001, max = 6,  step = 0.02},
  {id = "rel", name = "RELEASE",   min = 0.02,  max = 10, step = 0.05},
  {id = "res", name = "RESONANCE",   min = 0,     max = 1,  step = 0.02},
  {id = "size", name = "GRAIN",  min = 0,     max = 1,  step = 0.02},
  {id = "dens", name = "DENSITY",  min = 0,     max = 1,  step = 0.02},
  {id = "mem", name = "MEMORY",   min = 0,     max = 1,  step = 0.02},
  {id = "caos", name = "CHAOS",  min = 0,     max = 1,  step = 0.02},
  {id = "roto", name = "BROKEN",  min = 0,     max = 1,  step = 0.02},
  {id = "polvo", name = "DUST", min = 0,     max = 1,  step = 0.02},
  {id = "eco", name = "ECHO",   min = 0,     max = 1,  step = 0.02},
}
local focus_index = 1

local fader_flash = 0      -- nombre del fader al elegirlo con E2
local falla_on = false     -- K2 apretado
local falla_flash = 0      -- cartel de la falla (K2 + encoders)
local FL = {lv = 0, ph = 0, spin = 0}   -- la falla en pantalla
local k2_held, k2_turned, k3_held = false, false, false
local k3_turned = false
local k3_press = nil
local K3_LONG = 0.5   -- segundos manteniendo K3 para alternar el modo acorde

-- animación
local PULSE = 24
local pulse = {}          -- pulso por nombre de control
local flash = 0
local chord_flash = 0
local model_flash = 0
local hold_flash = 0
local last_t = nil

-- la voz "simulada" para que la pantalla respire igual que el sonido
local VS = nil
local scene_hit   -- forward: la escena reacciona a cada nota

local function pv(id) return params:get(id) end
local function bump(name) pulse[name] = PULSE end
local function cur_fam() return FAMS[pv("fam")] end
local function cur_preset() return cur_fam().presets[pv("preset")] end
local function shift(n) return n + 12 * pv("oct") end
local function note_to_hz(n) return musicutil.note_num_to_freq(util.clamp(n, 0, 127)) end

local function chord_name() return chord_types[pv("chord")] end

local function chord_ivs()
  local iv = chord_intervals[chord_name()]
  if #iv >= 4 then return iv end
  return {iv[1], iv[2], iv[3], iv[1] + 12}
end

-- los tonos entre los que eligen los granos (modo acorde apagado: la nota sola)
local function four_tone_intervals()
  if pv("chord_on") == 1 then return {0} end
  return chord_ivs()
end

-- ============================================================
-- sonido (una sola voz: última nota manda)
-- ============================================================

local function send_chord()
  local iv = four_tone_intervals()
  local r = {}
  for i = 1, 4 do r[i] = 2 ^ ((iv[i] or 0) / 12) end
  engine.chord(r[1], r[2], r[3], r[4])
end

-- retrig: la envolvente vuelve a atacar; si no, la voz se desliza a la nota
local function play(note, retrig)
  local n = shift(note)
  ext.chord(n, current_vel)
  engine.noteOn(note_to_hz(n), current_vel, retrig and 1 or 0)
  if retrig or not VS or VS.t1 then
    VS = {t0 = util.time(), note = n, vel = current_vel}
  else
    VS.note = n
  end
  scene_hit(n, current_vel)
  flash = 1
end

local function ext_clock_on()
  return last_midi_clock ~= nil and (util.time() - last_midi_clock) < CLOCK_TIMEOUT
end

local function beat_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * 24 end
  return clock.get_beat_sec()
end

-- falla: tipo (0 = nada), profundidad y velocidad en Hz a tempo
local function falla_hz() return 1 / (beat_seconds() * FALLA_DIV[pv("falla_div")]) end
local falla_sent = ""
local function send_falla()
  if not params.lookup["falla_div"] then return end
  local m = falla_on and pv("falla_mode") or 0
  local key = string.format("%d %.3f %.4f", m, pv("falla_depth"), falla_hz())
  if key ~= falla_sent then
    falla_sent = key
    engine.falla(m, pv("falla_depth"), falla_hz())
  end
end

-- con clock MIDI, algunos equipos repiten la nota apretada a tempo: el
-- soltar espera un poco y si vuelve la misma nota no se redispara
local release_id = nil

local function cancel_release()
  if release_id then clock.cancel(release_id); release_id = nil end
end

local function release_now()
  release_id = nil
  if #held_stack == 0 and not hold_on and current_note ~= nil then
    ext.release()
    engine.noteOff()
    if VS and not VS.t1 then VS.t1 = util.time() end
    current_note = nil
  end
end

local function release_grace()
  return util.clamp((tick_sec or 0.02) * 13, 0.05, 0.8)
end

local function on_note_on(note, vel)
  cancel_release()
  table.insert(held_stack, note)
  -- si ya hay algo sonando (legato o retenido) la voz se desliza sin reatacar
  local retrig = current_note == nil
  current_note = note
  last_note = note
  current_vel = vel / 127
  play(note, retrig)
end

local function on_note_off(note)
  for i = #held_stack, 1, -1 do
    if held_stack[i] == note then table.remove(held_stack, i); break end
  end
  -- con HOLD, soltar teclas no cambia nada
  if hold_on then return end
  local top = held_stack[#held_stack]
  if top == nil then
    if current_note ~= nil then
      if ext_clock_on() then
        cancel_release()
        local wait = release_grace()
        release_id = clock.run(function() clock.sleep(wait); release_now() end)
      else
        release_now()
      end
    end
  elseif top ~= current_note then
    -- vuelve a la última tecla que sigue apretada
    current_note = top
    last_note = top
    play(top, false)
  end
end

local function set_hold(on)
  hold_on = on
  hold_flash = PULSE
  if not on then cancel_release(); release_now() end
end

-- teclas soltadas con clock corriendo que esperan por si el equipo las repite
local repeat_off = {}
local function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == "clock" then
    local now = util.time()
    if last_midi_clock then
      local d = now - last_midi_clock
      if d > 0.002 and d < 0.25 then
        tick_sec = tick_sec and (tick_sec * 0.9 + d * 0.1) or d
      end
    end
    last_midi_clock = now
    return
  elseif msg.type == "start" or msg.type == "stop" or msg.type == "continue" then
    return
  end
  local ch = params:get("midi_channel")
  if ch ~= 0 and msg.ch ~= ch then return end
  if msg.type == "note_on" and msg.vel > 0 then
    if repeat_off[msg.note] then repeat_off[msg.note] = nil; return end
    on_note_on(msg.note, msg.vel)
  elseif msg.type == "note_off" or (msg.type == "note_on" and msg.vel == 0) then
    if ext_clock_on() then
      local note = msg.note
      local tok = {}
      repeat_off[note] = tok
      local wait = util.clamp((tick_sec or 0.02) * 30, 0.05, 1)
      clock.run(function()
        clock.sleep(wait)
        if repeat_off[note] == tok then repeat_off[note] = nil; on_note_off(note) end
      end)
    else
      on_note_off(msg.note)
    end
  end
end

-- ============================================================
-- parámetros (se guardan solos en data/chordexfilo/estado.pset)
-- ============================================================

local STATE_FILE

-- un preset carga todo el sonido (no toca acorde, falla ni volumen)
local function load_preset()
  local p = cur_preset()
  params:set("atk", p.a); params:set("dec", p.d); params:set("sus", p.s); params:set("rel", p.r)
  params:set("forma", p.fo); params:set("sub", p.sb); params:set("glide", p.gl)
  params:set("wow", p.wo); params:set("drive", p.dr)
  params:set("nube", p.nu); params:set("size", p.sz); params:set("dens", p.dn)
  params:set("mem", p.me); params:set("caos", p.ca)
  params:set("roto", p.ro); params:set("polvo", p.po)
  params:set("cut", p.c); params:set("res", p.q); params:set("fenv", p.fe)
  params:set("eco", p.e); params:set("ecofb", p.ef); params:set("ecot_div", p.et)
  params:set("space", p.h)
  params:set("oct", p.o)
end

local eco_sent = 0
local function update_eco_time()
  local t = beat_seconds() * ECO_DIV[pv("ecot_div")]
  if math.abs(t - eco_sent) > 0.005 then eco_sent = t; engine.ecot(t) end
end

local function ctl(id, name, mn, mx, def, unit, fn, warp)
  params:add_control(id, name, controlspec.new(mn, mx, warp or "lin", 0, def, unit or ""))
  params:set_action(id, fn)
end

local function add_params()
  params:add_separator("filo", "CHORDEX FILO")
  params:add_number("midi_channel", "MIDI channel (0=all)", 0, 16, 1)
  params:add_option("fam", "bank", fam_names, 1)
  params:set_action("fam", function()
    if not loading then
      if pv("preset") ~= 1 then params:set("preset", 1) else load_preset() end
    end
  end)
  params:add_number("preset", "preset", 1, 8, 1)
  params:set_action("preset", function()
    if not loading then load_preset() end
  end)
  params:add_option("chord", "chord", chord_types, 1)
  params:set_action("chord", function() send_chord() end)
  params:add_option("chord_on", "chord mode (grains)", {"no", "yes"}, 2)
  params:set_action("chord_on", function() send_chord() end)
  params:add_separator("filo_falla", "GLITCH (K2)")
  params:add_option("falla_mode", "glitch type", FALLA_NAMES, 1)
  params:set_action("falla_mode", function(v)
    if not loading then params:set("falla_div", FALLA_DEF_DIV[v]) end
    send_falla()
  end)
  params:add_control("falla_depth", "depth", controlspec.new(0, 1, "lin", 0, 0.85, ""))
  params:set_action("falla_depth", function() send_falla() end)
  params:add_option("falla_div", "rate", FALLA_DIV_NAMES, 2)
  params:set_action("falla_div", function() send_falla() end)

  params:add_separator("filo_src", "SOURCE")
  ctl("forma", "shape (saw-pulse)", 0, 1, DEF.fo, "", function(v) engine.forma(v) end)
  ctl("sub", "sub", 0, 1, DEF.sb, "", function(v) engine.sub(v) end)
  ctl("glide", "glide", 0, 1, DEF.gl, "s", function(v) engine.glide(v) end)
  params:add_number("oct", "octave", -2, 2, 0)
  params:set_action("oct", function()
    if current_note and not loading then play(current_note, false) end
  end)
  ctl("wow", "wow (tape)", 0, 1, DEF.wo, "", function(v) engine.wow(v) end)
  ctl("drive", "saturation", 0, 1, DEF.dr, "", function(v) engine.drive(v) end)

  params:add_separator("filo_grn", "CLOUD")
  ctl("nube", "cloud (dry-grains)", 0, 1, DEF.nu, "", function(v) engine.nube(v) end)
  ctl("size", "grain size", 0, 1, DEF.sz, "", function(v) engine.size(v) end)
  ctl("dens", "density", 0, 1, DEF.dn, "", function(v) engine.dens(v) end)
  ctl("mem", "memory", 0, 1, DEF.me, "", function(v) engine.mem(v) end)
  ctl("caos", "chaos", 0, 1, DEF.ca, "", function(v) engine.caos(v) end)
  ctl("roto", "broken", 0, 1, DEF.ro, "", function(v) engine.roto(v) end)
  ctl("polvo", "dust", 0, 1, DEF.po, "", function(v) engine.polvo(v) end)

  params:add_separator("filo_env", "ENVELOPE / FILTER")
  ctl("atk", "attack", 0.001, 6, DEF.a, "s", function(v) engine.atk(v) end)
  ctl("dec", "decay", 0.05, 6, DEF.d, "s", function(v) engine.dec(v) end)
  ctl("sus", "sustain", 0, 1, DEF.s, "", function(v) engine.sus(v) end)
  ctl("rel", "release", 0.02, 10, DEF.r, "s", function(v) engine.rel(v) end)
  ctl("cut", "cutoff", 0, 1, DEF.c, "", function(v) engine.cut(v) end)
  ctl("res", "resonance", 0, 1, DEF.q, "", function(v) engine.res(v) end)
  ctl("fenv", "filter env", 0, 1, DEF.fe, "", function(v) engine.fenv(v) end)

  params:add_separator("filo_fx", "FX")
  ctl("eco", "tape echo", 0, 1, DEF.e, "", function(v) engine.eco(v) end)
  ctl("ecofb", "echo feedback", 0, 0.9, DEF.ef, "", function(v) engine.ecofb(v) end)
  params:add_option("ecot_div", "echo time", ECO_NAMES, DEF.et)
  params:set_action("ecot_div", function() eco_sent = 0; update_eco_time() end)
  ctl("space", "hall", 0, 0.8, DEF.h, "", function(v) engine.space(v) end)
  ctl("gain", "volume", 0, 1.5, 1.0, "", function(v) engine.gain(v) end)
end

-- ============================================================
-- init / controles
-- ============================================================

local screen_metro
local splash_start = nil
-- primero la intro U-MA de partículas, después FILO
local SPLASH_IN, SPLASH_HOLD, SPLASH_FADE = 0.4, 2.2, 0.6
local uma_intro = include("lib/uma_splash_particles")
local uma_sound = include("lib/uma_splash") -- base de la intro, maneja el sonido

local function skip_splash()
  if splash_start and util.time() - splash_start < uma_intro.DUR then uma_sound.sound_off() end
  splash_start = nil
end

function init()
  midi_in = {}
  for i = 1, #midi.vports do
    midi_in[i] = midi.connect(i)
    midi_in[i].event = midi_event
  end

  add_params()
  ext.add_params()
  STATE_FILE = norns.state.data .. "estado.pset"
  local fresh = not util.file_exists(STATE_FILE)
  loading = true
  if not fresh then
    params:read(STATE_FILE)
    params:bang()
  else
    params:bang()
    loading = false
    load_preset()
  end
  loading = false
  update_eco_time()

  uma_sound.sound_on(norns.state.path .. "lib/uma_particles.wav")
  splash_start = util.time()
  screen_metro = metro.init(function() redraw() end, 1 / 24, -1)
  screen_metro:start()
  -- primera vez (sin estado guardado): tempo interno 50 BPM
  if fresh then params:set("clock_tempo", 50) end
  ext.init{
    rings = {"cut", "size", "falla_depth", "space"},
    env = function() return pv("atk"), pv("dec"), pv("sus"), pv("rel") end,
    beat = beat_seconds, on = on_note_on, off = on_note_off,
    level = function() return flash end,
  }
end

function cleanup()
  ext.cleanup()
  if STATE_FILE then params:write(STATE_FILE, "chordexfilo") end
end

local function nudge(p, d)
  params:set(p.id, util.clamp(pv(p.id) + d * p.step, p.min, p.max))
end

function enc(n, d)
  if splash_start or not params.lookup["fam"] then return end
  local dir = d > 0 and 1 or -1
  if n == 1 then
    if k2_held then
      params:set("falla_depth", util.clamp(pv("falla_depth") + d * 0.02, 0, 1))
      falla_flash = PULSE * 2
    elseif k3_held then
      k3_turned = true
      -- los 32 presets en fila: al pasar el 8 entra a la familia siguiente
      local g = util.clamp((pv("fam") - 1) * 8 + pv("preset") + dir, 1, #FAMS * 8)
      local f, pr = math.floor((g - 1) / 8) + 1, (g - 1) % 8 + 1
      if f ~= pv("fam") then
        loading = true; params:set("fam", f); loading = false
        if pr == pv("preset") then load_preset() end
      end
      params:set("preset", pr)
      model_flash = PULSE * 2
    else
      params:set("cut", util.clamp(pv("cut") + d * 0.01, 0, 1))
      bump("cut")
    end
  elseif n == 2 then
    if k2_held then
      params:set("falla_mode", ((pv("falla_mode") - 1 + dir) % #FALLA_NAMES) + 1)
      falla_flash = PULSE * 2
    elseif k3_held then
      k3_turned = true
      params:set("space", util.clamp(pv("space") + d * 0.01, 0, 0.8))
      bump("space")
    else
      focus_index = ((focus_index - 1 + dir) % #P) + 1
      bump(P[focus_index].id)
      -- el nombre del fader aparece un momento
      fader_flash = PULSE * 1.5
      model_flash = 0; chord_flash = 0
    end
  elseif n == 3 then
    if k2_held then
      params:set("falla_div", util.clamp(pv("falla_div") + dir, 1, #FALLA_DIV))
      falla_flash = PULSE * 2
    elseif k3_held then
      k3_turned = true
      params:set("chord", util.clamp(pv("chord") + dir, 1, #chord_types))
      chord_flash = PULSE * 2
    else
      nudge(P[focus_index], d)
      fader_flash = PULSE * 1.5
      model_flash = 0; chord_flash = 0
      bump(P[focus_index].id)
    end
  end
end

function key(n, z)
  if not params.lookup["fam"] then return end
  -- K1 llega acá solo si se mantiene (el toque corto abre el menú de norns)
  if n == 1 then
    if z == 1 then
      if splash_start then skip_splash() end
      set_hold(not hold_on)
    end
  elseif n == 2 then
    -- la falla dura mientras K2 está apretado
    if z == 1 then
      k2_held = true
      if not splash_start then falla_on = true end
    else
      if splash_start then skip_splash() end
      k2_held = false
      falla_on = false
    end
    send_falla()
  elseif n == 3 then
    k3_held = (z == 1)
    if z == 1 and splash_start then skip_splash() end
    if z == 1 then
      -- mantener K3 sin girar ningún encoder alterna el modo acorde
      k3_turned = false
      local press = util.time()
      k3_press = press
      clock.run(function()
        clock.sleep(K3_LONG)
        if k3_held and not k3_turned and k3_press == press then
          params:set("chord_on", 3 - params:get("chord_on"))
          chord_flash = PULSE * 2
        end
      end)
    end
  end
end

-- ============================================================
-- GRÁFICOS — acumulador por nivel (mismo esquema que los otros Chordex)
-- ============================================================

local G = {}
do
local bt, b1, b2, b3, b4, bn = {}, {}, {}, {}, {}, {}
for lv = 1, 15 do bt[lv] = {}; b1[lv] = {}; b2[lv] = {}; b3[lv] = {}; b4[lv] = {}; bn[lv] = 0 end

local function add(lv, ty, a, b, c, d)
  lv = math.floor(lv + 0.5)
  if lv < 1 then return end
  if lv > 15 then lv = 15 end
  local n = bn[lv] + 1
  bn[lv] = n
  bt[lv][n] = ty; b1[lv][n] = a; b2[lv][n] = b; b3[lv][n] = c; b4[lv][n] = d
end

function G.px(lv, x, y) add(lv, 0, x, y) end
function G.line(lv, x1, y1, x2, y2) add(lv, 3, x1, y1, x2, y2) end
function G.rect(lv, x, y, w, h) add(lv, 4, x, y, w, h) end
function G.circle(lv, x, y, r) add(lv, 5, x, y, r) end

function G.flush()
  local floor = math.floor
  for lv = 1, 15 do
    local n = bn[lv]
    if n > 0 then
      local T, A, B, C, D = bt[lv], b1[lv], b2[lv], b3[lv], b4[lv]
      screen.level(lv)
      local fills, strokes = false, false
      for k = 1, n do
        local ty = T[k]
        if ty == 0 then
          screen.rect(floor(A[k]), floor(B[k]), 1, 1); fills = true
        elseif ty == 4 then
          screen.rect(floor(A[k]), floor(B[k]), C[k], D[k]); fills = true
        else
          strokes = true
        end
      end
      if fills then screen.fill() end
      if strokes then
        for k = 1, n do
          local ty = T[k]
          if ty == 3 then
            screen.move(floor(A[k]) + 0.5, floor(B[k]) + 0.5)
            screen.line(floor(C[k]) + 0.5, floor(D[k]) + 0.5)
          elseif ty == 5 then
            screen.move(floor(A[k]) + 0.5 + C[k], floor(B[k]) + 0.5)
            screen.circle(floor(A[k]) + 0.5, floor(B[k]) + 0.5, C[k])
          end
        end
        screen.stroke()
      end
      bn[lv] = 0
    end
  end
end
end

-- envolvente simulada (la misma ADSR que el engine)
local function env_at(vs, t)
  if not vs then return 0 end
  local a, d, s, r = pv("atk") + 0.002, pv("dec"), pv("sus"), pv("rel")
  local function held(el)
    if el < a then return el / a end
    return s + (1 - s) * math.exp(-(el - a) / math.max(0.01, d) * 3)
  end
  local e
  if vs.pluck then
    -- paso de arpegio: la compuerta baja sola
    local el = t - vs.t0
    if el < vs.dur then e = held(el)
    else
      local x = (el - vs.dur) / math.max(0.02, r)
      e = x >= 1 and 0 or held(vs.dur) * (1 - x) * (1 - x)
    end
  else
    e = held((vs.t1 or t) - vs.t0)
    if vs.t1 then
      local x = (t - vs.t1) / math.max(0.02, r)
      e = x >= 1 and 0 or e * (1 - x) * (1 - x)
    end
  end
  return util.clamp(e, 0, 1) * (0.6 + vs.vel * 0.4)
end

-- ============================================================
-- la voz calculada en Lua (misma receta que el engine) para dibujar
-- ============================================================

local V = {N = 96, y = {}, spec = {}, amp = 0, fe = 0, tw = {}}
for k = 1, V.N do V.y[k] = 0 end
for h = 1, 14 do V.spec[h] = 0 end

-- 2 ciclos de la nota = 1 ciclo del sub
local function compute_voice(t)
  local vs = VS
  V.amp = env_at(vs, t)
  -- caída: al frenarse la cinta se apaga
  if pv("falla_mode") == 1 then V.amp = V.amp * (1 - FL.lv * pv("falla_depth")) end
  local fo, sb, ro = pv("forma"), pv("sub"), pv("roto")
  local note = (vs and vs.note) or (last_note and shift(last_note) or 45)
  local f = note_to_hz(note)
  local fe = 0
  if vs then
    local el, a = t - vs.t0, math.max(0.005, pv("atk"))
    fe = (el < a) and el / a or math.exp(-(el - a) / (pv("dec") + 0.1) * 3)
    fe = fe * vs.vel
  end
  V.fe = fe
  local fc = 50 * 2 ^ (pv("cut") * 8.5) * (1 + fe * pv("fenv") * 4) * (f / 130.8) ^ 0.25
  local per = V.N / 2
  local a = math.min(1, 1 - math.exp(-2 * math.pi * fc / (f * per)))
  local q = pv("res")
  local ys, vv, pk = 0, 0, 1e-6
  for pass = 1, 2 do
    for k = 1, V.N do
      local x = (k - 1) / per             -- 0..2 ciclos
      local ph = x % 1
      local v = ((1 - fo) * (1 - 2 * ph) + fo * (ph < 0.5 and 1 or -1)) * 0.5
        + math.sin(math.pi * x) * sb * 0.5
      vv = vv * (q * 0.85) + a * (v - ys)
      ys = ys + vv
      if pass == 2 then V.y[k] = ys; pk = math.max(pk, math.abs(ys)) end
    end
  end
  pk = math.max(pk, 0.4)
  -- roto: la onda se escalona (menos muestras y menos bits)
  local hold_n = 1 + math.floor(ro * 5)
  local steps = math.max(2, math.floor(14 * (1 - ro) + 2))
  local h = 0
  for k = 1, V.N do
    local y = V.y[k] / pk
    if ro > 0.05 then
      if (k - 1) % hold_n == 0 then h = math.floor(y * steps + 0.5) / steps end
      y = h
    end
    V.y[k] = y
  end
  -- espectro: 14 armónicos de la nota (bins pares, la ventana dura 2 ciclos)
  local N = V.N
  for hh = 1, 14 do
    local tw = V.tw[hh]
    if not tw then
      tw = {c = {}, s = {}}
      for k = 1, N do
        local an = 2 * math.pi * (2 * hh) * (k - 1) / N
        tw.c[k] = math.cos(an); tw.s[k] = math.sin(an)
      end
      V.tw[hh] = tw
    end
    local re, im = 0, 0
    for k = 1, N do re = re + V.y[k] * tw.c[k]; im = im + V.y[k] * tw.s[k] end
    local mag = 2 * math.sqrt(re * re + im * im) / N * V.amp
    V.spec[hh] = V.spec[hh] * 0.5 + mag * 0.5
  end
end

-- ============================================================
-- dibujo
-- ============================================================

local CX, CY = 64, 32
local R_DRY = 11      -- la onda seca
local RR = 17         -- el anillo de memoria
local TAPE = 5        -- segundos de memoria (como el engine)
local MEM_N = 48
local TW = 2 * math.pi
local memv = {}
for k = 1, MEM_N do memv[k] = 0 end
local head = 0        -- posición del cabezal (0..1)
local grains, gacc = {}, 0
local drop_t, dropped = 0, false
local rot = 0
local rings, comets = {}, {}

local function pl(name) return (pulse[name] or 0) / PULSE end

-- cada nota: un cometa desde la rueda y un anillo (el eco lo repite)
scene_hit = function(n, vel, step)
  if #comets > 20 then table.remove(comets, 1) end
  comets[#comets + 1] = {pc = n % 12, r = 0, lv = 6 + vel * 9}
  -- los pasos del arpegio solo tiran el cometa (si no, los anillos se empastan)
  if step then return end
  if #rings > 10 then table.remove(rings, 1) end
  rings[#rings + 1] = {r = RR, lv = 5 + vel * 5, gen = 0}
end

-- panel izquierdo: la voz. OSC, SUB, NUBE y POLVO entran al filtro
local NODES = {{x = 4, y = 6}, {x = 11, y = 6}, {x = 18, y = 6}, {x = 25, y = 6}}
local FX_, FY_ = 15, 22
local function draw_voice(t)
  local e = V.amp
  local nube = pv("nube")
  local lv_in = {1 - nube * 0.6, pv("sub"), nube, pv("polvo")}
  local cp, rp = pl("cut"), pl("res")
  -- el filtro tiembla con el wow de la cinta
  local fx = FX_ + math.sin(t * 3.8) * pv("wow") * 1.5
  local fy = FY_
  G.line(2 + e * 8, 2, 36, 28, 36)
  G.line(2 + e * 6, fx, fy + 4, fx, 35)
  for i, nd in ipairs(NODES) do
    local l = lv_in[i]
    if l > 0.02 then
      G.line(1 + l * 3 * (0.4 + e), nd.x, nd.y + 3, fx, fy - 3)
      local np = 1 + math.floor(l * 2 + 0.5)
      for q = 0, np - 1 do
        local u = (t * (0.5 + i * 0.12) + q / np) % 1
        G.px(5 + l * e * 10, nd.x + (fx - nd.x) * u, nd.y + 3 + (fy - 3 - nd.y - 3) * u)
      end
    end
    G.circle(3 + l * (3 + e * 9), nd.x, nd.y, 2)
  end
  -- OSC: un fantasma que se corre con el wow
  local wo = pv("wow")
  if wo > 0.05 then
    local ph = t * (1 + wo * 3)
    G.px(6 + wo * 9, NODES[1].x + math.cos(ph) * 3, NODES[1].y + math.sin(ph * 1.3) * 3)
  end
  -- NUBE: granitos alrededor (más densidad = más)
  for _ = 1, math.floor(nube * (1 + pv("dens") * 3) * (0.3 + e)) do
    G.px(5 + math.random() * 9, NODES[3].x + math.random(-3, 3), NODES[3].y + math.random(-3, 3))
  end
  -- POLVO
  for _ = 1, math.floor(pv("polvo") * 3 * (0.3 + e)) do
    G.px(4 + math.random() * 6, NODES[4].x + math.random(-3, 3), NODES[4].y + math.random(-3, 3))
  end
  -- filtro: el punto adentro sube con el cutoff, el anillo es la resonancia
  local cut = pv("cut")
  G.circle(cp > 0 and 15 or (4 + e * 8), fx, fy, 3)
  G.rect(6 + e * 9 + cp * 6, fx - 1, fy + 1 - math.floor(cut * 3 + V.fe * pv("fenv") * 2), 2, 1)
  local res = pv("res")
  if res > 0.05 or rp > 0 then G.circle(3 + res * 7 + rp * 6, fx, fy, 5) end
end

-- faders: 10 columnitas abajo a la izquierda
local FADER_ICON = {
  atk   = {"..#", ".##", "###"},   -- rampa que sube
  rel   = {"#..", "##.", "###"},   -- rampa que cae
  res   = {".#.", ".#.", "#.#"},   -- pico
  size  = {"...", "###", "..."},   -- un grano largo
  dens  = {"#.#", ".#.", "#.#"},   -- muchos granos
  mem   = {"###", "#.#", "###"},   -- la cinta
  caos  = {"#..", "..#", ".#."},   -- desorden
  roto  = {"##.", "...", ".##"},   -- partido
  polvo = {".#.", "#..", "..#"},   -- motas
  eco   = {"#..", "#.#", "#.#"},   -- repeticiones
}

local function draw_faders()
  for i, p in ipairs(P) do
    local x = 1 + (i - 1) * 3
    local focused = (focus_index == i)
    local pp = pl(p.id)
    local lv = focused and 15 or (pp > 0 and 6 + 9 * pp or 6)
    G.line(focused and 3 or 1, x, 42, x, 55)
    local v = (pv(p.id) - p.min) / (p.max - p.min)
    if p.id == "atk" or p.id == "rel" then v = math.sqrt(v) end
    local cy = math.floor(54 - v * 12 + 0.5)
    G.rect(lv, x - (focused and 1 or 0), cy, focused and 3 or 2, 2)
    local low = (i % 2 == 0)
    local iy = low and 61 or 57
    local il = focused and 15 or math.floor(5 + 8 * pp + 0.5)
    if low then G.px(focused and 5 or 2, x, 57) G.px(focused and 5 or 2, x, 59) end
    local ic = FADER_ICON[p.id]
    for r = 1, 3 do
      local row = ic[r]
      for c = 1, 3 do
        if row:sub(c, c) == "#" then G.px(il, x - 2 + c, iy + r - 1) end
      end
    end
  end
end

-- el centro: la cinta (anillo), el cabezal, los granos y la onda seca
local function draw_cloud(t, dt, iv)
  local N = V.N
  local env = V.amp
  local nube, size, dens, mem, caos = pv("nube"), pv("size"), pv("dens"), pv("mem"), pv("caos")
  local ro, po = pv("roto"), pv("polvo")

  -- la memoria guarda la envolvente de lo que va sonando
  local fm = pv("falla_mode")
  -- tartamudeo: la memoria se detiene
  if not (falla_on and fm == 2) then
    head = (head + dt / TAPE) % 1
    memv[math.floor(head * MEM_N) + 1] = env
  end
  -- roto: cortes
  drop_t = drop_t - dt
  if drop_t <= 0 then
    drop_t = 1 / (3 + 10 * ro)
    dropped = ro > 0.12 and math.random() < ro * ro * 0.42
  end
  local dim = dropped and 0.2 or 1
  -- mordida: todo parpadea a tempo
  if falla_on and fm == 3 and (FL.ph % 1) >= 0.5 then dim = 0.15 end
  -- pozo: anillos que se hunden hacia el centro
  if fm == 4 and FL.lv > 0.05 then
    for k = 0, 2 do
      local u = (FL.ph * 0.5 + k / 3) % 1
      G.circle((2 + 7 * u) * FL.lv, CX, CY, 4 + (1 - u) * 26)
    end
  end

  -- anillo de memoria
  local act = env
  for k = 1, MEM_N do
    local a = TW * (k - 0.5) / MEM_N - math.pi / 2
    local m = memv[k]
    if m > act then act = m end
    G.px(2 + m * 6, CX + math.cos(a) * RR, CY + math.sin(a) * RR)
  end
  -- el presente
  local ah = TW * head - math.pi / 2
  G.line(10, CX + math.cos(ah) * (RR - 2), CY + math.sin(ah) * (RR - 2),
    CX + math.cos(ah) * (RR + 2), CY + math.sin(ah) * (RR + 2))

  -- la onda seca, adentro
  local dl = (2 + 11 * math.min(1, env * 1.4 + flash * 0.2)) * (1 - nube * 0.7) * dim
  local sc = 0.3 + 0.7 * env
  local px, py
  for k = 0, N, 2 do
    local kk = (k % N) + 1
    local a = TW * k / N + rot
    local rad = R_DRY + V.y[kk] * 2.5 * sc
    local x, y = CX + math.cos(a) * rad, CY + math.sin(a) * rad
    if px then G.line(dl, px, py, x, y) end
    px, py = x, y
  end
  rot = rot + dt * (0.08 + env * 0.3)

  -- nacen granos
  local gbase = 0.015 * (0.55 / 0.015) ^ size
  local gdens = math.min(2 * 30 ^ dens, 14 / gbase)
  gacc = gacc + dt * math.min(gdens, 30)
  while gacc >= 1 do
    gacc = gacc - 1
    local dly = 0.03 + math.random() * 0.01 * 350 ^ mem
    local u = (head - dly / TAPE) % 1
    local m = memv[math.floor(u * MEM_N) + 1]
    if m > 0.04 and #grains < 40 then
      local oc = math.random()
      local o = (oc < caos * 0.3) and 1 or ((oc > 1 - caos * 0.25) and -1 or 0)
      local semi = iv[math.random(#iv)]
      grains[#grains + 1] = {
        u = u, off = (o + semi / 12) * 5 + (math.random() - 0.5) * caos * 3,
        rev = math.random() < caos * 0.45, life = 0,
        -- en pantalla viven un poco más que en el sonido, para que se vean
        dur = 0.3 + gbase * 1.5 * (1 - caos * 0.6 * math.random()),
        len = 0.25 + size * 0.9, lv = m,
      }
    end
  end
  -- los granos: arcos que avanzan (o retroceden) por la cinta
  for i = #grains, 1, -1 do
    local g = grains[i]
    g.life = g.life + dt
    local p = g.life / g.dur
    if p >= 1 then
      table.remove(grains, i)
    else
      local lv = (2 + 13 * g.lv * math.sin(math.pi * p)) * (0.25 + 0.75 * nube) * dim
      if lv >= 1 then
        local span = g.len * 0.6
        local a0 = TW * g.u - math.pi / 2 + (g.rev and -1 or 1) * g.len * 0.5 * p
        local n = math.max(2, math.ceil(span / 0.14))
        local gx, gy
        for s = 0, n do
          local a = a0 + span * s / n
          local kk = math.floor(((a * 4 / TW) % 1) * N) + 1
          local rad = RR + g.off + V.y[kk] * 2.5
          local x, y = CX + math.cos(a) * rad, CY + math.sin(a) * rad
          if gx then G.line(lv, gx, gy, x, y) end
          gx, gy = x, y
        end
      end
    end
  end

  -- polvo: motas sueltas
  for _ = 1, math.floor(po * po * 9 * (0.15 + act)) do
    local a, r = math.random() * TW, 8 + math.random() * 22
    G.px(3 + math.random() * 7, CX + math.cos(a) * r, CY + math.sin(a) * r)
  end

  -- anillo del cutoff al moverlo con E1; el del hall con K3 + E2
  local function ring(v, p, rim)
    if p <= 0 then return end
    local n = 40
    for k = 1, n do
      local a = TW * k / n
      G.px((k / n) <= v and 15 * p or 3 * p, CX + math.cos(a) * rim, CY + math.sin(a) * rim)
    end
  end
  ring(pv("cut"), pl("cut"), 27)
  ring(pv("space") / 0.8, pl("space"), 30)

  -- eco: anillos que se abren; al pasar el tiempo del eco nace otro más débil
  local eco, fb = pv("eco"), pv("ecofb")
  local et = beat_seconds() * ECO_DIV[pv("ecot_div")]
  local speed = 14
  for i = #rings, 1, -1 do
    local r = rings[i]
    local age = (r.r - RR) / speed
    r.r = r.r + dt * speed
    local l = r.lv * (1 - (r.r - RR) / 9)
    if l < 1.5 or r.r > 32 then table.remove(rings, i)
    else
      G.circle(math.min(9, l), CX, CY, r.r)
      if not r.echoed and eco > 0.05 and age >= et and r.gen < 4 then
        r.echoed = true
        local nl = r.lv * fb * (0.6 + eco * 0.4)
        if nl > 2.5 then rings[#rings + 1] = {r = RR, lv = nl, gen = r.gen + 1} end
      end
    end
  end
end

-- el acorde en la rueda de 12 notas, en el centro
local function wheel_xy(pc, rad)
  local a = (pc / 12) * TW - math.pi / 2
  return CX + math.cos(a) * rad, CY + math.sin(a) * rad
end

local function draw_wheel(dt, iv, notes)
  local root = current_note or last_note
  local lit = current_note ~= nil
  local W = 6
  local tones = {}
  if notes then
    -- arpegio andando: las notas que recorre
    for _, n in ipairs(notes) do tones[#tones + 1] = shift(n) % 12 end
  elseif root then
    for _, v in ipairs(iv) do tones[#tones + 1] = (shift(root) + v) % 12 end
  end
  for pc = 0, 11 do
    local x, y = wheel_xy(pc, W)
    G.px(2, x, y)
  end
  if #tones > 0 then
    local base = lit and 1 or 0.35
    local sorted = {}
    for _, pc in ipairs(tones) do sorted[#sorted + 1] = pc end
    table.sort(sorted)
    for i = 1, #sorted do
      local a, b = sorted[i], sorted[i % #sorted + 1]
      if a ~= b then
        local x1, y1 = wheel_xy(a, W)
        local x2, y2 = wheel_xy(b, W)
        G.line((4 + 5 * V.amp) * base + chord_flash / PULSE * 6, x1, y1, x2, y2)
      end
    end
    for i, pc in ipairs(tones) do
      local x, y = wheel_xy(pc, W)
      if i == 1 then G.rect(15 * base, x - 1, y - 1, 2, 2)
      else G.px(11 * base, x, y) end
    end
  end
  for i = #comets, 1, -1 do
    local c = comets[i]
    c.r = c.r + dt * 34
    if c.r > 32 then table.remove(comets, i)
    else
      local r0 = W + c.r
      local x1, y1 = wheel_xy(c.pc, r0)
      local x2, y2 = wheel_xy(c.pc, math.max(W, r0 - 4))
      G.line(c.lv * (1 - c.r / 34), x2, y2, x1, y1)
    end
  end
end

-- panel derecho: banco/preset, osciloscopio, espectro, falla
local function draw_right(t, dt)
  local x0 = 98
  for f = 1, #FAMS do
    G.rect(pv("fam") == f and 12 or 2, x0 + 1 + (f - 1) * 4, 0, 3, 1)
  end
  for p = 1, 8 do
    G.px(pv("preset") == p and 12 or 2, x0 + 1 + (p - 1) * 2, 2)
  end
  -- retener: rombo de 3x3 arriba a la derecha
  local lk = hold_on and (current_note and 13 or 8) or 3
  lk = math.min(15, lk + hold_flash * 0.25)
  G.px(lk, 125, 0) G.px(lk, 124, 1) G.px(lk, 126, 1) G.px(lk, 125, 2)
  if hold_on then G.px(lk, 125, 1) end

  -- osciloscopio: un ciclo de la nota (se apaga en los cortes)
  local per = V.N / 2
  local mid = 12
  local lv = (4 + 11 * math.min(1, V.amp * 1.5)) * (dropped and 0.3 or 1)
  local sc = 0.2 + 0.8 * V.amp
  local px, py
  for xx = 0, 29 do
    local k = math.floor(xx / 29 * (per - 1)) + 1
    local y = mid - V.y[k] * 7 * sc
    if px then G.line(lv, px, py, x0 + xx, y) end
    px, py = x0 + xx, y
  end

  -- espectro: 14 armónicos
  local base = 50
  for h = 1, 14 do
    local x = x0 + 1 + (h - 1) * 2
    local m = math.sqrt(V.spec[h]) * 26
    local hh = math.min(26, math.floor(m + 0.5))
    for y = 0, hh - 1 do
      G.px(3 + 12 * (1 - y / 26) * math.min(1, V.amp * 2 + 0.3), x, base - 1 - y)
    end
  end

  -- la falla: quieta y tenue en reposo, animada mientras K2 está apretado
  local m, dp, on, ph = pv("falla_mode"), pv("falla_depth"), falla_on, FL.ph
  local hi = on and 15 or 5
  if m == 1 then
    -- CAIDA: el carrete se frena y el punto cae por la curva
    local rx, ry = x0 + 5, 57
    G.circle(on and 12 or 5, rx, ry, 4)
    for q = 0, 2 do
      local an = FL.spin + q * TW / 3
      G.px(hi, rx + math.cos(an) * 2, ry + math.sin(an) * 2)
    end
    local ppx, ppy
    for xx = 0, 16, 2 do
      local u = xx / 16
      local y = 53 + u * u * 8
      if ppx then G.line(on and 7 or 3, ppx, ppy, x0 + 11 + xx, y) end
      ppx, ppy = x0 + 11 + xx, y
    end
    local u = FL.lv * dp
    G.rect(hi, x0 + 10 + u * 16, 52 + u * u * 8, 3, 3)
  elseif m == 2 then
    -- TARTAMUDEO: el mismo pedacito, repetido
    local cur = math.floor(ph) % 5
    for i = 0, 4 do
      local lv = (on and i == cur) and 15 or (on and 6 or 4)
      local bx = x0 + 1 + i * 6
      G.rect(lv, bx, 58, 1, 3) G.rect(lv, bx + 1, 55, 1, 6)
      G.rect(lv, bx + 2, 53, 1, 8) G.rect(lv, bx + 3, 57, 1, 4)
    end
  elseif m == 3 then
    -- MORDIDA: dos filas de dientes que muerden a tempo
    local open = on and (((ph % 1) < 0.5) and 0 or 3) or 2
    for i = 0, 6 do
      local bx = x0 + 1 + i * 4
      G.rect(hi, bx, 52, 2, 5 - open)
      G.rect(hi, bx + 2, 57 + open, 2, 5 - open)
    end
  else
    -- POZO: anillos que se hunden
    local cx, cy = x0 + 14, 57
    for k = 0, 2 do
      local u = on and ((ph * 0.5 + k / 3) % 1) or (k / 3 + 0.15)
      local r = (1 - u) * 13
      for j = 1, 14 do
        local an = TW * j / 14
        G.px(on and (4 + u * 11) or (3 + u * 3), cx + math.cos(an) * r, cy + math.sin(an) * r * 0.38)
      end
    end
    G.px(hi, cx, cy)
  end
  -- abajo: tipo (4 puntos) y profundidad (rayita)
  for k = 1, #FALLA_NAMES do
    G.px(k == m and (on and 15 or 9) or 2, x0 + 1 + (k - 1) * 2, 63)
  end
  local gl = math.floor(dp * 16 + 0.5)
  if gl > 0 then G.line(on and 10 or 3, x0 + 11, 63, x0 + 11 + gl, 63) end
end

-- dibujos de las familias (aparecen al cambiar de preset con K3 + E1)
local FAM_ICON = {
  CINTA = {
    "###############",
    "#             #",
    "#  ##     ##  #",
    "# #++#...#++# #",
    "#  ##     ##  #",
    "#             #",
    "###############",
  },
  NUBE = {
    "    .  #  .    ",
    "  #   .#.  #   ",
    " .  ##+++#   . ",
    "  #+++++++#+ # ",
    " #++++++++++#  ",
    "  .#######. .  ",
    "    .   #   .  ",
  },
  ROTO = {
    "####   #   ####",
    "#++#  #    #++#",
    "#++# #   . #++#",
    "###  ##    ####",
    "#++#   #   #+  ",
    "#++#  #  . #++#",
    "####  #    ####",
  },
  ABISMO = {
    "###############",
    " #+++++++++++# ",
    "  #+++++++++#  ",
    "   #.......#   ",
    "    #.....#    ",
    "     #...#     ",
    "      ###      ",
  },
}
local ICON_LV = {["#"] = 15, ["+"] = 9, ["."] = 4}

local function text_box(txt, a, y)
  local cy = y or CY
  screen.font_face(1)
  screen.font_size(8)
  local w = screen.text_extents(txt)
  screen.level(0)
  screen.rect(CX - w / 2 - 3, cy - 6, w + 6, 11)
  screen.fill()
  screen.level(math.floor(15 * a))
  screen.move(CX - w / 2, cy + 2)
  screen.text(txt)
end

local function draw_overlays()
  if falla_flash > 0 then
    text_box(FALLA_NAMES[pv("falla_mode")] .. " " .. FALLA_DIV_NAMES[pv("falla_div")]
      .. " " .. string.format("%02d", math.floor(pv("falla_depth") * 99 + 0.5)),
      math.min(1, falla_flash / PULSE))
  elseif model_flash > 0 then
    -- dibujo de la familia + nombre del preset
    local a = math.min(1, model_flash / PULSE)
    local rows = FAM_ICON[cur_fam().name]
    local w, h = #rows[1], #rows
    local name = cur_preset().n
    screen.font_face(1)
    screen.font_size(8)
    local tw = screen.text_extents(name)
    local bw = math.max(w, tw) + 6
    local x0, y0 = math.floor(CX - w / 2), CY - 10
    screen.level(0)
    screen.rect(math.floor(CX - bw / 2), y0 - 3, bw, h + 16)
    screen.fill()
    for ch, l in pairs(ICON_LV) do
      local lv = math.floor(l * a + 0.5)
      if lv > 0 then
        screen.level(lv)
        for y = 1, h do
          local r = rows[y]
          for x = 1, w do
            if r:sub(x, x) == ch then screen.rect(x0 + x - 1, y0 + y - 1, 1, 1) end
          end
        end
        screen.fill()
      end
    end
    screen.level(math.floor(15 * a))
    screen.move(CX - tw / 2, y0 + h + 9)
    screen.text(name)
  elseif chord_flash > 0 or k3_held then
    -- nombre del acorde, solo mientras se elige (K3)
    local root = current_note or last_note
    local rn = root and note_names[(shift(root) % 12) + 1]
    local txt = (rn or "") .. (chord_suffix[chord_name()] ~= "" and chord_suffix[chord_name()] or (rn and "" or "maj"))
    if pv("chord_on") == 1 then txt = rn or "1" end
    text_box(txt, k3_held and 1 or math.min(1, chord_flash / PULSE))
  elseif fader_flash > 0 then
    -- nombre del fader elegido con E2 o ajustado con E3
    text_box(P[focus_index].name, 1, 58)   -- abajo, al borde de la pantalla
  end
end

-- ---- presentación: FILO en bloques, con glitch ----
local FILO = {
  {"#####", "#....", "#....", "####.", "#....", "#....", "#...."},
  {"#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"},
  {"#....", "#....", "#....", "#....", "#....", "#....", "#####"},
  {".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."},
}
local GL = {fr = -1, dx = {}, noise = {}, jx = 0, cut = 0, ghost = 0}

local function draw_splash(alpha)
  screen.clear()
  local t = util.time()
  -- 12 veces por segundo se sortea la falla: bandas corridas, una banda
  -- apagada, un fantasma y ruido
  local fr = math.floor(t * 12)
  if fr ~= GL.fr then
    GL.fr = fr
    local burst = math.random() < 0.45
    GL.jx = burst and math.random(-2, 2) or 0
    for b = 1, 14 do
      GL.dx[b] = (burst and math.random() < 0.4) and math.random(-9, 9) or 0
    end
    GL.cut = burst and math.random(1, 14) or 0
    GL.ghost = burst and math.random(-4, 4) or 0
    GL.noise = {}
    for i = 1, (burst and math.random(2, 6) or 0) do
      GL.noise[i] = {math.random(8, 108), math.random(12, 52), math.random(3, 14), math.random(3, 10)}
    end
  end
  local S, x0, y0 = 4, 15, 18
  local function pass(lv, ox)
    if lv < 1 then return end
    screen.level(lv)
    for li, L in ipairs(FILO) do
      local lx = x0 + (li - 1) * 26
      for r = 1, 7 do
        local row = L[r]
        for half = 0, 1 do
          local b = (r - 1) * 2 + half + 1
          if b ~= GL.cut then
            local dx = GL.dx[b] + GL.jx + ox
            for c = 1, 5 do
              if row:sub(c, c) == "#" then
                screen.rect(lx + (c - 1) * S + dx, y0 + (r - 1) * S + half * 2, S, 2)
              end
            end
          end
        end
      end
    end
    screen.fill()
  end
  if GL.ghost ~= 0 then pass(math.floor(5 * alpha), GL.ghost) end
  pass(math.floor(15 * alpha), 0)
  -- una franja negra que baja (el tracking)
  screen.level(0)
  screen.rect(0, y0 - 2 + math.floor((t * 22) % 34), 128, 2)
  screen.fill()
  for _, nz in ipairs(GL.noise) do
    screen.level(math.floor(nz[4] * alpha))
    screen.rect(nz[1], nz[2], nz[3], 1)
    screen.fill()
  end
  screen.update()
end

local function tick(dt)
  for k, v in pairs(pulse) do pulse[k] = math.max(0, v - 1) end
  model_flash = math.max(0, model_flash - 1)
  fader_flash = math.max(0, fader_flash - 1)
  falla_flash = math.max(0, falla_flash - 1)
  -- la falla en pantalla sube y baja como en el engine
  local fm = pv("falla_mode")
  local hz = falla_hz()
  local tc = falla_on and (((fm == 1 or fm == 4) and math.min(3, 1 / hz)) or 0.02) or 0.2
  FL.lv = FL.lv + ((falla_on and 1 or 0) - FL.lv) * math.min(1, dt / tc * 2.5)
  FL.ph = FL.ph + dt * hz
  FL.spin = FL.spin + dt * 5 * (1 - (fm == 1 and FL.lv * pv("falla_depth") or 0))
  chord_flash = math.max(0, chord_flash - 1)
  hold_flash = math.max(0, hold_flash - 1)
  flash = math.max(0, flash - dt * 3)
end

local eco_timer = 0
function redraw()
  local now = util.time()
  if splash_start then
    local e = now - splash_start
    if e < uma_intro.DUR then
      uma_intro.render(e)
      screen.update()
      return
    end
    e = e - uma_intro.DUR
    local t1 = SPLASH_IN
    local t2 = t1 + SPLASH_HOLD
    local t3 = t2 + SPLASH_FADE
    if e < t1 then draw_splash(e / SPLASH_IN) return
    elseif e < t2 then draw_splash(1) return
    elseif e < t3 then draw_splash(1 - (e - t2) / SPLASH_FADE) return
    else splash_start = nil end
  end

  local dt = last_t and math.min(0.2, now - last_t) or 1 / 24
  last_t = now
  tick(dt)
  eco_timer = eco_timer + dt
  if eco_timer > 1 then eco_timer = 0; update_eco_time(); send_falla() end
  compute_voice(now)
  local iv = four_tone_intervals()
  local wiv = pv("chord_on") == 2 and chord_ivs() or {0}

  screen.clear()
  draw_cloud(now, dt, iv)
  draw_wheel(dt, wiv)
  draw_voice(now)
  draw_faders()
  draw_right(now, dt)
  G.flush()
  draw_overlays()
  screen.update()
end
