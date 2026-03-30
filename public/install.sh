#!/usr/bin/env bash
# ============================================================================
# FlashXpress WordPress Stack Installer v3.2.0
# ============================================================================
# Installs a complete WordPress hosting stack:
#   - NGINX with FlashXPRESS FastCGI Cache
#   - MariaDB 11.4
#   - PHP 8.4 (with fallback to 8.3/8.2/8.1)
#   - Redis Object Cache
#   - WP-CLI + Certbot
#   - UFW Firewall + Fail2Ban
#   - fx CLI Tool
#
# Website: https://wp.flashxpress.cloud
# Support:  https://buymeacoffee.com/wasimb
# Made with love by Wasim Akram
# ============================================================================

set -euo pipefail

# ---------- Constants & Branding ----------
readonly FX_VERSION="3.2.0"
readonly FX_TITLE="FlashXpress WordPress Stack"
readonly FX_URL="https://wp.flashxpress.cloud"
readonly FX_SUPPORT="https://buymeacoffee.com/wasimb"

# ---------- Color Codes ----------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# ---------- Helper Functions ----------

fx_print_banner() {
    clear
    echo -e "${MAGENTA}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║                                                          ║"
    echo "  ║   ██████╗ ██████╗  ██████╗██╗  ██╗ ██████╗ ██╗    ██╗  ║"
    echo "  ║  ██╔════╝██╔═══██╗██╔════╝██║ ██╔╝██╔═══██╗██║    ██║  ║"
    echo "  ║  ██║     ██║   ██║██║     █████╔╝ ██║   ██║██║ █╗ ██║  ║"
    echo "  ║  ██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██║███╗██║  ║"
    echo "  ║  ╚██████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝╚███╔███╔╝  ║"
    echo "  ║   ╚═════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝   ║"
    echo "  ║                                                          ║"
    echo "  ║        WordPress Stack Installer v${FX_VERSION}                ║"
    echo "  ║                                                          ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}  Website: ${FX_URL}${NC}"
    echo -e "${CYAN}  Support: ${FX_SUPPORT}${NC}"
    echo -e "${WHITE}  Made with ${RED}❤${WHITE} by Wasim Akram${NC}"
    echo ""
}

fx_info()    { echo -e "${GREEN}[fx]${NC} $*"; }
fx_warn()    { echo -e "${YELLOW}[fx warn]${NC} $*"; }
fx_error()   { echo -e "${RED}[fx error]${NC} $*" >&2; }
fx_step()    { echo -e "${BLUE}[fx]${NC} ${BOLD}==>${NC} $*"; }

fx_detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_VERSION="${VERSION_ID}"
        fx_info "Detected OS: ${PRETTY_NAME}"
    else
        fx_error "Unsupported operating system."
        exit 1
    fi
    case "${OS_ID}" in
        ubuntu) ;;
        *) fx_error "Only Ubuntu is supported. Detected: ${OS_ID}"; exit 1 ;;
    esac
}

fx_check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        fx_error "Please run this script as root or with sudo."
        fx_info "Usage: sudo bash install"
        exit 1
    fi
}

fx_pre_install() {
    fx_step "Setting environment variables..."
    export NEEDRESTART_MODE=a
    export DEBIAN_FRONTEND=noninteractive

    fx_step "Updating system packages..."
    apt-get update -y
    apt-get upgrade -y

    fx_step "Installing basic dependencies..."
    apt-get install -y \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        gnupg \
        lsb-release \
        ufw \
        fail2ban \
        unzip \
        git \
        jq \
        htop \
        tree \
        bc \
        apache2-utils
}

# ---------- NGINX Installation ----------

