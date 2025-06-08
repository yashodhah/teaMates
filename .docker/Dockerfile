FROM eclipse-temurin:21

ARG SERVICE_NAME
ENV SERVICE_NAME=${SERVICE_NAME}

WORKDIR /app

COPY ${SERVICE_NAME}/target/*.jar /app/app.jar

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
