#!/bin/bash

# Verifica se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "? Este script precisa ser executado como root. Use: sudo ./atualiza_fuso_sao_paulo.sh"
  exit 1
fi

# Define o fuso horário para America/Sao_Paulo
echo "? Atualizando o fuso horário para America/Sao_Paulo..."
timedatectl set-timezone America/Sao_Paulo

# Confirmação
echo "? Fuso horário atualizado com sucesso!"
timedatectl
