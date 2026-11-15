// Engine_Filo.sc
// Chordex Filo — el hermano roto de la familia Chordex: un sinte MONOFÓNICO
// lo-fi con una nube de granos (al estilo "clouds"), profundo y sucio.
//
// Voz (\filo_voice, una sola, siempre viva):
//   fuente: dos sierras desafinadas <-> pulso con PWM (forma), con el wow y
//           el flutter de una cinta gastada. Última nota manda, con glide.
//   cinta:  la fuente se graba todo el tiempo en una memoria de 5 s.
//   nube:   granos que leen esa memoria: tamaño, densidad, memoria (cuánto
//           para atrás buscan) y caos (octavas, granos al revés, desorden,
//           panorama). Con el modo acorde, cada grano elige un tono del
//           acorde: una sola voz que suena a acorde desarmado.
//   sub:    seno una octava abajo, directo (lo profundo).
//   roto:   baja la frecuencia de muestreo y los bits, y aparecen cortes.
//   filtro: pasa bajos resonante con envolvente; polvo = soplido, crackle,
//           zumbido y pérdida de agudos.
// Falla (K2 mantenido; fmode 1..4, fdepth 0..1, frate Hz a tempo):
//   1 CAÍDA:      la cinta se frena: la afinación se desploma y se apaga
//   2 TARTAMUDEO: la memoria deja de grabar y repite el último pedacito
//   3 MORDIDA:    roto y saturación al máximo, con cortes a tempo
//   4 POZO:       baja una octava, se cierra el filtro y se abre el hall
// FX (\filo_fx): eco de cinta a tempo (tiembla y se ensucia en cada vuelta)
//   -> hall oscuro -> compresor -> limitador.

