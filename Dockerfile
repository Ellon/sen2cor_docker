FROM ubuntu:xenial

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

# Set sen2cor version string to be used below
ENV SEN2COR_VERSION 2.4.0

# Download and install sen2cor into /home/appuser
RUN wget http://step.esa.int/thirdparties/sen2cor/${SEN2COR_VERSION}/Sen2Cor-${SEN2COR_VERSION}-Linux64.run \
  && chmod +x Sen2Cor-${SEN2COR_VERSION}-Linux64.run \
  && ./Sen2Cor-${SEN2COR_VERSION}-Linux64.run \
  && rm Sen2Cor-${SEN2COR_VERSION}-Linux64.run

# Configure the container to run as a L2A_Process executable
ENTRYPOINT ["/home/appuser/Sen2Cor-2.4.0-Linux64/bin/L2A_Process"]
CMD ["--help"]
