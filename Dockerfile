FROM archlinux:base

# image configuration
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

# install environment
## update pacman.conf with multilib
RUN echo "[multilib]" >> "/etc/pacman.conf" && \
    echo "Include = /etc/pacman.d/mirrorlist" >> "/etc/pacman.conf"

## install Chaotic-AUR
RUN pacman-key --init && pacman-key --recv-key 0706B90D37D9B881 3056513887B78AEB \
        --keyserver keyserver.ubuntu.com && pacman-key --lsign-key 0706B90D37D9B881 3056513887B78AEB \
        && pacman --noconfirm -U 'https://geo-mirror.chaotic.cx/chaotic-aur/chaotic-'{keyring,mirrorlist}'.pkg.tar.zst' \
        && echo "[multilib]" >>/etc/pacman.conf && echo "Include = /etc/pacman.d/mirrorlist" >>/etc/pacman.conf && \
        echo -e "[garuda]\\nInclude = /etc/pacman.d/chaotic-mirrorlist\\n[chaotic-aur]\\nInclude = /etc/pacman.d/chaotic-mirrorlist" >>/etc/pacman.conf

## install minimal required packages
RUN pacman --noconfirm -Syu binutils fakeroot git make sudo
## create build user
RUN useradd -m -d "/home/build" -s "/usr/bin/nologin" build && \
    echo "build ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/build"
COPY "ahriman/docker/install-aur-package.sh" "/usr/local/bin/install-aur-package"
## install package dependencies
## darcs is not installed by reasons, because it requires a lot haskell packages which dramatically increase image size
RUN pacman -Sy --noconfirm --asdeps devtools git pyalpm python-cerberus python-inflection python-passlib python-requests python-srcinfo && \
    pacman -Sy --noconfirm --asdeps python-build python-installer python-wheel && \
    pacman -Sy --noconfirm --asdeps breezy mercurial python-aiohttp python-aiohttp-cors python-boto3 python-cryptography python-jinja python-requests-unixsocket python-systemd rsync subversion && \
    runuser -u build -- install-aur-package python-aioauth-client python-aiohttp-apispec-git python-aiohttp-jinja2  \
                                            python-aiohttp-debugtoolbar python-aiohttp-session python-aiohttp-security

# install ahriman
## copy tree
COPY --chown=build "ahriman" "/home/build/ahriman"
## create package archive and install it
RUN cd "/home/build/ahriman" && \
    make VERSION=$(python -c "from src.ahriman.version import __version__; print(__version__)") archlinux && \
    cp ./*-src.tar.xz "package/archlinux" && \
    cd "package/archlinux" && \
    runuser -u build -- makepkg --noconfirm --install --skipchecksums && \
    cd / && rm -r "/home/build/ahriman"

# cleanup unused
RUN find "/var/cache/pacman/pkg" -type f -delete
RUN pacman -Qdtq | pacman -Rscn --noconfirm -

VOLUME ["/var/lib/ahriman"]

# minimal runtime ahriman setup
COPY "entrypoint.sh" "/usr/local/bin/entrypoint"

# chaotic specific configuration
COPY "ahriman.ini" "/etc/ahriman.ini"
COPY "builders" "/etc/chaotic"

ENTRYPOINT ["entrypoint"]
# default command
CMD ["repo-update", "--refresh"]