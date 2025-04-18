# Image based on .Net SDK to provide pwsh to which we add cron to run scheduled jobs
FROM mcr.microsoft.com/dotnet/sdk:9.0-noble

# Install cron
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y install cron \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install docker CLI tools
RUN apt-get update \
    && apt-get -y install docker.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ue dumb-init to respond to Ctrl+C and other signals
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_amd64.deb \
    && dpkg -i dumb-init_*.deb \
    && rm dumb-init_1.2.5_amd64.deb

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "cron", "-f", "-L", "15" ]