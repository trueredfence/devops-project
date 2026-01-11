sudo certbot certonly --manual --preferred-challenges=dns --manual-auth-hook ./auth.sh -d *.redfence.in
sudo certbot certonly --manual --preferred-challenges=dns
sudo certbot renew --dry-run
## Cron Job
0 0,12 * * * root sleep $((RANDOM % 3600)) && certbot renew --manual-public-ip-logging-ok --no-random-sleep-on-renew --quiet
sudo certbot certonly --manual --manual --preferred-challenges=dns --manual-auth-hook ./auth.sh -d bytesec.co.in -d *.bytesec.co.in
