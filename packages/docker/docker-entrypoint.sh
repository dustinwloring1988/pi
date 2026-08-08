#!/bin/bash
# Generate models.json for Ollama
MODEL="${PI_MODEL:-qwen3.6:27b}"

mkdir -p /root/.pi/agent

cat > /root/.pi/agent/models.json << EOF
{
  "providers": {
    "ollama": {
      "baseUrl": "http://host.docker.internal:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        {
          "id": "${MODEL}",
          "name": "Ollama ${MODEL}",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 128000,
          "maxTokens": 32000,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
EOF

echo "=== Generated models.json ==="
cat /root/.pi/agent/models.json
echo "=============================="
echo ""
echo "=== Environment ==="
echo "PI_MODEL: ${PI_MODEL}"
echo "HOME: ${HOME}"
echo "=================="
echo ""

# Run pi with the model
exec pi --model "ollama/${MODEL}" --api-key "ollama" "$@"
