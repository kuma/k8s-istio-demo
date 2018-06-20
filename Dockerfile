FROM alpine:latest
WORKDIR /app
RUN apk --no-cache add ca-certificates
ADD ./main_linux /app
EXPOSE 4000
CMD ["./main_linux"]