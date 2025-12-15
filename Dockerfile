# Stage 1: Build
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Модули
COPY go.mod go.sum ./
RUN go mod download

# Код
COPY . .

# Сборка бинарника
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Stage 2: Runtime
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Копируем бинарник
COPY --from=builder /app/main .

# Порт приложения
EXPOSE 5000

# Запуск
CMD ["./main"]
