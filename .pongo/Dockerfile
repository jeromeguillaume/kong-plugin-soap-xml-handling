# Utiliser explicitement ARM64
FROM --platform=linux/arm64 ubuntu:22.04

# Mettre à jour les paquets et installer Squid 5.2
RUN apt-get update && \
    apt-get install -y squid=5.2* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Créer le répertoire pour le cache de Squid
RUN mkdir -p /var/spool/squid && chown -R proxy:proxy /var/spool/squid

# Exposer le port par défaut de Squid
EXPOSE 3128

# Lancer Squid en mode foreground pour Docker
CMD ["squid", "-N", "-d", "1"]