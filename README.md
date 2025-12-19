# Todo App (Go + React + MongoDB)

Продакшн-развёрнутое Todo-приложение: backend на Go + MongoDB и frontend на React (Vite + Chakra UI), отдаётся через nginx.  
Живая версия доступна по адресу: https://todo-go-react.duckdns.org/ [web:204][web:211]

---

## Архитектура

- **Frontend**: Vite + React + TypeScript + Chakra UI + React Query.
- **Backend**: Go + MongoDB (Atlas).
- **Reverse proxy / static hosting**: nginx.
- **Домен / SSL**: `todo-go-react.duckdns.org` с Let’s Encrypt (Certbot). [web:188][web:204]

Схема запросов в продакшне:

Browser -> https://todo-go-react.duckdns.org

/ -> nginx -> статика из /var/www/todo_list_front/dist

/api/... -> nginx -> http://localhost:5000/api/... (Go backend)

text

---

## Backend (Go + MongoDB)

### Стек

- Go
- MongoDB (Atlas)
- net/http (или выбранный фреймворк, например Fiber)

### Переменные окружения

Файл `.env` в корне backend‑проекта:

PORT=5000
MONGODB_URI="URL"
ENV=development

text

- `PORT` — порт HTTP‑сервера (по умолчанию `5000`).
- `MONGODB_URI` — строка подключения к MongoDB.
- `ENV` — окружение (`development` / `production`). [web:281][web:292]

### Основные эндпоинты

(подстрой под свою реализацию, пример):

- `GET /api/todos` — список задач.
- `POST /api/todos` — создать задачу.
- `PUT /api/todos/:id` — обновить задачу.
- `DELETE /api/todos/:id` — удалить задачу. [web:277][web:283]

### Запуск локально

cd backend
go mod tidy
go run ./cmd/server # или go run main.go — по структуре проекта

text

Сервер поднимется на `http://localhost:5000` (или порт из `PORT`).

Проверка:

curl -v http://localhost:5000/api/todos

text

Должен вернуться JSON со списком задач.

### Продакшн‑запуск (systemd пример)

1. Собрать бинарник:

cd backend
go build -o todo-backend ./cmd/server # или свой путь

text

2. Пример unit‑файла:

[Unit]
Description=Todo Go Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/var/www/todo_backend
ExecStart=/var/www/todo_backend/todo-backend
Restart=always
Environment=PORT=5000
Environment=MONGODB_URI=...

[Install]
WantedBy=multi-user.target

text

3. Активировать сервис:

sudo systemctl daemon-reload
sudo systemctl enable todo-backend
sudo systemctl start todo-backend
sudo systemctl status todo-backend

text

---

## Frontend (Vite + React + Chakra UI)

### Стек

- Vite (React + TypeScript)
- Chakra UI
- React Query
- Fetch API [web:282][web:287]

### Переменные окружения (frontend)

Фронтенд использует `VITE_API_URL`:

- `.env.development` (dev):

VITE_API_URL=http://localhost:5000/api

text

- `.env.production` (prod за nginx):

VITE_API_URL=/api

text

В коде базовый URL:

export const BASE_URL = import.meta.env.VITE_API_URL || "/api";

text

Пример использования в `TodoList`:

import { BASE_URL } from "./App";

const res = await fetch(${BASE_URL}/todos);
const data = await res.json();

text

В dev это `http://localhost:5000/api/todos`, в prod — `https://todo-go-react.duckdns.org/api/todos`. [web:267][web:278]

### Запуск локально

cd frontend
npm install
npm run dev

text

Приложение откроется по адресу `http://localhost:5173`.  
Для корректной работы нужен запущенный backend на `http://localhost:5000`.

### Сборка

cd frontend
npm run build

text

Готовый билд — в `dist/`.

---

## nginx конфигурация (продакшн)

Пример конфига, где:

- фронт лежит в `/var/www/todo_list_front/dist`;
- Go backend слушает `localhost:5000`;
- домен `todo-go-react.duckdns.org` обслуживается с HTTPS. [web:188][web:211]

upstream go_api {
server localhost:5000;
}

HTTP: default server
server {
listen 80 default_server;
listen [::]:80 default_server;

text
server_name _;

access_log /var/log/nginx/access.log;
error_log /var/log/nginx/error.log;

root /var/www/todo_list_front/dist;
index index.html;

# API → Go
location /api/ {
    proxy_pass http://go_api;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# React SPA
location / {
    try_files $uri $uri/ /index.html;
}
}

HTTP → HTTPS redirect for domain
server {
listen 80;
listen [::]:80;
server_name todo-go-react.duckdns.org;

text
return 301 https://$host$request_uri;
}

HTTPS server for domain
server {
listen 443 ssl;
listen [::]:443 ssl;
server_name todo-go-react.duckdns.org;

text
ssl_certificate /etc/letsencrypt/live/todo-go-react.duckdns.org/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/todo-go-react.duckdns.org/privkey.pem;
include /etc/letsencrypt/options-ssl-nginx.conf;
ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

access_log /var/log/nginx/access.log;
error_log /var/log/nginx/error.log;

root /var/www/todo_list_front/dist;
index index.html;

# API → Go
location /api/ {
    proxy_pass http://go_api;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# React SPA
location / {
    try_files $uri $uri/ /index.html;
}
}

text

Проверка и перезагрузка:

sudo nginx -t
sudo systemctl reload nginx

text

---

## Полезные команды отладки

- Проверить backend через nginx:

curl -v http://localhost/api/todos

text

- Проверить прямое подключение к Go:

curl -v http://localhost:5000/api/todos

text

- Логи nginx:

sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log

text

- Проверить, что сервис Go жив:

sudo systemctl status todo-backend

text
undefined
