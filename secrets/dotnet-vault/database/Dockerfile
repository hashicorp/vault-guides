FROM mcr.microsoft.com/mssql/server:2019-latest

USER root
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app

# Grant permissions for the import-data script to be executable
RUN chmod +x /usr/src/app/import-data.sh

EXPOSE 5001

USER mssql
CMD /bin/bash ./entrypoint.sh