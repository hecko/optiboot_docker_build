Build Optiboot without any local pre-requirements:

```
# dont forget to run this as root as that is required by docker daemon (usually)
sudo su -
git clone https://github.com/hecko/optiboot_docker_build.git
cd optiboot_docker_build
BUILDKIT_PROGRESS=plain DOCKER_BUILDKIT=1 docker build --no-cache --output out .
cat out/optiboot.hex
```
