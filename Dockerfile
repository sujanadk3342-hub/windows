# Use a lightweight Debian base
FROM debian:bullseye-slim

# Prevent prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install XFCE Desktop, VNC server, and noVNC
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    && apt-get clean

# Set up a VNC password (change 'password' to something else)
RUN mkdir ~/.vnc && \
    echo "password" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Expose the port Railway uses (PORT is provided by Railway)
ENV PORT=8080
EXPOSE 8080

# Command to start VNC and noVNC
CMD vncserver :1 -geometry 1024x768 -depth 24 && \
    /usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen $PORT
