FROM python:3.12-slim

WORKDIR /app

# Install Python dependencies first before copying app code.
# Docker builds images in layers. Copying requirements.txt and running pip
# separately means Docker can cache this layer. If only app.py changes,
# Docker reuses the cached pip layer instead of reinstalling everything.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# YOUR TURN: Copy the Flask application file into the container.
# The file is called app.py and it should go into the current directory ( . )
# Syntax: COPY <file-on-your-machine> <destination-inside-container>
#
COPY app.py .
# COPY ___________ .

# This line docuemnts which network port Flask is listening on inside the container. 
# When the container is ran, Docker will know to forward traffic from the host machine to this port inside the container.
EXPOSE 5000

# Check that Flask is up and can reach the database.
# Docker runs this command on an interval and marks the container "healthy"
# when it succeeds, which is what triggers Apache to start in docker-compose.
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=15s \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# YOUR TURN: Tell Docker what command to run when this container starts.
# Think about how you would start a Python script from your terminal.
# If you wanted to run app.py on your VM, you would type: python app.py
# Docker's CMD takes that same command, just written as a list of strings.
# Syntax: CMD ["command", "argument"]
#
# CMD ["___________", "___________"]
CMD ["python", "app.py"]