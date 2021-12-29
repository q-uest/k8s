FROM openjdk:11
RUN mkdir /usr/src/myapp -p
COPY ./spring-petclinic/target/pcl.jar /usr/src/myapp
WORKDIR /usr/src/myapp
CMD ["java", "-jar", "pcl.jar"]
