# Use an official Ruby runtime as a parent image
# Using slim version for smaller size
FROM ruby:3.3-slim

# Set the working directory in the container
WORKDIR /app

# Copy the maze application script into the container at /app
COPY maze_app.rb .

# Make the script executable (optional, but good practice)
# RUN chmod +x maze_app.rb

# Set the default command to execute when the container starts
# This will run the Ruby script interactively
CMD ["ruby", "maze_app.rb"]