fx_install_nginx() {
    fx_step "Installing NGINX..."
    apt-get install -y nginx

    # Create FastCGI cache directory
    mkdir -p /var/cache/nginx/fastcgi
    chown -R www-data:www-data /var/cache/nginx/fastcgi

    # Remove default server block
    if [[ -f /etc/nginx/sites-enabled/default ]]; then
        rm -f /etc/nginx/sites-enabled/default
    fi

    # Write FastCGI cache config (inline - no external files)
    fx_step "Configuring FastCGI cache..."
    cat > /etc/nginx/conf.d/fastcgi-cache.conf <<'FCFG'
# FlashXpress FastCGI Cache
fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2 keys_zone=FLASHXPRESS:100m inactive=60m use_temp_path=off;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

# Map upstream cache status to branded X-Cache header
map $upstream_cache_status $fx_cache_status {
    default        "FlashXpress MISS";
    HIT            "FlashXpress HIT";
    MISS           "FlashXpress MISS";
    BYPASS         "FlashXpress BYPASS";
    EXPIRED        "FlashXpress EXPIRED";
    STALE          "FlashXpress STALE";
    UPDATING       "FlashXpress UPDATING";
    REVALIDATED    "FlashXpress REVALIDATED";
}
FCFG

    # Write custom FastCGI params (inline)
    cat > /etc/nginx/fastcgi_params <<'FPARAM'
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;
fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  REQUEST_SCHEME     $scheme;
fastcgi_param  HTTPS              $https if_not_empty;
fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;
fastcgi_param  REDIRECT_STATUS    200;
fastcgi_param  PATH_INFO          $fastcgi_path_info;
fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
fastcgi_param  HTTP_HOST          $host;
fastcgi_param  HTTP_USER_AGENT    $http_user_agent;
fastcgi_param  HTTP_REFERER       $http_referer;
fastcgi_param  HTTP_COOKIE        $http_cookie;
fastcgi_param  HTTP_ACCEPT        $http_accept;
fastcgi_param  HTTP_ACCEPT_ENCODING $http_accept_encoding;
fastcgi_buffer_size             128k;
fastcgi_buffers                4 256k;
fastcgi_busy_buffers_size      256k;
FPARAM

    # Create NGINX main config with FastCGI cache include
    cat > /etc/nginx/nginx.conf <<'NGINX_CONF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log warn;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 256M;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # Logging
    access_log /var/log/nginx/access.log;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    # FlashXpress FastCGI Cache
    include /etc/nginx/conf.d/fastcgi-cache.conf;

    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGINX_CONF

    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    systemctl enable nginx
    systemctl start nginx
    fx_info "NGINX installed and configured with FlashXPRESS FastCGI cache."
}

# ---------- MariaDB Installation ----------

fx_install_mariadb() {
    fx_step "Installing MariaDB 11.4..."

    curl -fsSL https://mariadb.org/mariadb_release_signing_key.asc \
        | gpg --dearmor -o /usr/share/keyrings/mariadb-keyring.gpg 2>/dev/null || true

    cat > /etc/apt/sources.list.d/mariadb.list <<EOF
deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mariadb-keyring.gpg] https://mariadb.mirror.ultimum.io/repo/11.4/ubuntu $(lsb_release -sc) main
EOF

    apt-get update -y
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y mariadb-server

    systemctl enable mariadb
    systemctl start mariadb

    fx_step "Securing MariaDB installation..."
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -e "FLUSH PRIVILEGES;"

    fx_info "MariaDB 11.4 installed and secured."
}

# ---------- PHP Installation ----------

