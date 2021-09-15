FROM mcr.microsoft.com/mssql/server:2017-latest

# Arguments that the mssql server base image requires for successfully creating a running container
ARG ACCEPT_EULA="Y"
ARG SA_PASSWORD="Testing!123"

RUN mkdir -p /usr/hc_src/app
WORKDIR /usr/hc_src/app

COPY . /usr/hc_src/app

# Grant permissions for the import-data script to be executable
RUN chmod +x /usr/hc_src/app/import-data.sh

CMD /bin/bash ./entrypoint.sh