Engine_Filo : CroneEngine {

  var voiceBus, buf, voice, fxSynth;

  alloc {
    voiceBus = Bus.audio(context.server, 2);
    buf = Buffer.alloc(context.server, (context.server.sampleRate * 5).asInteger, 1);

    SynthDef(\filo_voice, {
      arg out = 0, buf = 0, freq = 110, gate = 0, vel = 0.8, t_trig = 0,
          atk = 0.05, dec = 1.2, sus = 0.8, rel = 1.5, glide = 0.05,
          forma = 0.2, sub = 0.4, wow = 0.4, drive = 0.3,
          cut = 0.5, res = 0.2, fenv = 0.2,
          nube = 0.75, size = 0.45, dens = 0.5, mem = 0.3, caos = 0.3,
          roto = 0.25, polvo = 0.3, fmode = 0, fdepth = 0.8, frate = 2,
          r1 = 1, r2 = 1, r3 = 1, r4 = 1;
      var env, velA, fv, wv, f, osc, src, sb, frames, wr, wrK, isC, isT, isM, isP, ft, cL, tL, mL, pL, pm, rt, dv,
          gbase, gdens, trig, gdur, ratio, oc, oct, rev, grate, need, dly, pos, gpan,
          cloud, ov, sig, m, held, steps, drop, dg, fe, fc, act, nz;

      velA = 0.4 + (Lag.kr(vel, 0.02) * 0.6);
      // t_trig baja la compuerta un instante: la envolvente vuelve a atacar
      env = EnvGen.kr(Env.adsr(atk + 0.002, dec, sus, rel), gate - t_trig);
      fv = Lag.kr(freq, glide);

      // cinta: wow lento + flutter rápido + deriva
      wv = ((SinOsc.kr(0.6 + LFNoise1.kr(0.3, 0.25)) * 0.007)
        + (LFNoise2.kr(8) * 0.003) + (LFNoise2.kr(0.2) * 0.005)) * wow;

      // falla
      isC = (fmode > 0.5) * (fmode < 1.5);
      isT = (fmode > 1.5) * (fmode < 2.5);
      isM = (fmode > 2.5) * (fmode < 3.5);
      isP = fmode > 3.5;
      ft = (1 / frate.max(0.2)).clip(0.03, 3);
      cL = LagUD.kr(isC, ft, 0.2);
      tL = Lag.kr(isT, 0.01);
      mL = Lag.kr(isM, 0.01);
      pL = LagUD.kr(isP, ft, 0.3);
      pm = (2 ** (cL * fdepth * -3)) * (2 ** (pL * -1));
      rt = roto + (mL * fdepth * (1 - roto));
      dv = drive + (mL * fdepth * 0.6 * (1 - drive));

      f = fv * (1 + wv) * pm;

      osc = XFade2.ar(
        VarSaw.ar(f, 0, 0.04) + (VarSaw.ar(f * 1.006, 0.3, 0.04) * 0.6),
        Pulse.ar(f, 0.5 + (LFTri.kr(0.11) * 0.32)) * 1.2,
        (forma * 2) - 1) * 0.5;
      src = (osc * env * velA * (1 + (drive * 2))).tanh;

      // la memoria: se graba siempre (el tartamudeo la detiene)
      frames = BufFrames.kr(buf);
      wr = Phasor.ar(0, 1 - isT, 0, frames);
      BufWr.ar(Select.ar(K2A.ar(isT), [src, BufRd.ar(1, buf, wr, 1, 1)]), buf, wr, 1);
      wrK = A2K.kr(wr);

      // la nube
      gbase = size.linexp(0, 1, 0.015, 0.55);
      gdens = dens.linexp(0, 1, 2, 60).min(14 / gbase);
      trig = Select.kr(isT, [
        Impulse.kr(gdens * LFNoise0.kr(gdens).range(1 - (caos * 0.7), 1 + (caos * 0.7))),
        Impulse.kr(frate)]);
      gdur = Select.kr(isT, [gbase * TRand.kr(1 - (caos * 0.6), 1, trig), ft.min(1.2)]);
      ratio = Select.kr(TIRand.kr(0, 3, trig), [r1, r2, r3, r4]);
      oc = TRand.kr(0, 1, trig);
      oct = 2 ** ((oc < (caos * 0.3)) - (oc > (1 - (caos * 0.25))));
      rev = TRand.kr(0, 1, trig) < (caos * 0.45);
      grate = Select.kr(isT, [
        ratio * oct * (1 - (2 * rev)) * (1 + (TRand.kr(-1, 1, trig) * caos * 0.012)), 1]) * pm;
      // un grano más agudo lee más rápido: arranca más atrás para no pasar al cabezal
      need = ((grate - 1).max(0) * gdur) + 0.03;
      dly = Select.kr(isT, [
        (need + (TRand.kr(0, 1, trig) * mem.linexp(0, 1, 0.01, 3.5))).min(4.6),
        ft.min(1.2) + 0.02]);
      pos = ((wrK - (dly * SampleRate.ir)) / frames).wrap(0, 1);
      gpan = TRand.kr(-1, 1, trig) * (0.35 + (caos * 0.55)) * (1 - isT);
      cloud = GrainBuf.ar(2, trig, gdur, buf, grate, pos, 2, gpan, -1, 64);
      ov = Select.kr(isT, [(gdens * gbase).max(1), 1]);
      cloud = cloud * (ov ** -0.5) * 1.5;

      sb = (SinOsc.ar(f * 0.5) + (LFTri.ar(f * 0.5) * 0.3)) * env * velA * sub * 0.5;
      // tartamudeo: calla lo seco y deja la nube repitiendo
      sig = ([src, src] * (1 - nube) * 0.9 * (1 - (tL * fdepth)))
        + (cloud * (nube + (tL * fdepth * (1 - nube)))) + ([sb, sb] * (1 - (tL * fdepth)));

      // roto: menos muestras, menos bits y cortes
      m = (rt * 2.5).min(1);
      held = Latch.ar(sig, Impulse.ar(rt.linexp(0, 1, 20000, 1400)));
      sig = (sig * (1 - m)) + (held * m);
      steps = rt.linexp(0, 1, 2048, 10);
      sig = (sig * steps).round(1) / steps;
      drop = Lag.kr(LFNoise0.kr(rt.linlin(0, 1, 3, 13)).range(0, 1) > (rt.squared * 0.42), 0.003);
      sig = sig * (1 - (0.92 * (1 - drop) * (rt > 0.12)));
      // mordida: cortes a tempo
      sig = sig * (1 - (mL * fdepth * (1 - Lag.kr(LFPulse.kr(frate, 0, 0.5), 0.004))));

      // saturación de cinta (un poco torcida)
      dg = 1 + (dv.squared * 10);
      sig = ((sig * dg) + (dv * 0.08)).tanh / (1 + (dv * 1.6));

      fe = EnvGen.kr(Env.perc(atk.max(0.005), dec + 0.1, 1, -4), gate - t_trig) * velA;
      fc = 50 * (2 ** ((Lag.kr(cut, 0.05) - (pL * fdepth * 0.35)).clip(0, 1) * 8.5)) * (1 + (fe * fenv * 4))
        * ((fv / 130.8) ** 0.25);
      sig = RLPF.ar(LeakDC.ar(sig), fc.clip(30, 17000), (1 - (res * 0.92)).max(0.07))
        * (1 - (res * 0.3));
      // cinta gastada: se pierden los agudos
      sig = LPF.ar(sig, polvo.linexp(0, 1, 15000, 4200));

      // polvo: soplido, crackle y zumbido; aparece con el sonido y se va después
      act = (Amplitude.kr(Mix(sig), 0.01, 2.5) * 12).min(1);
      nz = (HPF.ar(PinkNoise.ar([1, 1]), 1800) * 0.05)
        + (BPF.ar(Dust2.ar([1, 1] * polvo.linlin(0, 1, 2, 22)), 2400, 0.9) * 0.9)
        + (SinOsc.ar(50) * 0.012) + (LPF.ar(BrownNoise.ar([1, 1]), 120) * 0.05);
      sig = sig + (nz * polvo.squared * act);

      // caída: al frenarse la cinta el sonido se apaga
      Out.ar(out, HPF.ar(sig, 28) * 0.8 * (1 - (cL * fdepth)));
    }).add;

    SynthDef(\filo_fx, {
      arg in, out, eco = 0.25, ecot = 0.4, ecofb = 0.5, space = 0.35, gain = 1.0, wow = 0.4, pozo = 0;
      var sig, fb, d, wob, verb, comp, pz;

      sig = In.ar(in, 2);

      // eco de cinta: el tiempo tiembla y cada vuelta sale más oscura y sucia
      wob = 1 + (SinOsc.kr(0.43) * 0.004 * (0.3 + wow)) + (LFNoise2.kr(3) * 0.002 * wow);
      fb = LocalIn.ar(2);
      d = DelayC.ar(sig + (fb.reverse * ecofb.clip(0, 0.9)), 2.2,
        (Lag.kr(ecot, 0.4) * wob).clip(0.02, 2.1));
      LocalOut.ar((LPF.ar(HPF.ar(d, 150), 2800) * 1.3).tanh * 0.8);
      sig = sig + (d * eco * 0.8);

      // hall oscuro (el pozo lo abre)
      pz = Lag.kr(pozo, 0.6);
      verb = HPF.ar(sig, 120) * (space + (pz * 0.45));
      verb = DelayN.ar(verb, 0.06, 0.035);
      verb = FreeVerb2.ar(verb[0], verb[1], 1, (0.82 + (space * 0.2) + (pz * 0.12)).min(0.98), 0.6);
      sig = sig + (LPF.ar(verb, 5200) * 1.2);

      sig = LPF.ar(HPF.ar(sig, 28), 15000);
      comp = Compander.ar(sig, Mix(sig) * 0.5, 0.25, 1, 0.45, 0.01, 0.25);
      sig = Limiter.ar(LeakDC.ar(comp * 1.5 * gain), 0.92, 0.002);
      Out.ar(out, sig);
    }).add;

    context.server.sync;

    voice = Synth.head(context.xg, \filo_voice, [\out, voiceBus, \buf, buf]);
    fxSynth = Synth.tail(context.xg, \filo_fx, [\in, voiceBus, \out, context.out_b]);

    // frecuencia, vel, reatacar (1) o deslizar sin reatacar (0)
    this.addCommand("noteOn", "ffi", { |msg|
      voice.set(\freq, msg[1], \vel, msg[2], \gate, 1, \t_trig, msg[3]);
    });

    this.addCommand("noteOff", "", { |msg| voice.set(\gate, 0) });

    // falla: tipo (0 = nada, 1..4), profundidad, velocidad (Hz)
    this.addCommand("falla", "iff", { |msg|
      voice.set(\fmode, msg[1], \fdepth, msg[2], \frate, msg[3].max(0.05));
      fxSynth.set(\pozo, if (msg[1] == 4) { msg[2] } { 0 });
    });

    // los 4 tonos del acorde como relaciones de frecuencia (1 1 1 1 = nota sola)
    this.addCommand("chord", "ffff", { |msg|
      voice.set(\r1, msg[1], \r2, msg[2], \r3, msg[3], \r4, msg[4]);
    });

    [\atk, \dec, \sus, \rel, \glide, \forma, \sub, \drive, \cut, \res, \fenv,
     \nube, \size, \dens, \mem, \caos, \roto, \polvo].do({ |k|
      this.addCommand(k, "f", { |msg| voice.set(k, msg[1]) });
    });
    this.addCommand("wow", "f", { |msg| voice.set(\wow, msg[1]); fxSynth.set(\wow, msg[1]) });

    this.addCommand("eco", "f", { |msg| fxSynth.set(\eco, msg[1]) });
    this.addCommand("ecot", "f", { |msg| fxSynth.set(\ecot, msg[1].clip(0.05, 2)) });
    this.addCommand("ecofb", "f", { |msg| fxSynth.set(\ecofb, msg[1]) });
    this.addCommand("space", "f", { |msg| fxSynth.set(\space, msg[1]) });
    this.addCommand("gain", "f", { |msg| fxSynth.set(\gain, msg[1]) });
    // compatibilidad con los otros Chordex (el crackle por teclas no existe acá)
    this.addCommand("crackle", "f", { |msg| });
  }

  free {
    voice.free;
    fxSynth.free;
    voiceBus.free;
    buf.free;
  }
}
