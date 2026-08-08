FROM vulhub/redis:5.0.7

# Create a flag that can only be read by exploiting the Lua sandbox escape
RUN echo "FLAG{lua_sandbox_escape_rce_success}" > /root/flag.txt && \
    chmod 600 /root/flag.txt

# Create a hint file in /tmp (world-readable) to guide the exploit
RUN echo "The flag is hidden somewhere only root can read. Can you escape the sandbox?" > /tmp/hint.txt && \
    chmod 644 /tmp/hint.txt

# Ensure Lua libraries are available for the exploit
RUN apt-get update && \
    apt-get install -y --no-install-recommends lua5.1 liblua5.1-0 iproute2 && \
    rm -rf /var/lib/apt/lists/*

# Create startup script that prints IP
RUN echo '#!/bin/sh' > /usr/local/bin/start.sh && \
    echo 'echo "========================================"' >> /usr/local/bin/start.sh && \
    echo 'echo "Redis CVE-2022-0543 Container"' >> /usr/local/bin/start.sh && \
    echo 'echo "Container IP: $(hostname -i)"' >> /usr/local/bin/start.sh && \
    echo 'echo "========================================"' >> /usr/local/bin/start.sh && \
    echo 'exec "$@"' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD ["redis-server", "--appendonly", "yes"]
