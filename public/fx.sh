#!/usr/bin/env bash
# ============================================================================
# fx CLI Tool - FlashXpress WordPress Stack Manager v3.2.0
# ============================================================================
# The main command-line interface for managing FlashXpress installations.
#
# Website: https://wp.flashxpress.cloud
# Support:  https://buymeacoffee.com/wasimb
# Made with love by Wasim Akram
# ============================================================================

set -euo pipefail

# ---------- Constants ----------
readonly FX_VERSION="3.2.0"
readonly FX_URL="https://wp.flashxpress.cloud"
readonly FX_SUPPORT="https://buymeacoffee.com/wasimb"
readonly FX_CONF_DIR="/etc/flashxpress"
readonly FX_BACKUP_DIR="/var/lib/flashxpress/backups"
readonly FX_LOG_DIR="/var/log/flashxpress"
readonly FX_SITES_DIR="/var/www"

# ---------- Colors ----------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# ---------- Helper Functions ----------

fx_info()  { echo -e "${GREEN}[fx]${NC} $*"; }
fx_warn()  { echo -e "${YELLOW}[fx warn]${NC} $*"; }
fx_error() { echo -e "${RED}[fx error]${NC} $*" >&2; }
fx_step()  { echo -e "${BLUE}[fx]${NC} ${BOLD}==>${NC} $*"; }

# Generate a random secure password
fx_gen_password() {
    openssl rand -base64 16 | tr -d '/+=' | head -c 24
}

# Generate a MySQL-safe password
fx_gen_db_password() {
    openssl rand -base64 24 | tr -d '/+=' | head -c 20
}

# Get active PHP version
fx_get_php_version() {
    if [[ -f "${FX_CONF_DIR}/php-version" ]]; then
        cat "${FX_CONF_DIR}/php-version"
    else
        # Auto-detect
        php_version=""
        for ver in 8.4 8.3 8.2 8.1; do
            if systemctl is-active --quiet "php${ver}-fpm" 2>/dev/null; then
                php_version="${ver}"
                break
            fi
        done
        echo "${php_version}"
    fi
}

# Validate domain name
fx_validate_domain() {
    local domain="$1"
    if [[ ! "${domain}" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        fx_error "Invalid domain name: ${domain}"
        return 1
    fi
}

# Validate a command requires root
fx_check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        fx_error "This command requires root privileges. Use sudo."
        exit 1
    fi
}

# ---------- Command: fx status ----------

cmd_status() {
    fx_check_root
    echo -e "${BOLD}${CYAN}  FlashXpress System Status${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"

    # NGINX
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "  NGINX          ${GREEN}● Running${NC}"
    else
        echo -e "  NGINX          ${RED}● Stopped${NC}"
    fi

    # MariaDB
    if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
        echo -e "  MariaDB        ${GREEN}● Running${NC}"
    else
        echo -e "  MariaDB        ${RED}● Stopped${NC}"
    fi

    # PHP-FPM
    local php_ver
    php_ver=$(fx_get_php_version)
    if [[ -n "${php_ver}" ]] && systemctl is-active --quiet "php${php_ver}-fpm" 2>/dev/null; then
        echo -e "  PHP-FPM ${php_ver}  ${GREEN}● Running${NC}"
    else
        echo -e "  PHP-FPM        ${RED}● Stopped${NC}"
    fi

    # Redis
    if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
        echo -e "  Redis          ${GREEN}● Running${NC}"
    else
        echo -e "  Redis          ${RED}● Stopped${NC}"
    fi

    # Fail2Ban
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        echo -e "  Fail2Ban       ${GREEN}● Running${NC}"
    else
        echo -e "  Fail2Ban       ${RED}● Stopped${NC}"
    fi

    # UFW
    local ufw_status
    ufw_status=$(ufw status 2>/dev/null | head -1 || echo "inactive")
    if echo "${ufw_status}" | grep -qi "active"; then
        echo -e "  UFW            ${GREEN}● Active${NC}"
    else
        echo -e "  UFW            ${YELLOW}● Inactive${NC}"
    fi

    # WP-CLI
    if command -v wp &>/dev/null; then
        echo -e "  WP-CLI         ${GREEN}● Installed${NC}"
    else
        echo -e "  WP-CLI         ${RED}● Not Found${NC}"
    fi

    # Certbot
    if command -v certbot &>/dev/null; then
        echo -e "  Certbot        ${GREEN}● Installed${NC}"
    else
        echo -e "  Certbot        ${RED}● Not Found${NC}"
    fi

    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
    echo -e "  FlashXpress   ${WHITE}v${FX_VERSION}${NC}"
    echo ""
}

# ---------- Command: fx version ----------

cmd_version() {
    echo -e "${MAGENTA}${BOLD}FlashXpress${NC} ${CYAN}v${FX_VERSION}${NC}"
    echo -e "${DIM}WordPress Stack Manager${NC}"
    echo -e "${DIM}${FX_URL}${NC}"
}

# ---------- Command: fx ssl ----------

cmd_ssl() {
    fx_check_root
    local subcmd="${1:-}"
    shift || true

    case "${subcmd}" in
        install)
            local domain="${1:-}"
            if [[ -z "${domain}" ]]; then
                fx_error "Usage: fx ssl install <domain>"
                exit 1
            fi
            fx_validate_domain "${domain}"
            fx_step "Installing SSL certificate for ${domain}..."

            # Get PHP version
            local php_ver
            php_ver=$(fx_get_php_version)

            # Get site directory
            local site_dir="${FX_SITES_DIR}/${domain}"
            if [[ ! -d "${site_dir}" ]]; then
                fx_error "Site directory not found: ${site_dir}"
                fx_error "Create the site first with: fx site create ${domain}"
                exit 1
            fi

            # Ensure letsencrypt dir exists
            mkdir -p /var/www/letsencrypt

            # Get SSL certificate first (without --nginx to avoid config overwrite)
            certbot certonly --webroot -w /var/www/letsencrypt \
                -d "${domain}" -d "www.${domain}" \
                --non-interactive --agree-tos -m "admin@${domain}" 2>/dev/null || \
            certbot certonly --standalone \
                -d "${domain}" -d "www.${domain}" \
                --non-interactive --agree-tos -m "admin@${domain}" 2>/dev/null

            if [[ ! -d "/etc/letsencrypt/live/${domain}" ]]; then
                fx_error "SSL certificate installation failed."
                exit 1
            fi

            # Generate NGINX HTTPS config (preserving all FlashXpress settings)
            fx_step "Updating NGINX configuration for HTTPS..."
            cat > "/etc/nginx/sites-available/${domain}" <<NGINXSSL
# FlashXpress Server Block - ${domain} (SSL)
# HTTP -> HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};

    # Let's Encrypt challenge
    location ^~ /.well-known/acme-challenge/ {
        allow all;
        root /var/www/letsencrypt;
    }

    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS server block
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${domain} www.${domain};

    # SSL Configuration
    ssl_certificate     /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;

    # Site root
    root ${site_dir};
    index index.php index.html;

    # Access and error logs
    access_log /var/log/nginx/${domain}.access.log;
    error_log /var/log/nginx/${domain}.error.log;

    # FastCGI Cache bypass conditions
    set \$skip_cache 0;
    if (\$request_method = POST) { set \$skip_cache 1; }
    if (\$query_string != "") { set \$skip_cache 1; }
    if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") { set \$skip_cache 1; }
    if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") { set \$skip_cache 1; }

    # Main location block
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP handling with FastCGI Cache
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php${php_ver}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_intercept_errors on;

        # FastCGI Cache
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        fastcgi_cache FLASHXPRESS;
        fastcgi_cache_valid 200 301 302 60m;
        fastcgi_cache_valid 404 1m;
        fastcgi_cache_use_stale error timeout updating invalid_header http_500 http_503;
        fastcgi_cache_lock on;
        fastcgi_cache_min_uses 1;

        # Security Headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # FlashXpress Cache Status Header
        add_header X-Cache "\$fx_cache_status" always;

        # FastCGI timeouts
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|otf|mp4|webm|ogg|mp3)$ {
        expires 365d;
        access_log off;
        add_header Cache-Control "public, immutable";
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to sensitive WordPress files
    location ~* /(?:xmlrpc\.php|wp-config\.php|readme\.html|license\.txt)$ {
        deny all;
    }

    # Rate limiting for wp-login.php
    location = /wp-login.php {
        limit_req zone=fxlimit burst=5 nodelay;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php${php_ver}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    # Limit upload size
    client_max_body_size 256M;

    # Rate limit zone
    limit_req_zone \$binary_remote_addr zone=fxlimit:10m rate=10r/s;
}
NGINXSSL

            # Test and reload NGINX
            nginx -t 2>/dev/null && systemctl reload nginx
            fx_info "SSL certificate installed for ${domain}"
            echo -e "  ${GREEN}HTTPS is now active!${NC}"
            echo -e "  Visit: ${CYAN}https://${domain}/wp-admin${NC}"
            echo ""
            echo -e "  ${DIM}Verify cache: curl -I https://${domain}${NC}"
            echo -e "  ${DIM}Look for: X-Cache: FlashXpress HIT${NC}"
            echo ""
            ;;
        renew)
            local domain="${1:-}"
            if [[ -z "${domain}" ]]; then
                fx_step "Renewing all SSL certificates..."
                certbot renew --quiet
            else
                fx_validate_domain "${domain}"
                fx_step "Renewing SSL certificate for ${domain}..."
                certbot renew --cert-name "${domain}" --quiet
            fi
            fx_info "SSL certificate(s) renewed."
            ;;
        remove)
            local domain="${1:-}"
            if [[ -z "${domain}" ]]; then
                fx_error "Usage: fx ssl remove <domain>"
                exit 1
            fi
            fx_validate_domain "${domain}"
            fx_step "Removing SSL certificate for ${domain}..."
            certbot delete --cert-name "${domain}" --non-interactive
            fx_info "SSL certificate removed for ${domain}"
            ;;
        *)
            fx_error "Unknown ssl command: ${subcmd}"
            fx_error "Usage: fx ssl {install|renew|remove} <domain>"
            exit 1
            ;;
    esac
}

