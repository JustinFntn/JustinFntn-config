# Configuration du terminal sur macOS

Récapitulatif des étapes pour mettre en place un environnement terminal moderne avec Ghostty, FiraCode Nerd Font, Starship (preset Gruvbox Rainbow) et Fastfetch.

## 1. Installation de Ghostty

[Ghostty](https://ghostty.org/) est un émulateur de terminal rapide, écrit en Zig, accéléré par GPU.

```url
https://ghostty.org/download
```

## 2. Installation de FiraCode Nerd Font

La [Nerd Font](https://www.nerdfonts.com/) est nécessaire pour afficher correctement les icônes utilisées par Starship et Fastfetch (glyphes Powerline, Devicons, etc.).

```
https://www.nerdfonts.com/font-downloads
```

Configurer ensuite la police dans Ghostty (`~/.config/ghostty/config`) :

```ini
font-family = FiraCode Nerd Font Mono
font-size = 14
```

Recharger la configuration : redémarrer Ghostty.

## 3. Installation et configuration de Starship (preset Gruvbox Rainbow)

[Starship](https://starship.rs/) est un prompt minimaliste, rapide et hautement personnalisable.

### Installation

```bash
curl -sS https://starship.rs/install.sh | sh
```

### Activation dans le shell

Pour **zsh** (shell par défaut sur macOS), ajouter à la fin de `~/.zshrc` :

```bash
eval "$(starship init zsh)"
```

Pour **bash**, ajouter à la fin de `~/.bashrc` :

```bash
eval "$(starship init bash)"
```

Recharger la configuration :

```bash
source ~/.zshrc
```

### Application du preset Gruvbox Rainbow

Starship fournit des [presets prêts à l'emploi](https://starship.rs/presets/). Pour appliquer **Gruvbox Rainbow** :

```bash
starship preset gruvbox-rainbow -o ~/.config/starship.toml
```

Le fichier `~/.config/starship.toml` contient désormais la configuration du preset. Il peut être édité librement pour personnaliser les modules affichés.

## Vérification finale

Ouvrir un nouvel onglet Ghostty :

- Le prompt Starship doit afficher les couleurs Gruvbox Rainbow avec les icônes Nerd Font.
- `fastfetch` doit s'exécuter automatiquement et afficher les informations système avec le logo Apple coloré.
