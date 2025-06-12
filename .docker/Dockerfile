# .docker/Dockerfile
FROM eclipse-temurin:21

ARG JAR_FILE
WORKDIR /app
COPY ${JAR_FILE} ./app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
