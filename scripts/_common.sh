### Constants

nginx_conf_path="/etc/nginx/conf.d/${domain}.d/ihatemoney.conf"
supervisor_conf_path="/etc/supervisor/conf.d/ihatemoney.conf"
gunicorn_conf_path="/etc/ihatemoney/gunicorn.conf.py"
ihatemoney_conf_path="/etc/ihatemoney/ihatemoney.cfg"
INSTALL_DIR="/opt/yunohost/ihatemoney"


### Functions

fetch_and_extract() {
    local DESTDIR=$1
    local OWNER_USER=${2:-admin}

    VERSION=1.0
    SHA256=e2ad6e56b161f13911c1c378aad79656bbdfce495189d80f997414803859348e
    SOURCE_URL="https://github.com/spiral-project/ihatemoney/archive/${VERSION}.tar.gz"

    tarball="/tmp/ihatemoney.tar.gz"
    rm -f "$tarball"

    wget -q -O "$tarball" "$SOURCE_URL" \
        || ynh_die "Unable to download tarball"
    echo "$SHA256 $tarball" | sha256sum -c >/dev/null \
        || ynh_die "Invalid checksum of downloaded tarball"
    test -d $DESTDIR || sudo mkdir $DESTDIR
    sudo tar xaf "${tarball}" -C "$DESTDIR" --strip-components 1\
        || ynh_die "Unable to extract tarball"

    rm -f "$tarball"
}


fix_permissions() {
    local SRC_DIR=$1

    # FIXME: what are perms to fix since we migrated to pip ?
    sudo find $SRC_DIR -type f | while read LINE; do sudo chmod 640 "$LINE" ; done
    sudo find $SRC_DIR -type d | while read LINE; do sudo chmod 755 "$LINE" ; done
    sudo chown -R ihatemoney:ihatemoney $SRC_DIR
    sudo chown -R www-data:www-data ${SRC_DIR}/budget/static
}


install_apt_dependencies() {
    sudo apt-get install -y -qq python3-virtualenv supervisor
}

create_unix_user() {
    sudo mkdir -p /opt/yunohost
    sudo useradd ihatemoney -d /opt/yunohost/ihatemoney/ --create-home || ynh_die "User creation failed"
}

create_system_dirs() {
    sudo install -o ihatemoney -g ihatemoney -m 755 -d \
         /var/log/ihatemoney \
         /etc/ihatemoney
    sudo mkdir -p /opt/yunohost
}

init_virtualenv () {
    sudo virtualenv /opt/yunohost/ihatemoney/venv --python /usr/bin/python3
}

configure_nginx () {
    local path=$1

    sed -i "s@PATHTOCHANGE@$path@g" ../conf/nginx.conf
    # Fix double-slash for domain-root install
    sed -i "s@location //@location /@" ../conf/nginx.conf
}




### Backported helpers (from testing)


# Add path
ynh_normalize_url_path () {
	path_url=$1
	test -n "$path_url" || ynh_die "ynh_normalize_url_path expect a URL path as first argument and received nothing."
	if [ "${path_url:0:1}" != "/" ]; then    # If the first character is not a /
		path_url="/$path_url"    # Add / at begin of path variable
	fi
	if [ "${path_url:${#path_url}-1}" == "/" ] && [ ${#path_url} -gt 1 ]; then    # If the last character is a / and that not the only character.
		path_url="${path_url:0:${#path_url}-1}"	# Delete the last character
	fi
	echo $path_url
}
