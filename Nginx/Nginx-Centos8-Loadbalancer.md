```
    worker_processes 22;
    worker_rlimit_nofile 100000;
    error_log /var/log/nginx/error.log crit;

    # is this need to be out of http {}
    events {
        worker_connections 4000;
        use epoll;
        multi_accept on;
    }
    http {
        # Define the cache zone
        proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m;

        upstream backend {
            least_conn;
            server backend1.example.com;
            server backend2.example.com;
            server backend3.example.com;
            # Add more backend servers as needed
        }

        server {
            listen 80;
            # For SSL
            #listen 443 ssl;
            server_name $DOMAIN;
            #security Tags
            server_tokens off;

            #SSL configuration change if ssl configured
            #ssl_certificate /path/to/ssl_certificate.crt;
            #ssl_certificate_key /path/to/ssl_certificate.key;
            #ssl_session_cache shared:SSL:10m;
            #ssl_session_timeout 10m;


            # Security headers
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-XSS-Protection "1; mode=block" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header Referrer-Policy "strict-origin-when-cross-origin" always;
            #add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.example.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' https://cdn.example.com data:; font-src 'self' https://fonts.gstatic.com; frame-src 'none'; base-uri 'self';";


            # Enable gzip compression
            gzip on;
            gzip_min_length 10240;
            gzip_comp_level 1;
            gzip_vary on;
            gzip_disable msie6;
            gzip_proxied expired no-cache no-store private auth;
            gzip_types text/css text/javascript text/xml text/plain text/x-component application/javascript application/x-javascript application/json application/xml application/rss+xml application/atom+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

            # allow the server to close connection on non responding client, this will free up memory
            reset_timedout_connection on;
            # request timed out -- default 60
            client_body_timeout 10;
            # if client stop responding, free up memory -- default 60
            send_timeout 2;
            # server will close connection after this time -- default 75
            keepalive_timeout 30;
            # number of requests client can make over keep-alive -- for testing environment
            keepalive_requests 100000;

            location / {
                # Enable caching
                proxy_cache my_cache;
                proxy_cache_valid 200 302 10m;
                proxy_cache_valid 404 1m;
                proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
                proxy_cache_lock on;
                proxy_cache_lock_timeout 5s;
                proxy_cache_revalidate on;
                proxy_cache_background_update on;
                proxy_cache_min_uses 1;
                proxy_cache_bypass $http_cache_control;
                add_header X-Cache-Status $upstream_cache_status;

                # Configure timeouts
                proxy_connect_timeout 5s;
                proxy_send_timeout 15s;
                proxy_read_timeout 30s;

                # Configure buffering and error handling
                proxy_buffering on;
                proxy_ignore_client_abort on;
                proxy_intercept_errors on;

                # Forward requests to backend servers
                proxy_pass http://backend;

                # Set headers for backend communication
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
    }
```

```
# you must set worker processes based on your CPU cores, nginx does not benefit from setting more than that
worker_processes auto; #some last versions calculate it automatically

# number of file descriptors used for nginx
# the limit for the maximum FDs on the server is usually set by the OS.
# if you don't set FD's then OS settings will be used which is by default 2000
worker_rlimit_nofile 100000;

# only log critical errors
error_log /var/log/nginx/error.log crit;

# provides the configuration file context in which the directives that affect connection processing are specified.
events {
    # determines how much clients will be served per worker
    # max clients = worker_connections * worker_processes
    # max clients is also limited by the number of socket connections available on the system (~64k)
    worker_connections 4000;

    # optimized to serve many clients with each thread, essential for linux -- for testing environment
    use epoll;

    # accept as many connections as possible, may flood worker connections if set too low -- for testing environment
    multi_accept on;
}

http {
    # cache informations about FDs, frequently accessed files
    # can boost performance, but you need to test those values
    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # to boost I/O on HDD we can disable access logs
    access_log off;

    # copies data between one FD and other from within the kernel
    # faster than read() + write()
    sendfile on;

    # send headers in one piece, it is better than sending them one by one
    tcp_nopush on;

    # don't buffer data sent, good for small data bursts in real time
    tcp_nodelay on;

    # reduce the data that needs to be sent over network -- for testing environment
    gzip on;
    # gzip_static on;
    gzip_min_length 10240;
    gzip_comp_level 1;
    gzip_vary on;
    gzip_disable msie6;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types
        # text/html is always compressed by HttpGzipModule
        text/css
        text/javascript
        text/xml
        text/plain
        text/x-component
        application/javascript
        application/x-javascript
        application/json
        application/xml
        application/rss+xml
        application/atom+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;

    # allow the server to close connection on non responding client, this will free up memory
    reset_timedout_connection on;

    # request timed out -- default 60
    client_body_timeout 10;

    # if client stop responding, free up memory -- default 60
    send_timeout 2;

    # server will close connection after this time -- default 75
    keepalive_timeout 30;

    # number of requests client can make over keep-alive -- for testing environment
    keepalive_requests 100000;
}
```
