FROM maven:3.8.4-eclipse-temurin-17 AS order-service-build

# set working directory
WORKDIR /build
# copy just pom.xml
COPY ./pom.xml ./pom.xml

# copy source files
COPY ./src ./src

# run maven build
RUN mvn package spring-boot:repackage -DskipTests

FROM eclipse-temurin:17-jre-alpine AS order-service

# Set application port
ENV APP_PORT=80

EXPOSE ${APP_PORT}
WORKDIR /app

# copy artifacts from build stage into the container image
COPY --from=order-service-build /build/target/order-service.jar /app/

# install bash because alpine uses /bin/sh
RUN apk update \
    && apk upgrade \
    && apk add bash

# copy the entrypoint shell script to the container
COPY ./docker/order-service/docker-entrypoint.sh /app/

# Fix permissions and format the shell script to UNIX format
RUN chmod 777 /app/docker-entrypoint.sh
RUN dos2unix /app/docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/app/docker-entrypoint.sh"]
CMD ["run_jar"]
