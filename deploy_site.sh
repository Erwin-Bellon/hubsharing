#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "================================================================="
echo " Belgian Interhub FHIR IG - One-Click Build & Launch"
echo "================================================================="

# 1. Check/Install Publisher JAR
mkdir -p input-cache
if [ ! -f "input-cache/publisher.jar" ]; then
    echo "Downloading publisher.jar (~220MB)..."
    curl -L -o input-cache/publisher.jar "https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar"
fi

# 2. Run SUSHI
echo "Running SUSHI..."
sushi .

# 3. Run Publisher
echo "Running IG Publisher..."
java -Xmx4096m -Dfile.encoding=UTF-8 -jar input-cache/publisher.jar -ig . -tx n/a -no-sushi

# 4. Start Server
echo "Starting server on http://localhost:8080/en/index.html..."
pkill -f "node serve.js" || true
node serve.js &
sleep 2

echo "IG is ready at http://localhost:8080/en/index.html"
