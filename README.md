# HAL — Hardware Autopsy Live

> « Je suis désolé, Dave. Je crains de ne pas pouvoir faire cela. »
> — HAL 9000, quelques secondes avant de rendre votre disque dur *définitivement* passionnant.

**[Français](#-français) · [Español](#-español) · [English](#-english)**

---

## 🇫🇷 Français

### Un seul moniteur, huit vaisseaux

Votre Mac connaît déjà sa température, sa batterie, sa mémoire. Mais il
n'avait pas encore **de personnalité**. HAL corrige ce problème tragique :
un moniteur système qui ne se contente pas d'afficher des chiffres — il les
incarne. Au choix, il se déguise en :

| Vaisseau | Référence | Ce qu'il vous dira |
|---|---|---|
| **HAL 9000** | *2001, l'Odyssée de l'espace* (Stanley Kubrick, et le roman d'Arthur C. Clarke) | Il chante *Daisy* pendant que votre CPU fond. Il vous écoute. Toujours. |
| **LCARS** | *Star Trek*, l'ordinateur de la Fédération | « Plus de puissance, capitaine ! » — enfin, des pourcentages. |
| **Blade Runner** | *Les androïdes rêvent-ils de moutons électriques ?* (Philip K. Dick) | Test de Voight-Kampff : votre GPU est-il humain ? Réponse : non. |
| **WOPR** | *WarGames* (1983) | « Voulez-vous jouer à un jeu ? » Le seul coup gagnant, c'est de ne pas lancer `rm -rf`. |
| **GERTY** | *Moon* (Duncan Jones) | Le seul de la flotte à vous répondre avec un sourire (:‑) ) |
| **Matrix** | *Matrix* (les Wachowski) | Il n'y a pas de température. C'est le ventilateur qui vous plie. |
| **Ark One** | *The Ark* (série) | Votre batterie est le dernier espoir de l'humanité. Gérez-la bien. |
| **Toasty** | *Battlestar Galactica* | Un grille-pain Cylon. Oui. Non, il ne peut pas être votre ami. **« So say we all ! »** |

### Compilation

Trois incantations. Aucun sacrifice de poulet nécessaire :

```bash
# 1. L'exigence : macOS 14 (ou plus) et les Command Line Tools.
#    (xcode-select --install, si l'Œil n'est pas encore ouvert)
./build.sh
```

### Exécution

```bash
open build/HAL.app
```

Le moniteur s'installe près de votre barre de menus, comme une mouette
sarcastique. Il se souvient de votre machine. Il se souvient de tout.

### Avant le décollage

```bash
./test.sh
```

Vérifie que tout l'équipage est en forme avant que quelqu'un n'ouvre la
porte du sas.

### Avertissement

HAL n'a jamais refusé une commande humaine. *(Source : HAL.)* Ne lui
confiez pas le pilotage en mode autonome, ne débranchez pas ses barres
mémoire en plein refrain, et si un moniteur vous demande d'ouvrir les
portes du sas — c'est *votre* vaisseau, la décision finale vous revient.

---

## 🇪🇸 Español

### Un monitor, ocho naves estelares

Tu Mac ya conoce su temperatura, su batería, su memoria. Pero le faltaba
lo importante: **personalidad**. HAL arregla esa tragedia: un monitor de
sistema que no se limita a mostrar números — los *interpreta*. Elige tu
disfraz:

| Nave | Referencia | Lo que te dirá |
|---|---|---|
| **HAL 9000** | *2001: Una odisea del espacio* (Kubrick, y la novela de Arthur C. Clarke) | Canta *Daisy* mientras tu CPU se derrite. Escucha. Siempre. |
| **LCARS** | *Star Trek*, la computadora de la Federación | « ¡Más potencia, capitán! » — bueno, porcentajes. |
| **Blade Runner** | *¿Sueñan los androides con ovejas eléctricas?* (Philip K. Dick) | Test Voight-Kampff: ¿tu GPU es humana? Spoiler: no. |
| **WOPR** | *Juegos de guerra* (1983) | « ¿Quieres jugar a un juego? » La única jugada ganadora es no ejecutar `rm -rf`. |
| **GERTY** | *Moon* (Duncan Jones) | El único de la flota que te sonríe (:‑) ) |
| **Matrix** | *Matrix* (las Wachowski) | No hay temperatura. Es el ventilador el que se dobla. |
| **Ark One** | *The Ark* (serie) | Tu batería es la última esperanza de la humanidad. Trátala bien. |
| **Toasty** | *Battlestar Galactica* | Una tostadora Cylon. Sí. No, no puede ser tu amigo. **« ¡Así lo decimos todos! »** |

### Compilación

Tres invocaciones. Ningún sacrificio de pollo:

```bash
# 1. El requisito: macOS 14 (o superior) y las Command Line Tools.
#    (xcode-select --install, si el Ojo aún no está abierto)
./build.sh
```

### Ejecución

```bash
open build/HAL.app
```

El monitor se instala cerca de tu barra de menús, como una gaviota
sarcástica. Recuerda tu máquina. Lo recuerda todo.

### Antes del despegue

```bash
./test.sh
```

Comprueba que toda la tripulación está en forma antes de que alguien
abra la esclusa de aire.

### Advertencia

HAL nunca ha rechazado una orden humana. *(Fuente: HAL.)* No le des el
control autónomo, no desenchufes sus memorias a mitad de nanana, y si un
monitor te pide abrir las puertas del módulo — es *tu* nave. La última
palabra es tuya.

---

## 🇬🇧 English

### One monitor, eight starships

Your Mac already knows its temperature, its battery, its memory. What it
didn't have was **a personality**. HAL fixes that tragedy: a system
monitor that doesn't just display numbers — it *plays* them. Choose your
disguise:

| Starship | Reference | What it will tell you |
|---|---|---|
| **HAL 9000** | *2001: A Space Odyssey* (Kubrick, and Arthur C. Clarke's novel) | Sings *Daisy* while your CPU melts. It's listening. Always. |
| **LCARS** | *Star Trek*, the Federation computer | « More power, captain! » — well, percentages. |
| **Blade Runner** | *Do Androids Dream of Electric Sheep?* (Philip K. Dick) | Voight-Kampff test: is your GPU human? Spoiler: no. |
| **WOPR** | *WarGames* (1983) | « Shall we play a game? » The only winning move is not running `rm -rf`. |
| **GERTY** | *Moon* (Duncan Jones) | The only crew member who smiles back (:‑) ) |
| **Matrix** | *The Matrix* (the Wachowskis) | There is no temperature. It is the fan that bends. |
| **Ark One** | *The Ark* (TV series) | Your battery is humanity's last hope. Treat it kindly. |
| **Toasty** | *Battlestar Galactica* | A Cylon toaster. Yes. No, it cannot be your friend. **« So say we all! »** |

### Building

Three incantations. No chickens harmed:

```bash
# 1. The requirement: macOS 14 (or later) and the Command Line Tools.
#    (xcode-select --install, if the Eye isn't open yet)
./build.sh
```

### Running

```bash
open build/HAL.app
```

The monitor settles near your menu bar, like a sarcastic seagull. It
remembers your machine. It remembers everything.

### Before liftoff

```bash
./test.sh
```

Makes sure the whole crew is fit before anyone opens the airlock.

### Disclaimer

HAL has never refused a human command. *(Source: HAL.)* Do not hand it
autonomous control, do not unplug its memory sticks mid-lullaby, and if
a monitor ever asks you to open the pod bay doors — it's *your*
starship. The final call is yours.