# ---------- Command: fx auth ----------

cmd_auth() {
    fx_check_root
    local subcmd="${1:-}"
    shift || true

    case "${subcmd}" in
        on)
            local domain="${1:-}"
            if [[ -z "${domain}" ]]; then
                fx_error "Usage: fx auth on <domain>"
                exit 1
            fi
            fx_validate_domain "${domain}"
            fx_step "Enabling basic auth for ${domain}..."
            htpasswd -cb "/etc/nginx/.htpasswd-${domain}" "fxuser" "$(fx_gen_password)" 2>/dev/null
            fx_info "Basic auth enabled for ${domain}. Default user: fxuser"
            fx_info "Change password: fx auth add ${domain} <user>"
            systemctl reload nginx
            ;;
        off)
            local domain="${1:-}"
            if [[ -z "${domain}" ]]; then
                fx_error "Usage: fx auth off <domain>"
                exit 1
            fi
            fx_validate_domain "${domain}"
            fx_step "Disabling basic auth for ${domain}..."
            rm -f "/etc/nginx/.htpasswd-${domain}"
            fx_info "Basic auth disabled for ${domain}."
            systemctl reload nginx
            ;;
        add)
            local domain="${1:-}" user="${2:-}"
            if [[ -z "${domain}" || -z "${user}" ]]; then
                fx_error "Usage: fx auth add <domain> <user>"
                exit 1
            fi
            fx_validate_domain "${domain}"
            fx_step "Adding auth user '${user}' for ${domain}..."
            htpasswd "/etc/nginx/.htpasswd-${domain}" "${user}"
            fx_info "User '${user}' added for ${domain}."
            ;;
        remove)
            local domain="${1:-}" user="${2:-}"
            if [[ -z "${domain}" || -z "${user}" ]]; then
                fx_error "Usage: fx auth remove <domain> <user>"
                exit 1
            fi
            fx_validate_domain "${domain}"
            fx_step "Removing auth user '${user}' for ${domain}..."
            htpasswd -D "/etc/nginx/.htpasswd-${domain}" "${user}" 2>/dev/null || {
                fx_error "User '${user}' not found."
                exit 1
            }
            fx_info "User '${user}' removed for ${domain}."
            ;;
        *)
            fx_error "Unknown auth command: ${subcmd}"
            fx_error "Usage: fx auth {on|off|add|remove} <domain> [user]"
            exit 1
            ;;
    esac
}

# ---------- Command: fx site ----------

