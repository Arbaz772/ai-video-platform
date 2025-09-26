FROM node:18
WORKDIR /app
COPY backend/package*.json ./
RUN npm install --production
COPY backend/ .

# Ensure static directory exists
RUN mkdir -p /app/static

# download a small public-domain sample video into the image for local dev
RUN curl -L "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4" -o /app/static/sample.mp4 || echo "Could not download sample video"

# ensure file exists (optional)
RUN ls -lh /app/static || true

EXPOSE 4000
CMD ["node", "server.js"]
