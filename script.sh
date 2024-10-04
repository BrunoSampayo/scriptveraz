#!/bin/bash

# Cores para a saída
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

# Variáveis de estado
PASSWORD_CHANGED="fail"
HOSTNAME_CHANGED="fail"
NTP_CONFIGURED="fail"
COCKPIT_INSTALLED="fail"

# Nome do usuário
USER="sysmo"

# Mensagem inicial
echo -e "${RED}#############################################${NC}"
echo -e "${RED}#                                           #${NC}"
echo -e "${RED}#      Script Auxiliar instalação PDV Veraz #${NC}"
echo -e "${RED}#                                           #${NC}"
echo -e "${RED}#############################################${NC}"

# Função para excluir e criar nova senha
function change_password {
    if id "$USER" &>/dev/null; then
        sudo passwd -d "$USER"
        echo -e "${RED}A senha do usuário $USER foi excluída. Digite uma nova senha:${NC}"
        sudo passwd "$USER" && PASSWORD_CHANGED="ok" || PASSWORD_CHANGED="fail"
    else
        echo -e "${RED}Usuário $USER não encontrado.${NC}"
    fi
}

# Função para renomear o computador
function rename_computer {
    CURRENT_HOSTNAME=$(hostname)
    echo "O nome atual do computador: $CURRENT_HOSTNAME"
    read -p "Digite um novo nome para o computador ou pressione Enter para não alterar: " NEW_HOSTNAME
    
    if [[ -n "$NEW_HOSTNAME" ]]; then
        sudo hostnamectl set-hostname "$NEW_HOSTNAME" && HOSTNAME_CHANGED="ok" || HOSTNAME_CHANGED="fail"
        echo -e "${RED}O nome do computador foi alterado para: $NEW_HOSTNAME${NC}"
    else
        echo -e "${RED}O nome do computador não foi alterado.${NC}"
    fi
}

# Função para configurar o servidor NTP
function configure_ntp {
    echo "Configurando o NTP..."
    echo "NTP=172.16.0.250" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl restart systemd-timesyncd
    echo "Verificando o status da sincronização de tempo..."
    timedatectl timesync-status && NTP_CONFIGURED="ok" || NTP_CONFIGURED="fail"
}

# Função para instalar o Cockpit
function install_cockpit {
    echo "Instalando o Cockpit..."
    if sudo apt -y install cockpit; then
        sudo systemctl enable cockpit.socket
        COCKPIT_INSTALLED="ok"
        echo -e "${RED}Cockpit instalado e habilitado com sucesso.${NC}"
    else
        echo -e "${RED}Falha na instalação do Cockpit.${NC}"
    fi
}

# Loop do menu
while true; do
    echo -e "\n${RED}Escolha uma opção:${NC}"
    echo "1) Excluir e criar nova senha"
    echo "2) Renomear computador"
    echo "3) Definir servidor NTP"
    echo "4) Instalar Cockpit"
    echo "5) Sair"
    read -p "Digite sua opção: " OPTION
    
    case $OPTION in
        1)
            change_password
            ;;
        2)
            rename_computer
            ;;
        3)
            configure_ntp
            ;;
        4)
            install_cockpit
            ;;
        5)
            break
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
done

# Checklist final
echo -e "\n${RED}Checklist:${NC}"
if [ "$PASSWORD_CHANGED" == "ok" ]; then
    echo -e "${RED}✔ A senha do usuário $USER foi alterada.${NC}"
else
    echo -e "${RED}✘ A senha do usuário $USER não foi alterada.${NC}"
fi

if [ "$HOSTNAME_CHANGED" == "ok" ]; then
    echo -e "${RED}✔ O nome do computador foi alterado.${NC}"
else
    echo -e "${RED}✘ O nome do computador não foi alterado.${NC}"
fi

if [ "$NTP_CONFIGURED" == "ok" ]; then
    echo -e "${RED}✔ O NTP foi configurado com sucesso.${NC}"
else
    echo -e "${RED}✘ O NTP não foi configurado corretamente.${NC}"
fi

if [ "$COCKPIT_INSTALLED" == "ok" ]; then
    echo -e "${RED}✔ O Cockpit foi instalado e habilitado.${NC}"
else
    echo -e "${RED}✘ O Cockpit não foi instalado.${NC}"
fi

echo -e "${RED}Processo concluído.${NC}"
