# keepalived

### keepalived conf file specially designed for centos8

```
global_defs {
    router_id NGINX_SERVER_1  # Unique identifier for this server
}
#This is the script that It will check contiune if not runing it will handover this to backup server
vrrp_script chk_nginx {
    script "pidof nginx"
    interval 2
}

vrrp_instance VI_1 {
    interface eth0  # Network interface
    state MASTER    # Set to MASTER on one server and BACKUP on others
    virtual_router_id 51 # This 51 is the network ID like all with 51 are in one group
    priority 100     # Set to a higher value on the MASTER server
    advert_int 1
    authentication {
        auth_type PASS # check both before configure
        autp_type ANT # check both before configure
        auth_pass password  # Authentication password
    }
    track_script {
        chk_nginx
    }
    virtual_ipaddress {
        192.168.1.100   # Virtual IP address
    }
}
```