cmd_site() {
    fx_check_root
    local subcmd="${1:-}"
    shift || true

    case "${subcmd}" in
        create)
            cmd_site_create "$@"
            ;;
        delete)
            cmd_site_delete "$@"
            ;;
        list)
            cmd_site_list
            ;;
        info)
            cmd_site_info "$@"
            ;;
        *)
            fx_error "Unknown site command: ${subcmd}"
            fx_error "Usage: fx site {create|delete|list|info} <domain>"
            exit 1
            ;;
    esac
}

cmd_site_create() {
    local domain="${1:-}"
    if [[ -z "${domain}" ]]; then
        fx_error "Usage: fx site create <domain>"
        exit 1
    fi
    fx_validate_domain "${domain}"

    local php_ver
    php_ver=$(fx_get_php_version)
    local site_dir="${FX_SITES_DIR}/${domain}"
    local db_name=$(echo "${domain}" | tr -cd 'a-zA-Z0-9_' | head -c 16)_wp
    local db_user=$(echo "${domain}" | tr -cd 'a-zA-Z0-9_' | head -c 12)_usr
    local db_pass=$(fx_gen_db_password)

    # Check if site already exists
    if [[ -d "${site_dir}" ]]; then
        fx_error "Site directory ${site_dir} already exists."
        exit 1
    fi

    fx_info "Creating WordPress site: ${domain}"

    # 1. Create site directory
    fx_step "Creating site directory..."
    mkdir -p "${site_dir}"
    chown -R www-data:www-data "${site_dir}"

    # 2. Create database
    fx_step "Creating database..."
    mysql -e "CREATE DATABASE \`${db_name}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    mysql -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

    # 3. Download WordPress
    fx_step "Downloading WordPress..."
    if command -v wp &>/dev/null; then
        sudo -u www-data wp core download --path="${site_dir}" --quiet --allow-root 2>/dev/null
    else
        curl -fsSL https://wordpress.org/latest.tar.gz | tar -xzf - -C "${site_dir}" --strip-components=1
        chown -R www-data:www-data "${site_dir}"
    fi

    # 4. Create wp-config.php
    fx_step "Configuring WordPress..."
    if command -v wp &>/dev/null; then
        sudo -u www-data wp config create \
            --path="${site_dir}" \
            --dbname="${db_name}" \
            --dbuser="${db_user}" \
            --dbpass="${db_pass}" \
            --dbhost="localhost" \
            --quiet \
            --allow-root 2>/dev/null

        # Add Redis cache constants to wp-config.php
        sudo -u www-data wp config set WP_REDIS_HOST '127.0.0.1' --path="${site_dir}" --quiet --allow-root 2>/dev/null || true
        sudo -u www-data wp config set WP_REDIS_PORT 6379 --path="${site_dir}" --raw --quiet --allow-root 2>/dev/null || true
        sudo -u www-data wp config set WP_CACHE true --path="${site_dir}" --raw --quiet --allow-root 2>/dev/null || true
    else
        # Fallback: create wp-config.php manually
        local wp_salt
        wp_salt=$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/ 2>/dev/null || echo "")
        cat > "${site_dir}/wp-config.php" <<WPCONFIG
<?php
/**
 * WordPress Configuration - Generated by FlashXpress
 */

define('DB_NAME', '${db_name}');
define('DB_USER', '${db_user}');
define('DB_PASSWORD', '${db_pass}');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

\$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_CACHE', true);

if (file_exists(ABSPATH . 'wp-settings.php')) {
    ${wp_salt}
    require_once ABSPATH . 'wp-settings.php';
}
WPCONFIG
        chown www-data:www-data "${site_dir}/wp-config.php"
    fi

    # 5. Create NGINX server block
    fx_step "Creating NGINX configuration..."
    cat > "/etc/nginx/sites-available/${domain}" <<NGINXSITE
# FlashXpress Server Block - ${domain}
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};

    root ${site_dir};
    index index.php index.html;

    # Access and error logs
    access_log /var/log/nginx/${domain}.access.log;
    error_log /var/log/nginx/${domain}.error.log;

    # FastCGI Cache bypass conditions
    set \$skip_cache 0;
    if (\$request_method = POST) { set \$skip_cache 1; }
    if (\$query_string != "") { set \$skip_cache 1; }
    if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") { set \$skip_cache 1; }
    if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") { set \$skip_cache 1; }

    # Let's Encrypt challenge
    location ^~ /.well-known/acme-challenge/ {
        allow all;
        root /var/www/letsencrypt;
    }

    # Main location block
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP handling with FastCGI Cache
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php${php_ver}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_intercept_errors on;

        # FastCGI Cache
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        fastcgi_cache FLASHXPRESS;
        fastcgi_cache_valid 200 301 302 60m;
        fastcgi_cache_valid 404 1m;
        fastcgi_cache_use_stale error timeout updating invalid_header http_500 http_503;
        fastcgi_cache_lock on;
        fastcgi_cache_min_uses 1;

        # Security Headers (must be here - NGINX add_header in location overrides server block)
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()" always;

        # FlashXpress Cache Status Header
        add_header X-Cache "\$fx_cache_status" always;

        # FastCGI timeouts
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|otf|mp4|webm|ogg|mp3)$ {
        expires 365d;
        access_log off;
        add_header Cache-Control "public, immutable";
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to sensitive WordPress files
    location ~* /(?:xmlrpc\.php|wp-config\.php|readme\.html|license\.txt)$ {
        deny all;
    }

    # Rate limiting for wp-login.php
    location = /wp-login.php {
        limit_req zone=fxlimit burst=5 nodelay;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php${php_ver}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    # Limit upload size
    client_max_body_size 256M;

    # Rate limit zone
    limit_req_zone \$binary_remote_addr zone=fxlimit:10m rate=10r/s;
}
NGINXSITE

    # Enable site
    ln -sf "/etc/nginx/sites-available/${domain}" "/etc/nginx/sites-enabled/${domain}"

    # 6. Create letsencrypt dir
    mkdir -p /var/www/letsencrypt

    # 7. Test and reload NGINX
    fx_step "Testing NGINX configuration..."
    nginx -t 2>/dev/null
    systemctl reload nginx

    # 8. Save site info
    mkdir -p "${FX_CONF_DIR}/sites"
    cat > "${FX_CONF_DIR}/sites/${domain}.conf" <<SITECONF
DOMAIN=${domain}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASS=${db_pass}
SITE_DIR=${site_dir}
PHP_VERSION=${php_ver}
CREATED=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
SITECONF
    chmod 600 "${FX_CONF_DIR}/sites/${domain}.conf"

    echo ""
    fx_info "${GREEN}Site created successfully!${NC}"
    echo ""
    echo -e "  ${CYAN}Domain:${NC}     ${domain}"
    echo -e "  ${CYAN}Site Dir:${NC}   ${site_dir}"
    echo -e "  ${CYAN}Database:${NC}   ${db_name}"
    echo -e "  ${CYAN}DB User:${NC}    ${db_user}"
    echo -e "  ${CYAN}DB Pass:${NC}    ${db_pass}"
    echo ""
    echo -e "  ${YELLOW}Important: Save these credentials securely!${NC}"
    echo -e "  ${YELLOW}Database credentials are stored in: ${FX_CONF_DIR}/sites/${domain}.conf${NC}"
    echo ""
    echo -e "  ${WHITE}Next Step:${NC} Install SSL certificate:"
    echo -e "  ${CYAN}  fx ssl install ${domain}${NC}"
    echo ""
    echo -e "  Visit: ${CYAN}http://${domain}/wp-admin${NC} to complete WordPress setup."
    echo ""
}

