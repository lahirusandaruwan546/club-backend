# Use Dart SDK image
FROM dart:stable

# Resolve app dependencies.
WORKDIR /app
COPY . .

RUN dart pub get

# Expose the port
EXPOSE 8080

# Start server
CMD ["dart", "run", "bin/main.dart"]
