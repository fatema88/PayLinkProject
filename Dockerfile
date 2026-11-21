
# Use Node.js image
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY backend/package*.json ./

# Install dependencies
RUN npm ci

# Copy backend source code
COPY backend/ ./

# Build NestJS application
RUN npm run build

# Application port
EXPOSE 3000

# Start application
CMD ["node", "dist/main.js"]
