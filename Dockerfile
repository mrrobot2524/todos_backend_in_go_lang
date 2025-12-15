# Stage 1: Build
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Скопируйте go.mod и go.sum
COPY go.mod go.sum ./

# Скачайте зависимости
RUN go mod download

# Скопируйте весь код
COPY . .

# Скомпилируйте приложение
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Stage 2: Runtime
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Скопируйте бинарник из builder stage
COPY --from=builder /app/main .

# Скопируйте frontend build если есть
COPY --from=builder /app/frontend/dist ./frontend/dist

# Expose порт
EXPOSE 5000

# Запустите приложение
CMD ["./main"]
