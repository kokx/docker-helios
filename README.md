# Docker helios

A docker image to run [Helios](https://heliosvoting.org/).

1. Create a .env file with your settings
2. Build the docker image
3. Run the image using
```
docker run --env-file=.env -p 8000:8000 docker-helios:latest
```