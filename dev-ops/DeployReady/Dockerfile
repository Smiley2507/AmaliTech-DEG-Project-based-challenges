# Use the official lightweight Node.js 20 Alpine image
FROM node:20-alpine

# Create a non-root user to run the app (security requirement)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory inside the container
WORKDIR /app

# Copy package files first for better Docker layer caching
COPY app/package*.json ./

# Install only production dependencies
RUN npm install --omit=dev

# Copy the rest of the application code
COPY app/ .

# Switch to the non-root user
USER appuser

# Expose the port — overridable via PORT env variable
EXPOSE ${PORT:-3000}

# Start the server
CMD ["node", "index.js"]
