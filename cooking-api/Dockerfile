FROM node:18-alpine

WORKDIR /app

# Копируем package.json и package-lock.json
COPY package*.json ./

# Устанавливаем зависимости
RUN npm install

# Копируем остальные файлы
COPY . .

# Указываем порт
EXPOSE 3000

# Запускаем приложение
CMD ["node", "server.js"]