fx_install_php() {
    fx_step "Adding ondrej/php PPA..."
    add-apt-repository -y ppa:ondrej/php
    apt-get update -y

    local php_version=""
    local php_available_versions=("8.4" "8.3" "8.2" "8.1")

    for ver in "${php_available_versions[@]}"; do
        if apt-cache show php${ver}-fpm &>/dev/null; then
            php_version="${ver}"
            break
        fi
    done

    if [[ -z "${php_version}" ]]; then
        fx_error "No suitable PHP version found (tried: ${php_available_versions[*]})."
        exit 1
    fi

    fx_info "Installing PHP ${php_version}..."

    apt-get install -y \
        php${php_version}-fpm \
        php${php_version}-mysql \
        php${php_version}-xml \
        php${php_version}-mbstring \
        php${php_version}-curl \
        php${php_version}-zip \
        php${php_version}-gd \
        php${php_version}-intl \
        php${php_version}-redis \
        php${php_version}-imagick \
        php${php_version}-cli \
        php${php_version}-common \
        php${php_version}-readline \
        php${php_version}-soap \
        php${php_version}-bcmath \
        php${php_version}-opcache

    # Disable older PHP versions
    for ver in "${php_available_versions[@]}"; do
        if [[ "${ver}" != "${php_version}" ]] && systemctl list-unit-files | grep -q "php${ver}-fpm"; then
            systemctl disable php${ver}-fpm 2>/dev/null || true
            systemctl stop php${ver}-fpm 2>/dev/null || true
        fi
    done

    # Write PHP security config (inline)
    cat > /etc/php/${php_version}/fpm/conf.d/disabled-functions.ini <<'PHPSEC'
; FlashXpress PHP Security Configuration
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,
curl_exec,curl_multi_exec,parse_ini_file,show_source,
phpinfo,posix_getpwuid,posix_getgrgid,posix_kill,
error_log,ini_set,ini_alter,ini_restore,dl,
putenv,getmypid,get_current_user,getmyuid

max_execution_time = 300
max_input_time = 300
memory_limit = 512M
upload_max_filesize = 256M
post_max_size = 256M
expose_php = Off
display_errors = Off
log_errors = On
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT

session.cookie_httponly = 1
session.use_strict_mode = 1
session.cookie_secure = 1
session.use_only_cookies = 1

file_uploads = On
max_file_uploads = 20
cgi.fix_pathinfo = 0
PHPSEC

    # PHP-FPM Configuration tweaks
    PHP_INI="/etc/php/${php_version}/fpm/php.ini"
    if [[ -f "${PHP_INI}" ]]; then
        sed -i 's/;upload_max_filesize = 2M/upload_max_filesize = 256M/' "${PHP_INI}"
        sed -i 's/;post_max_size = 8M/post_max_size = 256M/' "${PHP_INI}"
        sed -i 's/;max_execution_time = 30/max_execution_time = 300/' "${PHP_INI}"
        sed -i 's/;memory_limit = 128M/memory_limit = 512M/' "${PHP_INI}"
        sed -i 's/max_input_time = 60/max_input_time = 300/' "${PHP_INI}"
        sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' "${PHP_INI}"
        sed -i 's/expose_php = On/expose_php = Off/' "${PHP_INI}"
    fi

    PHP_POOL="/etc/php/${php_version}/fpm/pool.d/www.conf"
    if [[ -f "${PHP_POOL}" ]]; then
        sed -i 's/^;security.limit_extensions = .*/security.limit_extensions = .php/' "${PHP_POOL}"
    fi

    mkdir -p /etc/flashxpress
    echo "${php_version}" > /etc/flashxpress/php-version

    systemctl enable php${php_version}-fpm
    systemctl restart php${php_version}-fpm
    fx_info "PHP ${php_version} installed and configured."
}

# ---------- Redis Installation ----------

fx_install_redis() {
    fx_step "Installing Redis server..."
    apt-get install -y redis-server

    # Write Redis config (inline)
    cat > /etc/redis/redis.conf <<'REDISCONF'
# FlashXpress Redis Configuration for WordPress Object Cache
bind 127.0.0.1 ::1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

daemonize yes
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
databases 16

save 900 1
save 300 10
save 60 10000

stop-writes-on-bgsave-error no
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis

replica-serve-stale-data yes
replica-read-only yes

maxmemory 256mb
maxmemory-policy allkeys-lru
maxmemory-samples 5

lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
replica-lazy-flush yes

rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""

maxclients 10000

slowlog-log-slower-than 10000
slowlog-max-len 128

latency-monitor-threshold 0

appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
REDISCONF

    systemctl enable redis-server
    systemctl restart redis-server
    fx_info "Redis installed and configured for WordPress object cache."
}

# ---------- WP-CLI Installation ----------

fx_install_wp_cli() {
    fx_step "Installing WP-CLI..."
    if command -v wp &>/dev/null; then
        fx_info "WP-CLI is already installed."
        return 0
    fi

    curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
    chmod +x /usr/local/bin/wp
    wp --info --allow-root >/dev/null 2>&1
    fx_info "WP-CLI installed successfully."
}

# ---------- Certbot Installation ----------

fx_install_certbot() {
    fx_step "Installing Certbot (Let's Encrypt)..."
    apt-get install -y certbot python3-certbot-nginx
    fx_info "Certbot installed successfully."
}

# ---------- UFW Firewall Configuration ----------

fx_install_ufw() {
    fx_step "Configuring UFW firewall..."

    # Write UFW application profiles (inline)
    cat >> /etc/ufw/applications.ini <<'UFWCONF'

[Nginx Full]
title=Nginx HTTP and HTTPS
description=Web server (NGINX) with HTTP and HTTPS traffic
ports=80,443/tcp

[Nginx HTTP]
title=Nginx HTTP
description=Web server (NGINX) with HTTP traffic
ports=80/tcp

[Nginx HTTPS]
title=Nginx HTTPS
description=Web server (NGINX) with HTTPS traffic
ports=443/tcp
UFWCONF

    ufw --force reset
    ufw allow OpenSSH
    ufw allow 'Nginx Full'
    ufw --force enable

    fx_info "UFW firewall configured (ports 22, 80, 443)."
}

# ---------- Fail2Ban Configuration ----------

