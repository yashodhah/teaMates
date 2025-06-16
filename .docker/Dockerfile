# /.docker/Dockerfile
FROM eclipse-temurin:21-jdk-alpine

# build-time var pointing to the JAR on disk
ARG JAR_FILE
WORKDIR /app

# copy the JAR (from CI workspace) into the image
COPY ${JAR_FILE} ./app.jar

ENTRYPOINT ["java","-jar","/app/app.jar"]
