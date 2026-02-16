# WordPress Local Development con Docker + Traefik

Setup automático para levantar sitios WordPress locales con dominios `.test` usando un solo comando. Todos los sitios comparten una sola instancia de MariaDB y phpMyAdmin para gestión centralizada.

## Arquitectura

```
                         ┌─────────────┐
                         │   Traefik   │ :80
                         └──────┬──────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                      │
   mi-sitio.test        blog.test            pma.test
          │                     │                      │
   ┌──────┴──────┐    ┌────────┴───────┐    ┌─────────┴────────┐
   │  WordPress  │    │   WordPress    │    │   phpMyAdmin      │
   │  Container  │    │   Container    │    │   Container       │
   └──────┬──────┘    └────────┬───────┘    └─────────┬────────┘
          │                     │                      │
          └─────────────────────┼──────────────────────┘
                                │
                      ┌─────────┴────────┐
                      │    MariaDB       │
                      │  (una instancia) │
                      │  todas las DBs   │
                      └──────────────────┘
```

## Requisitos

- Fedora Linux (o distribución compatible)
- Docker
- dnsmasq

## Instalación

### 1. Instalar Docker

```bash
sudo dnf install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Iniciar Docker y habilitarlo al arranque
sudo systemctl enable --now docker

# Agregar tu usuario al grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Configurar dnsmasq para dominios `.test`

```bash
# Instalar dnsmasq
sudo dnf install dnsmasq

# Configurar resolución de *.test
echo "address=/.test/127.0.0.1" | sudo tee /etc/NetworkManager/dnsmasq.d/test-tld.conf

# Deshabilitar systemd-resolved (entra en conflicto con dnsmasq)
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# Crear resolv.conf que use dnsmasq
sudo rm -f /etc/resolv.conf
echo -e "nameserver 127.0.0.1\noptions edns0 trust-ad\nsearch ." | sudo tee /etc/resolv.conf

# Reiniciar NetworkManager
sudo systemctl restart NetworkManager
```

**Verificar:**

```bash
ping -c 1 cualquiercosa.test
# Debería resolver a 127.0.0.1
```

### 3. Instalar los scripts

```bash
# Clonar este repositorio
git clone https://github.com/TU_USUARIO/wp-local-docker.git
cd wp-local-docker

# Ejecutar el instalador
./install.sh
```

O manualmente:

```bash
# Crear directorio para los scripts
mkdir -p ~/.local/bin

# Copiar los scripts
cp scripts/wp_install ~/.local/bin/
cp scripts/wp_remove ~/.local/bin/
cp scripts/wp_list ~/.local/bin/

# Hacerlos ejecutables
chmod +x ~/.local/bin/wp_*

# Agregar ~/.local/bin al PATH (si no está)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 4. Crear la infraestructura base

```bash
# Crear directorio para los sitios
mkdir -p ~/wp-sites

# Copiar docker-compose base
cp docker-compose.yml ~/wp-sites/

# Levantar la infraestructura
cd ~/wp-sites && docker compose up -d
```

### 5. Configurar sudo para wp_remove (opcional)

Para que `wp_remove` pueda eliminar archivos creados por WordPress:

```bash
USERNAME=$(whoami)
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/rm -rf /home/$USERNAME/wp-sites/*" | sudo tee /etc/sudoers.d/wp-sites
sudo chmod 0440 /etc/sudoers.d/wp-sites
```

## Uso

### Crear un sitio

```bash
wp_install mi-tienda
# → http://mi-tienda.test

wp_install blog-personal
# → http://blog-personal.test
```

### Listar sitios

```bash
wp_list
```

### Eliminar un sitio

```bash
wp_remove mi-tienda
```

### Acceder a phpMyAdmin

- URL: http://pma.test
- Usuario: `root`
- Contraseña: `wp_root_secret_2024`

## Gestión de la infraestructura

```bash
# Detener todo (Traefik + MariaDB + phpMyAdmin)
cd ~/wp-sites && docker compose down

# Iniciar todo
cd ~/wp-sites && docker compose up -d

# Ver logs de MariaDB
docker logs wp-mariadb

# Ver logs de un sitio específico
docker logs wp-mi-sitio

# Backup de todas las bases de datos
docker exec wp-mariadb mariadb-dump -uroot -pwp_root_secret_2024 --all-databases > backup.sql

# Restaurar backup
docker exec -i wp-mariadb mariadb -uroot -pwp_root_secret_2024 < backup.sql
```

## Estructura de directorios

```
~/wp-sites/
├── docker-compose.yml      # Infraestructura base (Traefik, MariaDB, phpMyAdmin)
├── mi-sitio/
│   ├── docker-compose.yml  # Configuración del sitio
│   ├── wp-content/         # Archivos de WordPress (temas, plugins, uploads)
│   └── .site-info          # Credenciales del sitio
├── otro-sitio/
│   ├── docker-compose.yml
│   ├── wp-content/
│   └── .site-info
└── ...
```

## Notas

- **Una sola instancia de MariaDB** sirve a todos los sitios. Cada sitio tiene su propia base de datos y usuario aislado.
- **phpMyAdmin** en `http://pma.test` te permite ver y gestionar todas las bases de datos desde un solo lugar.
- Los archivos de `wp-content` (temas, plugins, uploads) están en `~/wp-sites/nombre/wp-content/` para edición directa.
- Las credenciales de cada sitio se guardan en `~/wp-sites/nombre/.site-info`.
- Para detener un sitio individual: `cd ~/wp-sites/nombre && docker compose stop`
- Para iniciarlo de nuevo: `cd ~/wp-sites/nombre && docker compose start`

## Personalización

### Cambiar la contraseña root de MariaDB

1. Edita `~/wp-sites/docker-compose.yml` y cambia `MYSQL_ROOT_PASSWORD`
2. Edita `~/.local/bin/wp_install` y `~/.local/bin/wp_remove` y cambia `DB_ROOT_PASSWORD`
3. Recrea la infraestructura: `cd ~/wp-sites && docker compose down -v && docker compose up -d`

## Licencia

MIT