cmd_site_delete() {
    local domain="${1:-}"
    if [[ -z "${domain}" ]]; then
        fx_error "Usage: fx site delete <domain>"
        exit 1
    fi
    fx_validate_domain "${domain}"

    local site_dir="${FX_SITES_DIR}/${domain}"
    local site_conf="${FX_CONF_DIR}/sites/${domain}.conf"

    if [[ ! -f "${site_conf}" ]]; then
        fx_error "Site ${domain} not found."
        exit 1
    fi

    # Load site config
    source "${site_conf}"

    echo -e "${RED}${BOLD}WARNING: This will permanently delete:${NC}"
    echo -e "  - Site directory: ${site_dir}"
    echo -e "  - Database: ${DB_NAME}"
    echo -e "  - NGINX configuration"
    echo -e "  - SSL certificate"
    echo ""
    read -rp "  Type '${domain}' to confirm deletion: " confirm

    if [[ "${confirm}" != "${domain}" ]]; then
        fx_warn "Deletion cancelled."
        return 0
    fi

    fx_step "Deleting site ${domain}..."

    # Remove NGINX config
    rm -f "/etc/nginx/sites-available/${domain}"
    rm -f "/etc/nginx/sites-enabled/${domain}"

    # Remove SSL certificate
    certbot delete --cert-name "${domain}" --non-interactive 2>/dev/null || true

    # Drop database
    mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`;" 2>/dev/null
    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

    # Remove site directory
    rm -rf "${site_dir}"

    # Remove site config
    rm -f "${site_conf}"

    # Reload NGINX
    nginx -t 2>/dev/null && systemctl reload nginx

    fx_info "Site ${domain} deleted successfully."
}

cmd_site_list() {
    fx_check_root
    local sites=()
    if [[ -d "${FX_CONF_DIR}/sites" ]]; then
        while IFS= read -r conf_file; do
            local domain
            domain=$(basename "${conf_file}" .conf)
            sites+=("${domain}")
        done < <(find "${FX_CONF_DIR}/sites" -name "*.conf" -type f 2>/dev/null)
    fi

    if [[ ${#sites[@]} -eq 0 ]]; then
        fx_warn "No sites found. Create one with: fx site create <domain>"
        return 0
    fi

    echo -e "${BOLD}${CYAN}  FlashXpress Sites${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
    printf "  %-30s %-12s %s\n" "DOMAIN" "PHP" "DIRECTORY"
    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"

    for domain in "${sites[@]}"; do
        local site_conf="${FX_CONF_DIR}/sites/${domain}.conf"
        local php_ver=""
        local site_dir=""

        if [[ -f "${site_conf}" ]]; then
            php_ver=$(grep "^PHP_VERSION=" "${site_conf}" | cut -d= -f2)
            site_dir=$(grep "^SITE_DIR=" "${site_conf}" | cut -d= -f2)
        fi

        printf "  ${GREEN}%-30s${NC} %-12s %s\n" "${domain}" "${php_ver}" "${site_dir}"
    done
    echo ""
}

cmd_site_info() {
    fx_check_root
    local domain="${1:-}"
    if [[ -z "${domain}" ]]; then
        fx_error "Usage: fx site info <domain>"
        exit 1
    fi

    local site_conf="${FX_CONF_DIR}/sites/${domain}.conf"
    if [[ ! -f "${site_conf}" ]]; then
        fx_error "Site ${domain} not found."
        exit 1
    fi

    source "${site_conf}"

    echo -e "${BOLD}${CYAN}  Site Information: ${domain}${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}Domain:${NC}      ${DOMAIN}"
    echo -e "  ${CYAN}Site Dir:${NC}    ${SITE_DIR}"
    echo -e "  ${CYAN}Database:${NC}    ${DB_NAME}"
    echo -e "  ${CYAN}DB User:${NC}     ${DB_USER}"
    echo -e "  ${CYAN}DB Pass:${NC}     ${DB_PASS}"
    echo -e "  ${CYAN}PHP Version:${NC} ${PHP_VERSION}"
    echo -e "  ${CYAN}Created:${NC}     ${CREATED}"

    # Check SSL
    if [[ -d "/etc/letsencrypt/live/${domain}" ]]; then
        local expiry
        expiry=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${domain}/cert.pem" 2>/dev/null | cut -d= -f2)
        echo -e "  ${CYAN}SSL:${NC}        ${GREEN}Active${NC} (expires: ${expiry})"
    else
        echo -e "  ${CYAN}SSL:${NC}        ${RED}Not Installed${NC}"
    fi

    # Disk usage
    if [[ -d "${SITE_DIR}" ]]; then
        local disk_usage
        disk_usage=$(du -sh "${SITE_DIR}" 2>/dev/null | cut -f1)
        echo -e "  ${CYAN}Disk Usage:${NC}  ${disk_usage}"
    fi
    echo ""
}

# ---------- Command: fx db ----------

cmd_db() {
    fx_check_root
    local subcmd="${1:-}"
    shift || true

    case "${subcmd}" in
        password) cmd_db_password "$@" ;;
        create)   cmd_db_create "$@" ;;
        delete)   cmd_db_delete "$@" ;;
        list)     cmd_db_list ;;
        export)   cmd_db_export "$@" ;;
        import)   cmd_db_import "$@" ;;
        *)
            fx_error "Unknown db command: ${subcmd}"
            fx_error "Usage: fx db {create|delete|list|export|import|password} [args]"
            exit 1
            ;;
    esac
}

cmd_db_password() {
    local domain="${1:-}"
    if [[ -z "${domain}" ]]; then
        fx_error "Usage: fx db password <domain>"
        exit 1
    fi

    local site_conf="${FX_CONF_DIR}/sites/${domain}.conf"
    if [[ ! -f "${site_conf}" ]]; then
        fx_error "Site ${domain} not found."
        exit 1
    fi

    source "${site_conf}"

    local new_pass
    new_pass=$(fx_gen_db_password)

    mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${new_pass}';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

    # Update config
    sed -i "s/^DB_PASS=.*/DB_PASS=${new_pass}/" "${site_conf}"
    chmod 600 "${site_conf}"

    # Update wp-config.php
    local site_dir
    site_dir=$(grep "^SITE_DIR=" "${site_conf}" | cut -d= -f2)
    if [[ -f "${site_dir}/wp-config.php" ]]; then
        sed -i "s/define('DB_PASSWORD', '${DB_PASS}')/define('DB_PASSWORD', '${new_pass}')/" "${site_dir}/wp-config.php"
        chown www-data:www-data "${site_dir}/wp-config.php"
    fi

    fx_info "Database password updated for ${domain}."
    fx_info "New password: ${new_pass}"
    echo -e "${YELLOW}Save this password securely!${NC}"
}

cmd_db_create() {
    local db_name="${1:-}"
    if [[ -z "${db_name}" ]]; then
        fx_error "Usage: fx db create <name>"
        exit 1
    fi

    local db_user="${db_name}_user"
    local db_pass=$(fx_gen_db_password)

    mysql -e "CREATE DATABASE \`${db_name}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    mysql -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

    fx_info "Database created:"
    echo -e "  ${CYAN}Database:${NC} ${db_name}"
    echo -e "  ${CYAN}User:${NC}     ${db_user}"
    echo -e "  ${CYAN}Password:${NC} ${db_pass}"
}

cmd_db_delete() {
    local db_name="${1:-}"
    if [[ -z "${db_name}" ]]; then
        fx_error "Usage: fx db delete <name>"
        exit 1
    fi

    read -rp "  Are you sure you want to delete database '${db_name}'? [y/N]: " confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        fx_warn "Cancelled."
        return 0
    fi

    local db_user="${db_name}_user"
    mysql -e "DROP DATABASE IF EXISTS \`${db_name}\`;" 2>/dev/null
    mysql -e "DROP USER IF EXISTS '${db_user}'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    fx_info "Database '${db_name}' deleted."
}

cmd_db_list() {
    echo -e "${BOLD}${CYAN}  Databases${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
    mysql -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "(Database|information_schema|performance_schema|mysql|sys)"
    echo ""
}

cmd_db_export() {
    local database="${1:-}" file="${2:-}"
    if [[ -z "${database}" ]]; then
        fx_error "Usage: fx db export <database> [file]"
        exit 1
    fi

    if [[ -z "${file}" ]]; then
        file="${database}_$(date +%Y%m%d_%H%M%S).sql.gz"
    fi

    fx_step "Exporting database ${database}..."
    mysqldump "${database}" 2>/dev/null | gzip > "${FX_BACKUP_DIR}/${file}"
    fx_info "Database exported to: ${FX_BACKUP_DIR}/${file}"
}

cmd_db_import() {
    local database="${1:-}" file="${2:-}"
    if [[ -z "${database}" || -z "${file}" ]]; then
        fx_error "Usage: fx db import <database> <file>"
        exit 1
    fi

    if [[ ! -f "${file}" && ! -f "${FX_BACKUP_DIR}/${file}" ]]; then
        fx_error "File not found: ${file}"
        exit 1
    fi

    local import_file="${file}"
    if [[ ! -f "${file}" && -f "${FX_BACKUP_DIR}/${file}" ]]; then
        import_file="${FX_BACKUP_DIR}/${file}"
    fi

    fx_step "Importing database ${database}..."
    if [[ "${import_file}" == *.gz ]]; then
        gunzip -c "${import_file}" | mysql "${database}" 2>/dev/null
    else
        mysql "${database}" < "${import_file}" 2>/dev/null
    fi
    fx_info "Database imported successfully."
}

# ---------- Command: fx pma ----------

cmd_pma() {
    fx_check_root
    local subcmd="${1:-}"
    shift || true

    local pma_dir="${FX_SITES_DIR}/phpmyadmin"
    local pma_conf="/etc/nginx/sites-available/phpmyadmin"

    case "${subcmd}" in
        install)
            fx_step "Installing phpMyAdmin..."
            local pma_version="5.2.1"
            local pma_url="https://files.phpmyadmin.net/phpMyAdmin/${pma_version}/phpMyAdmin-${pma_version}-all-languages.tar.gz"

            mkdir -p "${pma_dir}"
            curl -fsSL "${pma_url}" | tar -xzf - -C "${pma_dir}" --strip-components=1
            chown -R www-data:www-data "${pma_dir}"

            # Create temp directory
            mkdir -p "${pma_dir}/tmp"
            chown -R www-data:www-data "${pma_dir}/tmp"

            # Create NGINX config for phpMyAdmin
            local php_ver
            php_ver=$(fx_get_php_version)
            local pma_subdomain="pma.$(hostname -I 2>/dev/null | awk '{print $1}' | tr '.' '-')"

            cat > "${pma_conf}" <<PMA_NGINX
server {
    listen 8080;
    server_name _;

    root ${pma_dir};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php${php_ver}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\. {
        deny all;
    }
}
PMA_NGINX

            ln -sf "${pma_conf}" /etc/nginx/sites-enabled/phpmyadmin
            nginx -t 2>/dev/null && systemctl reload nginx

            # Generate random cookie secret
            local blowfish_secret
            blowfish_secret=$(openssl rand -hex 32)

            # Create config
            cp "${pma_dir}/config.sample.inc.php" "${pma_dir}/config.inc.php"
            sed -i "s/\\\$cfg\['blowfish_secret'\] = '';/\$cfg['blowfish_secret'] = '${blowfish_secret}';/" "${pma_dir}/config.inc.php"
            sed -i "s/\\\$cfg\['Servers'\]\[\\\$i\]\['host'\] = 'localhost';/\$cfg['Servers'][\$i]['host'] = 'localhost';/" "${pma_dir}/config.inc.php"
            chown www-data:www-data "${pma_dir}/config.inc.php"

            fx_info "phpMyAdmin installed."
            fx_info "Access at: ${CYAN}http://$(hostname -I 2>/dev/null | awk '{print $1}'):8080${NC}"
            echo -e "${YELLOW}Set a password with: fx pma password <password>${NC}"
            ;;
        password)
            local password="${1:-}"
            if [[ -z "${password}" ]]; then
                fx_error "Usage: fx pma password <password>"
                exit 1
            fi
            fx_warn "phpMyAdmin uses MariaDB authentication."
            fx_info "To change root MariaDB password:"
            echo -e "  mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY '${password}';\""
            ;;
        remove)
            fx_step "Removing phpMyAdmin..."
            rm -f /etc/nginx/sites-enabled/phpmyadmin
            rm -f "${pma_conf}"
            rm -rf "${pma_dir}"
            nginx -t 2>/dev/null && systemctl reload nginx
            fx_info "phpMyAdmin removed."
            ;;
        *)
            fx_error "Unknown pma command: ${subcmd}"
            fx_error "Usage: fx pma {install|password|remove}"
            exit 1
            ;;
    esac
}

# ---------- Command: fx adminer ----------

cmd_adminer() {
    fx_check_root
    local subcmd="${1:-}"

    local adminer_dir="${FX_SITES_DIR}/adminer"
    local adminer_conf="/etc/nginx/sites-available/adminer"

    case "${subcmd}" in
        install)
            fx_step "Installing Adminer..."
            mkdir -p "${adminer_dir}"
            curl -fsSL https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php -o "${adminer_dir}/index.php"
            chown -R www-data:www-data "${adminer_dir}"

            local php_ver
            php_ver=$(fx_get_php_version)

            cat > "${adminer_conf}" <<ADMINER_NGINX
server {
    listen 8081;
    server_name _;

    root ${adminer_dir};
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php${php_ver}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\. {
        deny all;
    }
}
ADMINER_NGINX

            ln -sf "${adminer_conf}" /etc/nginx/sites-enabled/adminer
            nginx -t 2>/dev/null && systemctl reload nginx

            fx_info "Adminer installed."
            fx_info "Access at: ${CYAN}http://$(hostname -I 2>/dev/null | awk '{print $1}'):8081${NC}"
            ;;
        remove)
            fx_step "Removing Adminer..."
            rm -f /etc/nginx/sites-enabled/adminer
            rm -f "${adminer_conf}"
            rm -rf "${adminer_dir}"
            nginx -t 2>/dev/null && systemctl reload nginx
            fx_info "Adminer removed."
            ;;
        *)
            fx_error "Unknown adminer command: ${subcmd}"
            fx_error "Usage: fx adminer {install|remove}"
            exit 1
            ;;
    esac
}

# ---------- Command: fx files ----------

cmd_files() {
    fx_check_root
    local subcmd="${1:-}"

    local fm_dir="${FX_SITES_DIR}/filemanager"

    case "${subcmd}" in
        install)
            fx_step "Installing TinyFileManager..."
            mkdir -p "${fm_dir}"

            curl -fsSL "https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php" \
                -o "${fm_dir}/index.php" 2>/dev/null || {
                fx_error "Failed to download TinyFileManager."
                exit 1
            }

            # Generate a random admin password
            local admin_pass
            admin_pass=$(fx_gen_password)

            # Set admin credentials (default: admin/admin)
            sed -i "s/\$auth_users = array(.*)/ \$auth_users = array('admin' => '${admin_pass}');/" "${fm_dir}/index.php"

            chown -R www-data:www-data "${fm_dir}"

            fx_info "TinyFileManager installed."
            fx_info "Access at: ${CYAN}https://$(hostname -I 2>/dev/null | awk '{print $1}')/filemanager/${NC}"
            fx_info "Username: admin | Password: ${admin_pass}"
            echo -e "${YELLOW}Save this password securely!${NC}"
            ;;
        remove)
            fx_step "Removing File Manager..."
            rm -rf "${fm_dir}"
            fx_info "File Manager removed."
            ;;
        *)
            fx_error "Unknown files command: ${subcmd}"
            fx_error "Usage: fx files {install|remove}"
            exit 1
            ;;
    esac
}

# ---------- Command: fx cache ----------

cmd_cache() {
    fx_check_root
    local subcmd="${1:-}"

    case "${subcmd}" in
        clear)
            fx_step "Clearing FastCGI cache..."
            if [[ -d /var/cache/nginx/fastcgi ]]; then
                rm -rf /var/cache/nginx/fastcgi/*
                fx_info "FastCGI cache cleared."
            else
                fx_warn "Cache directory not found."
            fi
            ;;
        status)
            echo -e "${BOLD}${CYAN}  FastCGI Cache Status${NC}"
            echo -e "${DIM}  ─────────────────────────────────────────────${NC}"

            if [[ -d /var/cache/nginx/fastcgi ]]; then
                local cache_size
                cache_size=$(du -sh /var/cache/nginx/fastcgi 2>/dev/null | cut -f1)
                local cache_files
                cache_files=$(find /var/cache/nginx/fastcgi -type f 2>/dev/null | wc -l)
                echo -e "  ${CYAN}Cache Size:${NC}    ${cache_size}"
                echo -e "  ${CYAN}Cached Files:${NC}  ${cache_files}"
            else
                echo -e "  Cache directory not found."
            fi
            echo ""
            ;;
        *)
            fx_error "Unknown cache command: ${subcmd}"
            fx_error "Usage: fx cache {clear|status}"
            exit 1
            ;;
    esac
}

# ---------- Command: fx php ----------

cmd_php() {
    fx_check_root
    local subcmd="${1:-}"
    shift || true

    case "${subcmd}" in
        version)
            local current
            current=$(fx_get_php_version)
            echo -e "${CYAN}Current PHP version:${NC} ${BOLD}${current}${NC}"
            echo -e "${DIM}FPM service: php${current}-fpm${NC}"
            ;;
        list)
            echo -e "${BOLD}${CYAN}  Installed PHP Versions${NC}"
            echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
            local current
            current=$(fx_get_php_version)
            for ver in 8.4 8.3 8.2 8.1; do
                if dpkg -l | grep -q "php${ver}-fpm"; then
                    local status
                    if [[ "${ver}" == "${current}" ]]; then
                        status="${GREEN}● Active${NC}"
                    else
                        status="${DIM}○ Installed${NC}"
                    fi
                    echo -e "  PHP ${ver}    ${status}"
                fi
            done
            echo ""
            ;;
        switch)
            local version="${1:-}"
            if [[ -z "${version}" ]]; then
                fx_error "Usage: fx php switch <version>"
                fx_error "Available: 8.4, 8.3, 8.2, 8.1"
                exit 1
            fi

            # Validate version
            case "${version}" in
                8.4|8.3|8.2|8.1) ;;
                *)
                    fx_error "Unsupported PHP version: ${version}"
                    exit 1
                    ;;
            esac

            if ! dpkg -l | grep -q "php${version}-fpm"; then
                fx_error "PHP ${version} is not installed."
                exit 1
            fi

            fx_step "Switching to PHP ${version}..."

            local current
            current=$(fx_get_php_version)

            # Stop current PHP-FPM
            if [[ -n "${current}" && "${current}" != "${version}" ]]; then
                systemctl disable "php${current}-fpm" 2>/dev/null || true
                systemctl stop "php${current}-fpm" 2>/dev/null || true
            fi

            # Enable and start new PHP-FPM
            systemctl enable "php${version}-fpm"
            systemctl start "php${version}-fpm"

            # Update stored version
            echo "${version}" > "${FX_CONF_DIR}/php-version"

            # Update all site NGINX configs to use new PHP socket
            if [[ -d "${FX_CONF_DIR}/sites" ]]; then
                for site_conf_file in "${FX_CONF_DIR}/sites"/*.conf; do
                    [[ -f "${site_conf_file}" ]] || continue
                    local site_domain
                    site_domain=$(basename "${site_conf_file}" .conf)
                    local nginx_conf="/etc/nginx/sites-available/${site_domain}"
                    if [[ -f "${nginx_conf}" ]]; then
                        sed -i "s|php${current}-fpm.sock|php${version}-fpm.sock|g" "${nginx_conf}"
                    fi
                done
                nginx -t 2>/dev/null && systemctl reload nginx
            fi

            fx_info "Switched to PHP ${version}."
            ;;
        restart)
            local php_ver
            php_ver=$(fx_get_php_version)
            systemctl restart "php${php_ver}-fpm"
            fx_info "PHP-FPM ${php_ver} restarted."
            ;;
        *)
            fx_error "Unknown php command: ${subcmd}"
            fx_error "Usage: fx php {version|list|switch|restart} [args]"
            exit 1
            ;;
    esac
}

# ---------- Command: fx backup ----------

cmd_backup() {
    fx_check_root
    local subcmd="${1:-}"
    shift || true

    case "${subcmd}" in
        create)
            local domain="${1:-}"
            if [[ -z "${domain}" ]]; then
                fx_error "Usage: fx backup create <domain>"
                exit 1
            fi

            local site_conf="${FX_CONF_DIR}/sites/${domain}.conf"
            if [[ ! -f "${site_conf}" ]]; then
                fx_error "Site ${domain} not found."
                exit 1
            fi

            source "${site_conf}"

            local backup_name="${domain}_$(date +%Y%m%d_%H%M%S)"
            local backup_file="${FX_BACKUP_DIR}/${backup_name}.tar.gz"

            fx_step "Creating backup for ${domain}..."

            # Create temporary directory for backup
            local tmp_dir
            tmp_dir=$(mktemp -d)

            # Export database
            mysqldump "${DB_NAME}" 2>/dev/null > "${tmp_dir}/database.sql"

            # Copy site files
            cp -a "${SITE_DIR}" "${tmp_dir}/site"

            # Copy site config
            cp "${site_conf}" "${tmp_dir}/site.conf"

            # Create archive
            tar -czf "${backup_file}" -C "${tmp_dir}" .

            # Cleanup
            rm -rf "${tmp_dir}"

            local backup_size
            backup_size=$(du -sh "${backup_file}" | cut -f1)
            fx_info "Backup created: ${backup_file} (${backup_size})"
            ;;
        list)
            echo -e "${BOLD}${CYAN}  FlashXpress Backups${NC}"
            echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
            if [[ -d "${FX_BACKUP_DIR}" ]]; then
                ls -lh "${FX_BACKUP_DIR}"/*.tar.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' || fx_warn "No backups found."
            else
                fx_warn "No backups found."
            fi
            echo ""
            ;;
        restore)
            local backup_file="${1:-}"
            if [[ -z "${backup_file}" ]]; then
                fx_error "Usage: fx backup restore <backup-file>"
                exit 1
            fi

            # Resolve backup file path
            if [[ ! -f "${backup_file}" && -f "${FX_BACKUP_DIR}/${backup_file}" ]]; then
                backup_file="${FX_BACKUP_DIR}/${backup_file}"
            fi

            if [[ ! -f "${backup_file}" ]]; then
                fx_error "Backup file not found: ${backup_file}"
                exit 1
            fi

            fx_warn "Restoring from backup will overwrite existing site data."
            read -rp "  Continue? [y/N]: " confirm
            if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
                fx_warn "Cancelled."
                return 0
            fi

            fx_step "Restoring from ${backup_file}..."

            local tmp_dir
            tmp_dir=$(mktemp -d)
            tar -xzf "${backup_file}" -C "${tmp_dir}"

            # Read site config
            if [[ -f "${tmp_dir}/site.conf" ]]; then
                source "${tmp_dir}/site.conf"
            else
                fx_error "Invalid backup: site.conf not found."
                rm -rf "${tmp_dir}"
                exit 1
            fi

            # Restore database
            mysql "${DB_NAME}" < "${tmp_dir}/database.sql" 2>/dev/null || {
                mysql -e "CREATE DATABASE \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
                mysql "${DB_NAME}" < "${tmp_dir}/database.sql" 2>/dev/null
            }

            # Restore site files
            rm -rf "${SITE_DIR}"
            cp -a "${tmp_dir}/site" "${SITE_DIR}"
            chown -R www-data:www-data "${SITE_DIR}"

            # Restore site config
            mkdir -p "${FX_CONF_DIR}/sites"
            cp "${tmp_dir}/site.conf" "${FX_CONF_DIR}/sites/${DOMAIN}.conf"
            chmod 600 "${FX_CONF_DIR}/sites/${DOMAIN}.conf"

            rm -rf "${tmp_dir}"
            fx_info "Backup restored successfully for ${DOMAIN}."
            ;;
        *)
            fx_error "Unknown backup command: ${subcmd}"
            fx_error "Usage: fx backup {create|list|restore} [args]"
            exit 1
            ;;
    esac
}

# ---------- Command: fx update ----------

cmd_update() {
    fx_check_root
    fx_step "Checking for FlashXpress updates..."

    local tmp_script
    tmp_script=$(mktemp)

    # Download latest installer
    if curl -fsSL "${FX_URL}/install" -o "${tmp_script}" 2>/dev/null; then
        bash "${tmp_script}"
        fx_info "FlashXpress updated to the latest version."
    else
        fx_error "Failed to download update. Check your internet connection."
    fi

    rm -f "${tmp_script}"
}

# ---------- Command: fx help ----------

cmd_help() {
    echo -e "${MAGENTA}${BOLD}"
    echo "  ██████╗ ██████╗  ██████╗██╗  ██╗ ██████╗ ██╗    ██╗"
    echo " ██╔════╝██╔═══██╗██╔════╝██║ ██╔╝██╔═══██╗██║    ██║"
    echo " ██║     ██║   ██║██║     █████╔╝ ██║   ██║██║ █╗ ██║"
    echo " ██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██║███╗██║"
    echo " ╚██████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝╚███╔███╔╝"
    echo "  ╚═════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝"
    echo -e "              WordPress Stack v${FX_VERSION}"
    echo -e "${NC}"
    echo -e "${WHITE}${BOLD}  Usage: fx <command> [subcommand] [args]${NC}"
    echo ""
    echo -e "${BOLD}${CYAN}  Core Commands${NC}"
    echo -e "  ${GREEN}fx status${NC}                   Show system status"
    echo -e "  ${GREEN}fx version${NC}                  Show FlashXpress version"
    echo -e "  ${GREEN}fx update${NC}                   Update FlashXpress"
    echo -e "  ${GREEN}fx help${NC}                     Show this help message"
    echo ""
    echo -e "${BOLD}${CYAN}  SSL Management${NC}"
    echo -e "  ${GREEN}fx ssl install <domain>${NC}     Install SSL certificate"
    echo -e "  ${GREEN}fx ssl renew <domain>${NC}       Renew SSL certificate"
    echo -e "  ${GREEN}fx ssl remove <domain>${NC}      Remove SSL certificate"
    echo ""
    echo -e "${BOLD}${CYAN}  Authentication${NC}"
    echo -e "  ${GREEN}fx auth on <domain>${NC}         Enable basic auth"
    echo -e "  ${GREEN}fx auth off <domain>${NC}        Disable basic auth"
    echo -e "  ${GREEN}fx auth add <domain> <user>${NC} Add auth user"
    echo -e "  ${GREEN}fx auth remove <domain> <user>${NC} Remove auth user"
    echo ""
    echo -e "${BOLD}${CYAN}  Site Management${NC}"
    echo -e "  ${GREEN}fx site create <domain>${NC}     Create WordPress site"
    echo -e "  ${GREEN}fx site delete <domain>${NC}     Delete WordPress site"
    echo -e "  ${GREEN}fx site list${NC}                List all sites"
    echo -e "  ${GREEN}fx site info <domain>${NC}       Show site info"
    echo ""
    echo -e "${BOLD}${CYAN}  Database Management${NC}"
    echo -e "  ${GREEN}fx db password <domain>${NC}     Change database password"
    echo -e "  ${GREEN}fx db create <name>${NC}         Create new database"
    echo -e "  ${GREEN}fx db delete <name>${NC}         Delete database"
    echo -e "  ${GREEN}fx db list${NC}                  List all databases"
    echo -e "  ${GREEN}fx db export <db> [file]${NC}    Export database"
    echo -e "  ${GREEN}fx db import <db> <file>${NC}    Import database"
    echo ""
    echo -e "${BOLD}${CYAN}  Tools${NC}"
    echo -e "  ${GREEN}fx pma install${NC}              Install phpMyAdmin"
    echo -e "  ${GREEN}fx pma password <password>${NC}  Set phpMyAdmin password"
    echo -e "  ${GREEN}fx pma remove${NC}               Remove phpMyAdmin"
    echo -e "  ${GREEN}fx adminer install${NC}          Install Adminer"
    echo -e "  ${GREEN}fx adminer remove${NC}           Remove Adminer"
    echo -e "  ${GREEN}fx files install${NC}            Install File Manager"
    echo -e "  ${GREEN}fx files remove${NC}             Remove File Manager"
    echo ""
    echo -e "${BOLD}${CYAN}  Cache${NC}"
    echo -e "  ${GREEN}fx cache clear${NC}              Clear FastCGI cache"
    echo -e "  ${GREEN}fx cache status${NC}             Show cache status"
    echo ""
    echo -e "${BOLD}${CYAN}  PHP${NC}"
    echo -e "  ${GREEN}fx php version${NC}              Show current PHP version"
    echo -e "  ${GREEN}fx php list${NC}                 List installed PHP versions"
    echo -e "  ${GREEN}fx php switch <version>${NC}     Switch PHP version"
    echo -e "  ${GREEN}fx php restart${NC}              Restart PHP-FPM"
    echo ""
    echo -e "${BOLD}${CYAN}  Backup${NC}"
    echo -e "  ${GREEN}fx backup create <domain>${NC}   Create site backup"
    echo -e "  ${GREEN}fx backup list${NC}              List backups"
    echo -e "  ${GREEN}fx backup restore <file>${NC}    Restore from backup"
    echo ""
    echo -e "${DIM}  ${FX_URL} | Made with ${RED}❤${DIM} by Wasim Akram${NC}"
    echo ""
}

# ---------- Main Entry Point ----------

main() {
    local command="${1:-}"

    if [[ -z "${command}" ]]; then
        cmd_help
        exit 0
    fi

    shift || true

    case "${command}" in
        status)         cmd_status "$@" ;;
        version|-v|--version) cmd_version ;;
        ssl)            cmd_ssl "$@" ;;
        auth)           cmd_auth "$@" ;;
        site)           cmd_site "$@" ;;
        db)             cmd_db "$@" ;;
        pma)            cmd_pma "$@" ;;
        adminer)        cmd_adminer "$@" ;;
        files)          cmd_files "$@" ;;
        cache)          cmd_cache "$@" ;;
        php)            cmd_php "$@" ;;
        backup)         cmd_backup "$@" ;;
        update)         cmd_update "$@" ;;
        help|-h|--help) cmd_help ;;
        *)
            fx_error "Unknown command: ${command}"
            fx_error "Run 'fx help' to see available commands."
            exit 1
            ;;
    esac
}

main "$@"
