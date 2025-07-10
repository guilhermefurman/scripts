#!/bin/bash

# Atualiza os reposit�rios para os oficiais do Debian 12 (Bookworm)
echo "?? Atualizando o sources.list para os reposit�rios oficiais do Debian 12..."

cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

echo "? Reposit�rios atualizados."

# Atualiza a lista de pacotes
echo "?? Executando apt update..."
apt update

# Atualiza os pacotes instalados
echo "?? Executando apt upgrade -y..."
apt upgrade -y

echo "? Sistema atualizado com sucesso."
