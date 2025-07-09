#!/bin/bash

# Verifica se est� sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "? Este script precisa ser executado como root. Use: sudo ./atualiza_fuso_sao_paulo.sh"
  exit 1
fi

# Define o fuso hor�rio para America/Sao_Paulo
echo "? Atualizando o fuso hor�rio para America/Sao_Paulo..."
timedatectl set-timezone America/Sao_Paulo

# Confirma��o
echo "? Fuso hor�rio atualizado com sucesso!"
timedatectl
