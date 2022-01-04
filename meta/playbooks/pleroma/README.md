```sh
ansible-playbook -l pleroma playbooks/pleroma/01.yml

su pleroma -s $SHELL -lc "./bin/pleroma_ctl instance gen --output /etc/pleroma/config.exs --output-psql /tmp/setup_db.psql"

ansible-playbook -l pleroma playbooks/pleroma/02.yml

# Start the instance to verify that everything is working as expected
su pleroma -s $SHELL -lc "./bin/pleroma daemon"

# Wait for about 20 seconds and query the instance endpoint, if it shows your uri, name and email correctly, you are configured correctly
sleep 20 && curl http://localhost:4000/api/v1/instance

# Stop the instance
su pleroma -s $SHELL -lc "./bin/pleroma stop"

sudo systemctl stop nginx
certbot certonly --standalone --preferred-challenges http -d $PLEROMA_TLD

ansible-playbook -l pleroma playbooks/pleroma/03.yml

# Uncomment the webroot method
sudo vim /etc/nginx/sites-available/pleroma.conf

sudo nginx -t

# Restart nginx
systemctl restart nginx

cd /opt/pleroma
su pleroma -s $SHELL -lc "./bin/pleroma_ctl user new joeuser joeuser@sld.tld --admin"
```
