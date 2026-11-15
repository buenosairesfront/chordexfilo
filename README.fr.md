[English](README.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex Filo

Le frère cassé de la famille Chordex : un synthé **monophonique lo-fi** pour
[monome norns](https://monome.org/docs/norns/). Une seule voix et un **nuage
de grains** qui la répète depuis la mémoire. En mode accord, chaque grain
choisit une note de l'accord : une voix qui sonne comme un accord démonté.
Cassé, profond et sale, avec 4 banques × 8 presets, soit 32 sons. À la place
de l'arpégiateur, il a la **FALLA** (panne) : tant que K2 est enfoncé,
quelque chose se casse.

![Chordex Filo](docs/sheet.png)

**L'écran, c'est le son :**

- **à gauche :** la voix. OSC, SUB, NUBE (nuage) et POLVO (poussière) sont
  des cercles dont la luminosité suit le niveau ; ils envoient des particules
  vers le filtre. Le point dans le filtre est le cutoff et l'anneau la
  résonance. En dessous, les 10 faders.
- **au centre :** l'anneau de points est la mémoire (ce qui vient de sonner
  brille), le trait marque le présent et les arcs sont les grains : plus loin
  du centre = plus aigu. À l'intérieur, l'onde sèche et l'accord sur la roue
  de 12 notes. Avec ROTO, tout devient crénelé et clignote.
- **à droite :** banque et preset, oscilloscope, spectre et la panne, animée
  tant que K2 est enfoncé.

## Caractéristiques

- **mono** : priorité à la dernière note. En jouant legato, la voix glisse
  sans réattaquer
- **4 banques × 8 presets**
  - **ROTO** (cassé) : MODEM, GLITCH, 8 BITS, CD RAYADO, CORTO, ESQUIRLAS,
    FALLA, SIERRA
  - **ABISMO** (abîme) : FOSA, SUBSUELO, CALDERA, BALLENA, TUNEL, LODO, DRONE,
    ECLIPSE
  - **CINTA** (bande) : VHS, CASETE, WALKMAN, BOBINA, DICTAFONO, RADIO AM,
    DERRETIDO, TECLADO
  - **NUBE** (nuage) : NIEBLA, ENJAMBRE, LLOVIZNA, MAREA, ESPEJO, CORO ROTO,
    CENIZA, AURORA
- **voix** : un oscillateur qui va de la dent de scie à l'impulsion, sub,
  saturation et pleurage de bande, filtre résonant avec enveloppe, glide
- **nuage** : la voix est enregistrée en permanence dans une mémoire de
  5 secondes que lisent les grains. Taille, densité, mémoire (jusqu'où ils
  remontent) et chaos (octaves, grains à l'envers, désordre, panoramique)
- **mode accord** : chaque grain choisit l'une des quatre notes de l'accord.
  **10 accords** : maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **FALLA** (K2 maintenu), au tempo, 4 types :
  - **CAIDA** (chute) : la bande ralentit, la hauteur s'effondre et s'éteint
  - **TARTAMUDEO** (bégaiement) : la tête s'arrête et répète le dernier petit
    bout
  - **MORDIDA** (morsure) : cassé au maximum, avec des coupures au tempo
  - **POZO** (puits) : une octave plus bas, le filtre se ferme et le hall
    s'ouvre
- **roto** : moins d'échantillons, moins de bits et des coupures. **polvo** :
  souffle, craquements, ronflette et perte d'aigus, qui suivent le son
- **effets** : écho à bande au tempo et hall sombre
- **maintien** (K1)
- suit l'horloge MIDI entrante pour le tempo de la panne et de l'écho
- tout est sauvegardé automatiquement

<!-- u-ma:family -->
## La famille Chordex

Mêmes contrôles, moteurs différents. Essayez les autres :

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.fr.md)**<br>polysynthé des années 80 avec un coucher de soleil outrun<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md)**<br>FM à 4 opérateurs, dessinée comme une fleur<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md)**<br>cordes d'orchestre avec le vrai mouvement d'une corde frottée<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.fr.md)**<br>wavetable : 8 banques de 8 ondes, dessinée comme une table en 3D<br>`;install https://github.com/buenosairesfront/chordexwt` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.fr.md)**<br>chiptune : 8 puces de console × 8 presets, dessiné comme un tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |
| <a href="https://github.com/buenosairesfront/chordexabnt/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexabnt/main/docs/1_warm_pad.png" width="200" alt="Chordex ABNT"></a> | **[Chordex ABNT](https://github.com/buenosairesfront/chordexabnt/blob/main/README.fr.md)**<br>pads, ambient, leads et textures : 4 familles × 8 presets, avec du MOUVEMENT au lieu d'un arpégiateur<br>`;install https://github.com/buenosairesfront/chordexabnt` |

**Plus de U-MA :** tous les instruments et outils au même endroit → [vitrine U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.fr.md)
<!-- /u-ma:family -->

## Prérequis

- norns (shield, standard ou fates)
- un clavier ou contrôleur MIDI

## Installation

Depuis maiden :

```
;install https://github.com/buenosairesfront/chordexfilo
```

Ensuite **redémarrez norns** (SYSTEM > RESTART) pour compiler le nouveau
moteur `Filo`, puis chargez **chordexfilo** depuis SELECT.

## Contrôles

| contrôle | action |
|---|---|
| E1 | cutoff (brillance) |
| E2 | choisit le fader (son nom s'affiche un instant) |
| E3 | règle le fader |
| K3 + E1 | preset (les 32 à la suite : ROTO 1–8, ABISMO, CINTA, NUBE) |
| K3 + E2 | hall |
| K3 + E3 | type d'accord |
| K3 maintenu (sans tourner) | mode accord on/off |
| K2 maintenu | panne (dure tant qu'il est enfoncé) |
| K2 + E1 | profondeur de la panne |
| K2 + E2 | type de panne |
| K2 + E3 | vitesse de la panne (1/2 à 1/32) |
| K1 maintenu | maintien on/off (losange en haut à droite) |

**Faders :** attaque, release, résonance, taille du grain, densité, mémoire,
chaos, roto (cassé), polvo (poussière), écho.

**Menu PARAMETERS :** canal MIDI (1 par défaut ; 0 = tous), banque, preset,
forme (scie–impulsion), sub, glide, octave, pleurage, saturation, nuage
(sec–grains), decay, sustain, enveloppe du filtre, répétitions et temps de
l'écho, volume, et tout ce qui précède.

## arc et crow

Les deux sont optionnels : sans arc ni crow connectés, rien ne change.

**arc** (4 anneaux, dessinés comme des potentiomètres) : 1 cutoff · 2 taille du grain · 3 profondeur de la panne · 4 hall

**crow** : IN1 = hauteur (V/oct, 0 V = C4), IN2 = gate (joue et relâche) · OUT1 = la note (V/oct) · OUT2 = enveloppe (0–8 V, avec l'attaque et le release du son) · OUT3 = LFO au tempo · OUT4 = une impulsion à chaque note. Désactivable dans PARAMETERS > ARC / CROW.

**Tempo :** au premier lancement, le tempo interne démarre à 50 BPM. Si une horloge MIDI arrive (par n'importe quel port MIDI), c'est elle qui commande.

## Galerie

| | |
|---|---|
| ![ROTO](docs/1_modem.png) ROTO · MODEM · maj7 | ![ABISMO](docs/2_fosa.png) ABISMO · FOSA · min7 |
| ![CINTA](docs/3_vhs.png) CINTA · VHS · maj7 | ![NUBE](docs/4_niebla.png) NUBE · NIEBLA · min |
| ![FALLA](docs/5_falla.png) panne TARTAMUDEO (K2 maintenu) | ![preset](docs/6_preset.png) choix du preset (K3 + E1) |

## Crédits

Créé par [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Publié sous licence MIT.
