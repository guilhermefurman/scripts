#!/bin/bash

# Verifica se o script está sendo executado como root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Este script deve ser executado como root. Use sudo."
  exit 1
fi

# Solicita ao usuário o novo hostname
read -p "Digite o novo hostname para o servidor: " novo_hostname

# Verifica se foi digitado algo
if [[ -z "$novo_hostname" ]]; then
  echo "❌ Nenhum hostname foi informado. Saindo."
  exit 1
fi

# Mostra o hostname atual
echo "🔎 Hostname atual: $(hostname)"

# Atualiza o hostname temporariamente
hostnamectl set-hostname "$novo_hostname"

# Atualiza o /etc/hosts (substitui o hostname antigo se existir)
sed -i "s/127.0.1.1.*/127.0.1.1 $novo_hostname/" /etc/hosts

# Confirmação
echo "✅ Hostname alterado com sucesso para: $(hostname)"
