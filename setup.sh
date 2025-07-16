#!/bin/bash
#
# Script de Configuração Essencial para Nova Instalação do Arch Linux
#
# Este script automatiza:
# 1. Instalação do Git (se necessário)
# 2. Clonagem do repositório Git bare de dotfiles
# 3. Configuração do alias 'config' para gerenciar dotfiles
# 4. Instalação do yay (se necessário)
# 5. Instalação do Git Credential Manager
# 6. Configuração do helper de credenciais Git
# 7. Checkout dos dotfiles (com opção de backup ou forçar)
# 8. Download e instalação de pacotes (pacman e AUR)
# 9. Copia de arquivos de configuração do /etc/ (REQUER CUSTOMIZAÇÃO)
# 10. Habilitação de serviços Systemd (REQUER CUSTOMIZAÇÃO)

# --- Variáveis de Configuração (EDITAR CONFORME SEU REPOSITÓRIO) ---
GITHUB_USERNAME="brunohcorreia"
DOTFILES_REPO_NAME="my-arch-configs"
DOTFILES_REPO_URL="https://github.com/${GITHUB_USERNAME}/${DOTFILES_REPO_NAME}.git"
DOTFILES_BARE_PATH="${HOME}/.dotfiles.git"
PACMAN_PACKAGES_FILE="packages_pacman.txt"
AUR_PACKAGES_FILE="packages_aur.txt"
# URL base para baixar os arquivos do seu repositório
REPO_RAW_URL="https://raw.githubusercontent.com/${GITHUB_USERNAME}/${DOTFILES_REPO_NAME}/main"

# --- Funções Auxiliares ---
log_info() {
    echo -e "\n\e[1;34mINFO: $1\e[0m"
}

log_success() {
    echo -e "\n\e[1;32mSUCESSO: $1\e[0m"
}

log_warn() {
    echo -e "\n\e[1;33mATENÇÃO: $1\e[0m"
}

log_error() {
    echo -e "\n\e[1;31mERRO: $1\e[0m" >&2
    exit 1
}

# --- Início do Script ---
log_info "Iniciando a configuração essencial da nova instalação Arch Linux..."

# --- 1. Verifique e Instale o Git ---
if ! command -v git &> /dev/null; then
    log_info "Git não encontrado. Instalando Git..."
    sudo pacman -S git --noconfirm || log_error "Falha ao instalar Git."
    log_success "Git instalado."
else
    log_info "Git já está instalado."
fi

# --- 2. Clone o Repositório Git Bare de Dotfiles ---
if [ -d "${DOTFILES_BARE_PATH}" ]; then
    log_warn "Repositório bare de dotfiles (${DOTFILES_BARE_PATH}) já existe. Pulando a clonagem."
else
    log_info "Clonando o repositório bare de dotfiles de ${DOTFILES_REPO_URL} para ${DOTFILES_BARE_PATH}..."
    git clone --bare "${DOTFILES_REPO_URL}" "${DOTFILES_BARE_PATH}" || log_error "Falha ao clonar o repositório bare."
    log_success "Repositório bare clonado com sucesso."
fi

# --- 3. Configure o Alias 'config' ---
log_info "Configurando o alias 'config' para o gerenciamento dos dotfiles..."

ALIAS_LINE="alias config='/usr/bin/git --git-dir=${DOTFILES_BARE_PATH}/ --work-tree=${HOME}'"
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"

# Adiciona ao .bashrc se existir e a linha ainda não estiver lá
if [ -f "${BASHRC}" ] && ! grep -qxF "${ALIAS_LINE}" "${BASHRC}"; then
    echo -e "\n${ALIAS_LINE}" >> "${BASHRC}"
    log_info "Alias 'config' adicionado ao ${BASHRC}."
fi

