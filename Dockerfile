# Multi-stage build for production
FROM ruby:3.1-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    npm \
    git \
    sqlite-dev

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Precompile assets
RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy \
    bundle exec rails assets:precompile

# Production stage
FROM ruby:3.1-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    postgresql-client \
    sqlite \
    tzdata \
    curl

# Create app user
RUN addgroup -g 1000 -S rails && \
    adduser -u 1000 -S rails -G rails

# Set working directory
WORKDIR /app

# Copy gems from builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application code and precompiled assets
COPY --from=builder --chown=rails:rails /app /app

# Create necessary directories
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log && \
    chown -R rails:rails /app

# Switch to non-root user
USER rails

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/todolists || exit 1

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000", "-e", "production"]