fx_install_fail2ban() {
    fx_step "Configuring Fail2Ban..."

    # Write Fail2Ban filter (inline)
    cat > /etc/fail2ban/filter.d/nginx-limit-req.conf <<'F2BCONF'
# Fail2Ban Filter: NGINX Rate Limiting - FlashXpress
[Definition]
failregex = ^.*\[error\] \d+#\d+: \*\d+ limiting requests by zone ".*", client: <HOST>.*$
ignoreregex =
F2BCONF

    # Write Fail2Ban jail config (inline)
    cat > /etc/fail2ban/jail.local <<'F2BJAIL'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sender = root@localhost

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 5
findtime = 60
bantime = 3600
F2BJAIL

    systemctl enable fail2ban
    systemctl restart fail2ban
    fx_info "Fail2Ban configured with NGINX rate limiting protection."
}

# ---------- FX CLI Tool Installation ----------

fx_install_cli() {
    fx_step "Installing fx CLI tool..."
    mkdir -p /etc/flashxpress /var/log/flashxpress /var/lib/flashxpress/backups

    # Download fx CLI from FlashXpress website
    fx_info "Downloading fx CLI from ${FX_URL}/fx.sh ..."
    if curl -fsSL "${FX_URL}/fx.sh" -o /usr/local/bin/fx 2>/dev/null; then
        chmod +x /usr/local/bin/fx
        fx_info "fx CLI tool installed at /usr/local/bin/fx"
    else
        fx_warn "Failed to download fx CLI from ${FX_URL}/fx.sh"
        fx_warn "You can install it manually later."
    fi
}

# ---------- Completion Banner ----------

fx_print_completion() {
    local php_ver=""
    if [[ -f /etc/flashxpress/php-version ]]; then
        php_ver=$(cat /etc/flashxpress/php-version)
    fi

    echo ""
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║                                                          ║"
    echo -e "  ║  ${BOLD}${GREEN}  Installation Complete!${NC}${GREEN}                              ║"
    echo "  ║                                                          ║"
    echo "  ║  ${CYAN}NGINX${GREEN}        : Running with FlashXPRESS FastCGI Cache ║"
    echo "  ║  ${CYAN}MariaDB${GREEN}      : v11.4 (Secured)                        ║"
    echo "  ║  ${CYAN}PHP${GREEN}          : ${php_ver:-installed}                                      "
    echo "  ║  ${CYAN}Redis${GREEN}        : Running (Object Cache)                 ║"
    echo "  ║  ${CYAN}WP-CLI${GREEN}       : Installed                             ║"
    echo "  ║  ${CYAN}Certbot${GREEN}      : Installed (Let's Encrypt)              ║"
    echo "  ║  ${CYAN}UFW${GREEN}          : Active (22, 80, 443)                   ║"
    echo "  ║  ${CYAN}Fail2Ban${GREEN}     : Running                               ║"
    echo "  ║  ${CYAN}fx CLI${GREEN}       : Installed                             ║"
    echo "  ║                                                          ║"
    echo -e "  ║  ${WHITE}Step 2: Create WordPress site:${GREEN}                    ║"
    echo -e "  ║  ${CYAN}  fx site create example.com${GREEN}                       ║"
    echo "  ║                                                          ║"
    echo -e "  ║  ${WHITE}Step 3: Install SSL certificate:${GREEN}                  ║"
    echo -e "  ║  ${CYAN}  fx ssl install example.com${GREEN}                        ║"
    echo "  ║                                                          ║"
    echo -e "  ║  ${DIM}Check cache: curl -I https://example.com${GREEN}             ║"
    echo "  ║                                                          ║"
    echo "  ║  ${WHITE}Run ${CYAN}'fx help'${WHITE} to see all available commands.${GREEN}        ║"
    echo "  ║                                                          ║"
    echo "  ║  ${YELLOW}Website : ${FX_URL}${GREEN}                   ║"
    echo "  ║  ${YELLOW}Support : ${FX_SUPPORT}${GREEN}     ║"
    echo "  ║                                                          ║"
    echo -e "  ║  Made with ${RED}❤${GREEN} by Wasim Akram                            ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# ---------- Main Installation ----------

main() {
    fx_print_banner
    fx_detect_os
    fx_check_root

    fx_info "Starting FlashXpress v${FX_VERSION} installation..."
    fx_info "This may take a few minutes depending on your server."
    echo ""

    fx_pre_install
    fx_install_nginx
    fx_install_mariadb
    fx_install_php
    fx_install_redis
    fx_install_wp_cli
    fx_install_certbot
    fx_install_ufw
    fx_install_fail2ban
    fx_install_cli

    fx_print_completion
}

main "$@"
