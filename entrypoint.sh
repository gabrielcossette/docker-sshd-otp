#!/bin/bash
set +e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'SFTP_USER1'
file_env 'SFTP_USER2'
file_env 'SFTP_USER3'
file_env 'SFTP_PASSWORD1'
file_env 'SFTP_PASSWORD2'
file_env 'SFTP_PASSWORD3'
file_env 'SFTP_SECRET1'
file_env 'SFTP_SECRET2'
file_env 'SFTP_SECRET3'

if [ ! -f /first_run_passed ]; then
    groupmod -g 82 www-data
	useradd -G www-data -s /bin/bash -p $(openssl passwd -1 $SFTP_PASSWORD1) $SFTP_USER1 
    useradd -G www-data -s /bin/bash -p $(openssl passwd -1 $SFTP_PASSWORD2) $SFTP_USER2
    useradd -G www-data -s /bin/bash -p $(openssl passwd -1 $SFTP_PASSWORD3) $SFTP_USER3
	mkdir -p /home/$SFTP_USER1/.ssh /home/$SFTP_USER2/.ssh /home/$SFTP_USER3/.ssh
	ln -s /sites /home/$SFTP_USER1/sites
	ln -s /sites /home/$SFTP_USER2/sites
	ln -s /sites /home/$SFTP_USER3/sites
    touch /first_run_passed
fi

cp /google_authenticator /home/$SFTP_USER1/.google_authenticator
cp /google_authenticator /home/$SFTP_USER2/.google_authenticator
cp /google_authenticator /home/$SFTP_USER3/.google_authenticator

sed -i -e "s/SECRETUSER/$SFTP_SECRET1/g" /home/$SFTP_USER1/.google_authenticator
sed -i -e "s/SECRETUSER/$SFTP_SECRET2/g" /home/$SFTP_USER2/.google_authenticator
sed -i -e "s/SECRETUSER/$SFTP_SECRET3/g" /home/$SFTP_USER3/.google_authenticator

chmod 400 /home/$SFTP_USER1/.google_authenticator
chmod 400 /home/$SFTP_USER2/.google_authenticator
chmod 400 /home/$SFTP_USER3/.google_authenticator

chown -R $SFTP_USER1:$SFTP_USER1 /home/$SFTP_USER1
chown -R $SFTP_USER2:$SFTP_USER2 /home/$SFTP_USER2
chown -R $SFTP_USER3:$SFTP_USER3 /home/$SFTP_USER3

supervisord -c /etc/supervisor/supervisord.conf