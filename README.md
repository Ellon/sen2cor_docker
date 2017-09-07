# sen2cor_docker
Dockerfile and related files to run sen2cor on a docker container.

# Message shared on STEP forum

Dear all,

After trying the Sen2Cor stand-alone installation on Ubuntu 14.04 without success and not willing to dig into anaconda installation, I decided to wrap this stand-alone version in a docker container. I'm sharing it here in case someone is interested.

To work around annoying user and group ids problems, you'll have to build the docker image yourself. Create an empty directory and copy the following contents in a file named `Dockerfile`:

```docker
FROM ubuntu:xenial

# Set sen2cor version string to be used below
ENV SEN2COR_VERSION 2.4.0

# Install needed packages
RUN apt-get update && apt-get install -y \
      wget \
      file \
    && rm -rf /var/lib/apt/lists/*

# Create a default user named appuser with default UID. If you want to have
# the processed producs with your user and grounp ids (recommended), build the
# image using the options:
# --build-arg APPUSER_UID=$(id -u) --build-arg APPUSER_GROUP=$(id -g)
ARG APPUSER_UID
ARG APPUSER_GROUP
ENV HOME /home/appuser
RUN groupadd ${APPUSER_GROUP:+-g} ${APPUSER_GROUP} appuser \
    && useradd ${APPUSER_UID:+-u} ${APPUSER_UID} -g appuser appuser \
    && mkdir -p $HOME \
    && chown -R appuser $HOME
WORKDIR $HOME
USER appuser

# Download and install sen2cor into /home/appuser
RUN wget http://step.esa.int/thirdparties/sen2cor/${SEN2COR_VERSION}/Sen2Cor-${SEN2COR_VERSION}-Linux64.run \
  && chmod +x Sen2Cor-${SEN2COR_VERSION}-Linux64.run \
  && ./Sen2Cor-${SEN2COR_VERSION}-Linux64.run \
  && rm Sen2Cor-${SEN2COR_VERSION}-Linux64.run

# Configure the container to run as a L2A_Process executable
ENTRYPOINT ["/home/appuser/Sen2Cor-2.4.0-Linux64/bin/L2A_Process"]
CMD ["--help"]

```
This `Dockerfile` downloads and installs Sen2Cor in the `/home/appuser` directory inside the container, adds an user named `appuser`, and finally creates an entry-point that allow us to use the container as if it was the `L2A_Process` executable. It also offers the possibility to inform the user and group ids for the `appuser` with `--build-arg` options.

You can build the docker image tagged `l2a_process:2.4.0` by running the following command on the directory with the `Dockerfile`:
```plain
$ docker build -t l2a_process:2.4.0 --build-arg APPUSER_UID=$(id -u) --build-arg APPUSER_GROUP=$(id -g) .
```
By informing your ids in the build process, any files created in the container by `appuser` in a shared directory between your computer and the container (for example, your 1C products directory) will have your current user as owner. This way you don't need to change the owner of the generated 2A products.

You can test the container using `docker run --rm l2a_process:2.4.0`, that will show the `L2A_Process.py` help message:
```plain
$ docker run --rm l2a_process:2.4.0 
usage: L2A_Process.py [-h] [--resolution {10,20,60}] [--sc_only] [--cr_only]
                      [--refresh] [--GIP_L2A GIP_L2A]
                      [--GIP_L2A_SC GIP_L2A_SC] [--GIP_L2A_AC GIP_L2A_AC]
                      directory

Sentinel-2 Level 2A Processor (Sen2Cor). Version: 2.4.0, created: 2017.06.05,
supporting Level-1C product version: 14.

positional arguments:
  directory             Directory where the Level-1C input files are located

optional arguments:
  -h, --help            show this help message and exit
  --resolution {10,20,60}
                        Target resolution, can be 10, 20 or 60m. If omitted,
                        all resolutions will be processed
  --sc_only             Performs only the scene classification at 60 or 20m
                        resolution
  --cr_only             Performs only the creation of the L2A product tree, no
                        processing
  --refresh             Performs a refresh of the persistent configuration
                        before start
  --GIP_L2A GIP_L2A     Select the user GIPP
  --GIP_L2A_SC GIP_L2A_SC
                        Select the scene classification GIPP
  --GIP_L2A_AC GIP_L2A_AC
                        Select the atmospheric correction GIPP

```

To use L2A_Product you'll need to have the 1C products available inside the container. For this, you can mount the directory with the products in the container using `--mount` option, and then use the path to the product directory inside the container. For example, if you are inside a directory with the 1C products, you can run process one of the products with:
```plain
$ docker run --rm --mount type=bind,source="$(pwd)",target=/home/appuser/products l2a_process:2.4.0 products/S2A_MSIL1C_<...>.SAFE
```
This will mount your products directory on `/home/appuser/products` inside the container. Then I can select the product to process by by informing its directory after the image tag name. You can pass any `L2A_Process.py` options after the image tag name and before the product directory (as if you were using the `L2A_Process.py` script directly).

I hope this will be useful to someone.