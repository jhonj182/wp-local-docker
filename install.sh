#!/bin/bash
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== WordPress Local Docker Installer ===${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Ejecuta este script desde el directorio del repositorio${NC}"
    exit 1
fi

# Crear directorio de scripts si no existe
mkdir -p ~/.local/bin

# Crear directorio wp-sites si no existe
mkdir -p ~/wp-sites

# Copiar scripts
echo -e "${YELLOW}Copiando scripts...${NC}"
cp scripts/wp_install ~/.local/bin/
cp scripts/wp_remove ~/.local/bin/
cp scripts/wp_list ~/.local/bin/
chmod +x ~/.local/bin/wp_*

# Copiar docker-compose base si no existe
if [ ! -f ~/wp-sites/docker-compose.yml ]; then
    echo -e "${YELLOW}Copiando docker-compose.yml...${NC}"
    cp docker-compose.yml ~/wp-sites/
else
    echo -e "${YELLOW}docker-compose.yml ya existe en ~/wp-sites, omitiendo...${NC}"
fi

# Agregar ~/.local/bin al PATH si no está
if ! echo $PATH | grep -q ".local/bin"; then
    echo -e "${YELLOW}Agregando ~/.local/bin al PATH...${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
fi

# Configurar sudoers para wp_remove
echo ""
echo -e "${YELLOW}Para que wp_remove funcione correctamente, necesitas configurar sudo.${NC}"
read -p "¿Deseas configurar sudoers ahora? (s/N): " config_sudo

if [[ "$config_sudo" == "s" || "$config_sudo" == "S" ]]; then
    USERNAME=$(whoami)
    echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/rm -rf /home/$USERNAME/wp-sites/*" | sudo tee /etc/sudoers.d/wp-sites
    sudo chmod 0440 /etc/sudoers.d/wp-sites
    echo -e "${GREEN}Sudoers configurado.${NC}"
fi

echo ""
echo -e "${GREEN}✅ Instalación completada!${NC}"
echo ""
echo -e "Para comenzar:"
echo -e "  1. Levanta la infraestructura base: ${CYAN}cd ~/wp-sites && docker compose up -d${NC}"
echo -e "  2. Crea tu primer sitio: ${CYAN}wp_install mi-sitio${NC}"
echo ""
echo -e "Si cerraste esta terminal, ejecuta: ${CYAN}source ~/.bashrc${NC}"
