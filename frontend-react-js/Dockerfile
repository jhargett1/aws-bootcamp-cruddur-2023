FROM node:16.18

WORKDIR /node
COPY package.json package-lock.json ./

RUN npm ci

WORKDIR /node/app
COPY . .

EXPOSE ${PORT}

ENV PORT=3000
CMD ["npm", "start"]