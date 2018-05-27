FROM ubuntu:xenial
RUN apt-get update && apt-get upgrade -y && apt-get install -y ed ssh rsyslog fail2ban openssh-server openssh-client supervisor python-pyinotify libpam-google-authenticator && apt-get clean
ENV DEBIAN_FRONTEND noninteractive

# Enable google-auth
RUN sed -i '2i auth required pam_google_authenticator.so' /etc/pam.d/sshd
RUN sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config

# Set up directories
RUN mkdir -p /var/run/sshd /var/log/supervisor /var/run/fail2ban

COPY fail2ban-supervisor.sh /usr/local/bin/
COPY supervisor.d/* /etc/supervisor/conf.d/
COPY fail2ban/* /etc/fail2ban/
CMD ["entrypoint.sh"] 
EXPOSE 22