# Adiciona ao .zshrc se existir e a linha ainda não estiver lá
if [ -f "${ZSHRC}" ] && ! grep -qxF "${ALIAS_LINE}" "${ZSHRC}"; then
    echo -e "\n${ALIAS_LINE}" >> "${ZSHRC}"
    log_info "Alias 'config' adicionado ao ${ZSHRC}."
fi

# Carrega o alias para a sessão atual do script
eval "${ALIAS_LINE}"
log_success "Alias 'config' configurado para esta sessão."

# --- 4. Configure o Git para Não Mostrar Todos os Arquivos Não Rastreáveis ---
log_info "Configurando o Git para não mostrar todos os arquivos não rastreáveis no HOME..."
config config --local status.showUntrackedFiles no || log_error "Falha ao configurar status.showUntrackedFiles."
log_success "Configuração de status.showUntrackedFiles aplicada."

# --- 5. Lidar com o Checkout dos Dotfiles ---
log_info "Preparando para fazer o checkout dos dotfiles para o seu diretório HOME."
log_warn "ATENÇÃO: Este passo pode sobrescrever arquivos existentes no seu HOME!"

read -p "Deseja fazer backup de arquivos existentes antes de sobrescrever? (y/N): " backup_choice
if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
    BACKUP_DIR="${HOME}/dotfiles_original_backup_$(date +%Y%m%d%H%M%S)"
    log_info "Criando diretório de backup: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"

    log_info "Listando arquivos que seriam sobrescritos para backup..."
    # Lista arquivos no repo que podem existir no HOME
    config ls-files | while read -r file; do
        if [ -e "${HOME}/${file}" ] && [ ! -d "${HOME}/${file}" ]; then # Se o arquivo existe e não é um diretório
            log_info "Copiando '${HOME}/${file}' para backup..."
            mkdir -p "$(dirname "${BACKUP_DIR}/${file}")" # Cria a estrutura de diretórios no backup
            cp -r "${HOME}/${file}" "$(dirname "${BACKUP_DIR}/${file}")" || log_warn "Não foi possível copiar '${HOME}/${file}' para backup. Continue manualmente."
        elif [ -d "${HOME}/${file}" ]; then # Se for um diretório, avisa
            log_warn "O diretório '${HOME}/${file}' pode conter arquivos que serão sobrescritos. Considere backup manual."
        fi
    done
    log_success "Backup concluído (verifique ${BACKUP_DIR})."
fi

read -p "Deseja forçar o checkout dos dotfiles (sobrescrever sem perguntar)? (y/N): " force_checkout_choice
if [[ "$force_checkout_choice" =~ ^[Yy]$ ]]; then
    log_warn "Forçando o checkout dos dotfiles. Isso sobrescreverá arquivos sem aviso."
    config checkout -f || log_error "Falha ao forçar o checkout dos dotfiles."
else
    log_info "Fazendo checkout padrão dos dotfiles. Conflitos podem exigir resolução manual."
    config checkout || log_error "Falha ao fazer checkout dos dotfiles. Resolva conflitos ou use 'config checkout -f'."
fi
log_success "Checkout dos dotfiles concluído."

# --- 6. Verifique e Instale o yay (AUR Helper) ---
if ! command -v yay &> /dev/null; then
    log_info "yay não encontrado. Instalando yay (AUR helper)..."
    sudo pacman -S git base-devel --noconfirm || log_error "Falha ao instalar dependências para yay."
    git clone https://aur.archlinux.org/yay.git /tmp/yay || log_error "Falha ao clonar yay do AUR."
    (cd /tmp/yay && makepkg -si --noconfirm) || log_error "Falha ao instalar yay."
    rm -rf /tmp/yay
    log_success "yay instalado com sucesso."
else
    log_info "yay já está instalado."
fi

# --- 7. Instale o Git Credential Manager ---
log_info "Verificando e instalando Git Credential Manager (para autenticação Git HTTPS)."
if ! command -v git-credential-manager &> /dev/null; then
    yay -S git-credential-manager-bin --noconfirm || log_error "Falha ao instalar git-credential-manager-bin."
    log_success "git-credential-manager-bin instalado."
