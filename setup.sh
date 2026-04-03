#!/usr/bin/env bash
# Script: setup.sh
# Objetivo: Instalacao e configuracao com resumo por etapa, barra de progresso global e log so em erro.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

TOTAL_STEPS=15
_completed=0

fail() {
  printf '\n\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2
}

progress_bar() {
  local completed=$1
  local width=36
  local filled=0
  if (( TOTAL_STEPS > 0 )); then
    filled=$(( completed * width / TOTAL_STEPS ))
  fi
  local bar=""
  local i
  # UTF-8 via hex (Bash 3.x nao expande $'\uXXXX'; sequencias U+2588 / U+2591)
  local fill=$'\xe2\x96\x88'
  local empty=$'\xe2\x96\x91'
  for ((i = 0; i < width; i++)); do
    if (( i < filled )); then
      bar+="$fill"
    else
      bar+="$empty"
    fi
  done
  local pct=0
  if (( TOTAL_STEPS > 0 )); then
    pct=$(( completed * 100 / TOTAL_STEPS ))
  fi
  printf '[%s] %d%%' "$bar" "$pct"
}

show_step_header() {
  local step_num=$1
  local title=$2
  local completed_before=$3
  printf '\n> Etapa %d/%d - %s\n' "$step_num" "$TOTAL_STEPS" "$title"
  progress_bar "$completed_before"
  printf '\n'
}

run_step() {
  local idx=$1
  local title=$2
  shift 2
  show_step_header "$idx" "$title" "$_completed"
  local logfile
  logfile=$(mktemp)
  if ! "$@" >"$logfile" 2>&1; then
    printf '\n'
    fail "Falha na etapa ${idx}: ${title}"
    printf '\n--- Saida do comando (stderr/stdout capturados) ---\n'
    cat "$logfile"
    printf '\n--- fim do log ---\n'
    rm -f "$logfile"
    exit 1
  fi
  rm -f "$logfile"
  _completed=$((_completed + 1))
}

step_hostname() {
  local idx=7
  show_step_header "$idx" "Definir hostname" "$_completed"
  local logfile
  logfile=$(mktemp)
  read -rp "Digite o hostname desejado (Enter para manter o atual): " WANT_HOST || true
  WANT_HOST="${WANT_HOST#"${WANT_HOST%%[![:space:]]*}"}"
  WANT_HOST="${WANT_HOST%"${WANT_HOST##*[![:space:]]}"}"
  if [[ -n "$WANT_HOST" ]]; then
    if ! hostnamectl set-hostname "$WANT_HOST" >"$logfile" 2>&1; then
      printf '\n'
      fail "Falha ao definir hostname: ${WANT_HOST}"
      cat "$logfile"
      rm -f "$logfile"
      exit 1
    fi
  fi
  rm -f "$logfile"
  _completed=$((_completed + 1))
}

# -------- Validacao e confirmacao --------

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  fail "Execute como root, por exemplo: sudo $0"
  exit 1
fi

read -rp "Deseja continuar com a instalacao e configuracao? [Y/N]: " _confirm
case "${_confirm,,}" in
  y|yes|s|sim) ;;
  *)
    printf 'Operacao cancelada pelo usuario.\n'
    exit 0
    ;;
esac

# -------- Etapas --------

# 1) Atualizar ~/.bashrc
run_step 1 "Atualizar bashrc" bash -c "cat << 'EOF' > ~/.bashrc
# ~/.bashrc: executed by bash(1) for non-login shells.

export LS_OPTIONS='--color=auto'
alias ll='ls \$LS_OPTIONS -lh'
alias l='ls \$LS_OPTIONS -lhA'
export PATH=\$PATH:/usr/sbin
alias cc='clear'
EOF"

# 2) Recarregar ~/.bashrc
run_step 2 "Carregar bashrc" bash -c "source ~/.bashrc"

# 3) Update
run_step 3 "apt update" apt-get update -y

# 4) Upgrade
run_step 4 "apt upgrade" apt-get upgrade -y

