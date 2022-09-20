FROM node:10-slim
LABEL maintainer "Matt McNeeney <matt@mattmc.co.uk>"

COPY . /

RUN npm install

ENV PORT 8080
EXPOSE 8080

CMD npm start
