FROM node:20-slim

# Install OpenSSL (required by Prisma)
RUN apt-get update -y && apt-get install -y openssl \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy dependency definition files
COPY package*.json ./

# Install dependencies cleanly
RUN npm ci

# Copy the rest of the backend source code
COPY . .

# Generate the Prisma database client
RUN npx prisma generate

# Expose the API port (as defined in server.js)
EXPOSE 3001

# Command to run the backend application
CMD ["npm", "start"]
