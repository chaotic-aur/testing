# Master branch builds of Ahriman
FROM arcan1s/ahriman:edge

# Configuration
ENV AHRIMAN_ARCHITECTURE="x86_64"
ENV AHRIMAN_BUILDER="temeraire"
ENV AHRIMAN_DEBUG=""
ENV AHRIMAN_FORCE_ROOT=""
ENV AHRIMAN_GITHUB_DEPLOYMENT=""
ENV AHRIMAN_GITHUB_OWNER="chaotic-aur"
ENV AHRIMAN_GITHUB_PASSWORD=""
ENV AHRIMAN_GITHUB_REPOSITORY="testing-repo"
ENV AHRIMAN_GITHUB_USERNAME="temeraire"
ENV AHRIMAN_HOST="0.0.0.0"
ENV AHRIMAN_MULTILIB="yes"
ENV AHRIMAN_OAUTH=""
ENV AHRIMAN_OAUTH_CLIENT_ID=""
ENV AHRIMAN_OAUTH_CLIENT_SECRET=""
ENV AHRIMAN_OUTPUT="console"
ENV AHRIMAN_PACKAGER="Garuda Builder <team@garudalinux.org"
ENV AHRIMAN_PACMAN_MIRROR=""
ENV AHRIMAN_PORT=""
ENV AHRIMAN_REPOSITORY="chaotic-aur"
ENV AHRIMAN_REPOSITORY_ROOT="/var/lib/ahriman/ahriman"
ENV AHRIMAN_TELEGRAM=""
ENV AHRIMAN_TELEGRAM_API_KEY=""
ENV AHRIMAN_TELEGRAM_CHAT_ID=""
ENV AHRIMAN_UNIX_SOCKET=""
ENV AHRIMAN_USER="ahriman"
ENV AHRIMAN_VALIDATE_CONFIGURATION="yes"

# Install Chaotic-AUR
RUN pacman-key --init && pacman-key --recv-key 0706B90D37D9B881 3056513887B78AEB \
    --keyserver keyserver.ubuntu.com && pacman-key --lsign-key 0706B90D37D9B881 3056513887B78AEB && \
    pacman --noconfirm -U 'https://geo-mirror.chaotic.cx/chaotic-aur/chaotic-'{keyring,mirrorlist}'.pkg.tar.zst' && \
    echo -e "[chaotic-aur]\\nInclude = /etc/pacman.d/chaotic-mirrorlist" >>/etc/pacman.conf

# Custom entrypoint with more configuration options
COPY "entrypoint.sh" "/usr/local/bin/entrypoint"

# Chaotic-specific configuration
COPY "ahriman.ini" "/etc/ahriman.ini"
COPY "builders" "/etc/chaotic"
