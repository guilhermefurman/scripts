#!/usr/bin/env bash
# Script: setup.sh
# Objetivo: Executar os comandos solicitados sem prompts, exibindo status e parando em erro.

set -euo pipefail

# Impede prompts de pacotes
export DEBIAN_FRONTEND=noninteractive

# -------- Helpers de UX --------
log()  { printf '\n\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; }

trap 'fail "Falha na linha $LINENO. Execução interrompida."' ERR

run() {
  # Executa um comando, mostra saída ao vivo e exibe [OK] ao final
  # Uso: run "Descrição" comando arg1 arg2 ...
  local desc="$1"; shift
  log "$desc"
  # shellcheck disable=SC2068
  "$@" 
  ok "$desc concluída."
}

# -------- Execução --------

# 1) Atualizar ~/.bashrc
run "Atualizando ~/.bashrc" bash -c "cat << 'EOF' > ~/.bashrc
# ~/.bashrc: executed by bash(1) for non-login shells.

export LS_OPTIONS='--color=auto'
alias ll='ls \$LS_OPTIONS -lh'
alias l='ls \$LS_OPTIONS -lhA'
export PATH=\$PATH:/usr/sbin
alias cc='clear'
EOF"

# 2) Recarregar ~/.bashrc
# Nota: 'source' no script afeta só este processo; ainda assim rodamos por completude
run "Carregando ~/.bashrc" bash -c "source ~/.bashrc && echo '? ~/.bashrc atualizado e carregado com sucesso.'"

# 3) Update/upgrade sem prompts
run "apt update"  apt-get update -y
run "apt upgrade" apt-get upgrade -y

# 4) Ajustar timezone
run "Ajustando timezone para America/Sao_Paulo" timedatectl set-timezone America/Sao_Paulo

# 5) Pré-requisitos (certificados, curl, git)
run "Instalando pacotes base (ca-certificates, curl, git)" apt-get install -y ca-certificates curl git

# 6) Preparar keyring do Docker
run "Criando /etc/apt/keyrings (Docker)" install -m 0755 -d /etc/apt/keyrings
run "Baixando chave GPG do Docker" curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
run "Ajustando permissão da chave" chmod a+r /etc/apt/keyrings/docker.asc

# 7) Adicionando repositório do Docker (conforme comandos fornecidos)
run "Configurando repositório APT do Docker" bash -c "echo \
  \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo \"\${UBUNTU_CODENAME:-\$VERSION_CODENAME}\") stable\" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null"

# 8) Atualizar índices
run "apt update (Docker repo)" apt-get update -y

# 9) Instalar Docker Engine e plugins
run "Instalando Docker Engine e plugins" apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 10) Verificar status do serviço Docker (não falhar se inativo)
log "Verificando status do serviço docker"
if systemctl is-active --quiet docker; then
  ok "Docker já está em execução."
else
  log "Docker não está ativo. Iniciando serviço…"
  run "Iniciando serviço docker" systemctl start docker
fi

# 11) Testar Docker (hello-world)
run "Executando teste do Docker (hello-world)" docker run --rm hello-world

# 12) Clonar projeto e entrar no diretório
run "Clonando repositório ticketz" bash -c "cd / && git clone https://github.com/ticketz-oss/ticketz.git"
run "Entrando no diretório do projeto" bash -c "cd /ticketz && pwd && ls -la"

ok "Script finalizado com sucesso! ??"