# 5) Timezone
run_step 5 "Ajustar timezone (America/Sao_Paulo)" timedatectl set-timezone America/Sao_Paulo

# 6) Pacotes base (inclui curl e htop)
run_step 6 "Instalar pacotes base (ca-certificates, curl, git, htop)" \
  apt-get install -y ca-certificates curl git htop

# 7) Hostname (interativo)
step_hostname

# 8) Keyring Docker
run_step 8 "Preparar keyring e chave GPG do Docker" bash -c "
  install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
  chmod a+r /etc/apt/keyrings/docker.asc
"

# 9) Repositorio Docker
run_step 9 "Configurar repositorio APT do Docker" bash -c "echo \
  \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo \"\${UBUNTU_CODENAME:-\$VERSION_CODENAME}\") stable\" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null"

# 10) apt update (com Docker)
run_step 10 "apt update (repositorio Docker)" apt-get update -y

# 11) Docker Engine
run_step 11 "Instalar Docker Engine e plugins" \
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 12) Servico Docker
run_step 12 "Garantir servico Docker ativo" bash -c "
  if systemctl is-active --quiet docker; then
    exit 0
  fi
  systemctl start docker
"

# 13) Teste Docker
run_step 13 "Teste Docker (hello-world)" docker run --rm hello-world

# 14) Ticketz: clone/pull, limpa .env extras, define FRONTEND_HOST com IPv4 192.168.200.x desta maquina
run_step 14 "Repositorio ticketz (clone ou atualizar)" bash -s <<'TICKETZ_SETUP'
set -euo pipefail
if [[ -d /ticketz/.git ]]; then
  git -C /ticketz pull --ff-only
elif [[ ! -e /ticketz ]]; then
  git clone https://github.com/ticketz-oss/ticketz.git /ticketz
else
  echo "Erro: /ticketz ja existe e nao e um clone git (sem .git)." >&2
  exit 1
fi
cd /ticketz || exit 1
rm -rf .env-backend-acme .env-backend-cloudflare .env-cloudflared .env-frontend-acme .env-frontend-cloudflare

FRONTEND_IP=$(ip -4 addr 2>/dev/null | awk '/inet 192\.168\.200\./ { split($2, a, "/"); print a[1]; exit }')
if [[ -z "${FRONTEND_IP}" ]]; then
  echo "Erro: nenhum IPv4 em 192.168.200.x encontrado nesta maquina (ip -4 addr)." >&2
  exit 1
fi

for f in .env-backend-local .env-frontend-local; do
  if [[ ! -f "$f" ]]; then
    echo "Erro: arquivo ${f} nao encontrado em /ticketz." >&2
    exit 1
  fi
  if ! grep -qE '^FRONTEND_HOST=localhost$' "$f"; then
    echo "Erro: linha exata FRONTEND_HOST=localhost nao encontrada em ${f}." >&2
    exit 1
  fi
  sed -i "s/^FRONTEND_HOST=localhost$/FRONTEND_HOST=${FRONTEND_IP}/" "$f"
done

ls -la
TICKETZ_SETUP

# 15) Stack Ticketz em segundo plano (compose local)
run_step 15 "Docker Compose (docker-compose-local.yaml)" bash -c 'cd /ticketz && docker compose -f docker-compose-local.yaml up -d'

# Barra final 100%
printf '\n> Concluido - %d/%d etapas\n' "$TOTAL_STEPS" "$TOTAL_STEPS"
progress_bar "$TOTAL_STEPS"
printf '\n\n\033[1;32m[OK]\033[0m Script finalizado com sucesso.\n\n'

# "printf" do coreutils trata formatos que comecam com "-" como opcoes; usar -- ou %s
printf -- '--- Resumo do sistema ---\n'
printf -- 'Hostname: %s\n' "$(hostname)"
printf -- 'Espaco livre em disco (particao /):\n'
df -h / | tail -n 1 | awk '{printf "  Disponivel: %s (total %s, uso %s, montado em %s)\n", $4, $2, $5, $6}'
printf -- 'Data/hora: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z (%Z)')"
printf '\n'