else
    log_info "git-credential-manager já está instalado."
fi

# Configure o helper de credenciais Git (globalmente)
log_info "Configurando o Git para usar o gerenciador de credenciais."
config config --global credential.helper manager || log_error "Falha ao configurar credential.helper."
log_success "Credential helper configurado. Você será solicitado a inserir seu PAT no primeiro push/pull."


# --- 8. Instale os Pacotes ---
log_info "Baixando listas de pacotes do repositório remoto..."
wget "${REPO_RAW_URL}/${PACMAN_PACKAGES_FILE}" -O "${HOME}/${PACMAN_PACKAGES_FILE}" || log_error "Falha ao baixar ${PACMAN_PACKAGES_FILE}."
wget "${REPO_RAW_URL}/${AUR_PACKAGES_FILE}" -O "${HOME}/${AUR_PACKAGES_FILE}" || log_error "Falha ao baixar ${AUR_PACKAGES_FILE}."
log_success "Listas de pacotes baixadas."

log_info "Instalando pacotes do Pacman..."
sudo pacman -S --noconfirm - < "${HOME}/${PACMAN_PACKAGES_FILE}" || log_error "Falha ao instalar pacotes do Pacman."
log_success "Pacotes do Pacman instalados."

log_info "Instalando pacotes do AUR via yay..."
yay -S --noconfirm - < "${HOME}/${AUR_PACKAGES_FILE}" || log_error "Falha ao instalar pacotes do AUR."
log_success "Pacotes do AUR instalados."

# --- 9. Copiar Arquivos de Configuração do /etc/ (REQUER CUSTOMIZAÇÃO MANUAL) ---
log_info "Copiando arquivos de configuração para /etc/ (REQUER CUSTOMIZAÇÃO MANUAL NESTA SEÇÃO)."
log_warn "Esta seção DEVE ser personalizada por você para os arquivos específicos do /etc/ que você versionou."
log_warn "Exemplos (descomente e ajuste conforme necessário):"
#
# sudo mkdir -p /etc/sddm.conf.d/
# sudo cp "${HOME}/.config/sddm/sddm.conf" /etc/sddm.conf
#
# sudo mkdir -p /etc/default/
# sudo cp "${HOME}/etc/default/grub" /etc/default/ # Se você tem uma pasta 'etc' no seu repo
#
# sudo cp "${HOME}/etc/tlp.conf" /etc/ # Exemplo para TLP
#
log_warn "Nenhum arquivo de /etc/ foi copiado automaticamente nesta execução. Faça manualmente ou edite o script."

# --- 10. Habilitar Serviços Systemd (REQUER CUSTOMIZAÇÃO MANUAL) ---
log_info "Habilitando serviços Systemd (REQUER CUSTOMIZAÇÃO MANUAL NESTA SEÇÃO)."
log_warn "Esta seção DEVE ser personalizada por você para os serviços específicos que você usa."
log_warn "Exemplos (descomente e ajuste conforme necessário):"
#
# sudo systemctl enable NetworkManager.service
# sudo systemctl enable sddm.service
# sudo systemctl enable tlp.service
# sudo systemctl enable ufw.service
# sudo systemctl enable bluetooth.service
#
log_warn "Nenhum serviço Systemd foi habilitado automaticamente nesta execução. Faça manualmente ou edite o script."

# --- Finalização ---
log_success "Configuração essencial concluída!"
log_warn "Lembre-se de editar este script para copiar arquivos /etc/ e habilitar serviços Systemd específicos."
log_warn "Pode ser necessário REINICIAR o sistema para que todas as configurações entrem em vigor."

read -p "Deseja reiniciar agora? (y/N): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    log_info "Reiniciando o sistema..."
    sudo systemctl reboot
else
    log_info "Reinício adiado. Por favor, reinicie manualmente quando for conveniente."
fi
