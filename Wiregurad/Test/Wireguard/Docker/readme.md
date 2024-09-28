# Docker Config

## Docker build
```
docker build -t wireguard-d .
```

## Docker run
### Windows
```
docker run -d --name wireguard --cap-add=NET_ADMIN -p 51820:51820 -v "C:\Users\redfence\Desktop\wiregurad\config":/etc/wireguard wireguard-d
```
### Linux
```
docker run -d --name wgd --cap-add=NET_ADMIN -p 51820:51820/udp -v "$(pwd)/config":/etc/wireguard wireguard-c
```
