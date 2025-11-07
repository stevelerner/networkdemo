#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="./nginx/certs"
DOMAIN="app.demo.local"

echo "=================================================="
echo "SSL Certificate Generator"
echo "=================================================="
echo ""

# Create cert directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Check if mkcert is available
if command -v mkcert &> /dev/null; then
    echo "mkcert found - generating trusted certificate..."
    echo ""
    
    # Install local CA if not already done
    mkcert -install 2>/dev/null || true
    
    # Generate certificate
    mkcert -cert-file "$CERT_DIR/${DOMAIN}.crt" \
           -key-file "$CERT_DIR/${DOMAIN}.key" \
           "$DOMAIN" \
           "*.demo.local"
    
    echo ""
    echo "Certificate generated using mkcert (trusted by your system)"
    echo "   Certificate: $CERT_DIR/${DOMAIN}.crt"
    echo "   Private Key: $CERT_DIR/${DOMAIN}.key"
    echo ""
    echo "Your browser will trust this certificate!"
    
else
    echo "WARNING: mkcert not found - generating self-signed certificate..."
    echo ""
    echo "To install mkcert for trusted certificates:"
    echo "  brew install mkcert"
    echo ""
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout "$CERT_DIR/${DOMAIN}.key" \
        -out "$CERT_DIR/${DOMAIN}.crt" \
        -subj "/C=US/ST=Demo/L=Demo/O=Demo/CN=${DOMAIN}" \
        -addext "subjectAltName=DNS:${DOMAIN},DNS:*.demo.local" \
        2>/dev/null
    
    echo "Self-signed certificate generated"
    echo "   Certificate: $CERT_DIR/${DOMAIN}.crt"
    echo "   Private Key: $CERT_DIR/${DOMAIN}.key"
    echo ""
    echo "WARNING: Browsers will show a security warning for self-signed certs."
    echo "   Use '-k' flag with curl or accept the browser warning."
fi

echo ""
echo "=================================================="
echo "Certificate details:"
echo "=================================================="
openssl x509 -in "$CERT_DIR/${DOMAIN}.crt" -noout -subject -issuer -dates

echo ""
echo "Done! You can now run: docker compose up -d"

