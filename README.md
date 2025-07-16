# Meus Dotfiles Arch Linux com Hyprland

Este repositório contém meus arquivos de configuração (`dotfiles`) para minha instalação Arch Linux, com foco no ambiente de janela Hyprland e aplicativos associados.

## Capturas de Tela


## Conteúdo Principal
Este repositório inclui configurações para:
* **Gerenciador de Janelas:** Hyprland
* **Barra de Status:** Waybar
* **Terminal:** Kitty
* **Lançador de Aplicativos:** Wofi
* **Outros:** `.bashrc`, `.zshrc`, `.gitconfig`, etc.

## Instalação e Configuração em uma Nova Máquina

Este guia assume uma instalação básica do Arch Linux com acesso à internet e um usuário com `sudo` configurado.

### 1. Clonar o Repositório Bare e Configurar o Alias

```bash
# Instale o Git se ainda não tiver (opcional, pode já estar no sistema base)
sudo pacman -S git --noconfirm

# Clone o repositório bare de dotfiles
git clone --bare [https://github.com/brunohcorreia/my-arch-configs.git](https://github.com/brunohcorreia/my-arch-configs.git) $HOME/.dotfiles.git

# Crie o alias 'config' (adicione ao seu .bashrc ou .zshrc)
echo "alias config='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'" >> ~/.bashrc   # Ou ~/.zshrc
source ~/.bashrc   # Ou source ~/.zshrc para recarregar o shell

# Configure o Git para não mostrar todos os arquivos não rastreados no HOME
config config --local status.showUntrackedFiles no
```
### 2. Executar o Script de Configuração Essencial

Baixe e execute o script setup.sh que automatiza o restante do processo:

```bash
cd ~
wget [https://raw.githubusercontent.com/brunohcorreia/my-arch-configs/main/setup.sh](https://raw.githubusercontent.com/brunohcorreia/my-arch-configs/main/setup.sh)
chmod +x setup.sh

# **IMPORTANTE:** Revise o script 'setup.sh' antes de executar!
# Ele contém seções que você deve personalizar para seus arquivos /etc/
# e serviços Systemd específicos.

./setup.sh
```
