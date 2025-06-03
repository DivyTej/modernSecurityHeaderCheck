#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help function
usage() {
  echo -e "Usage: $0 -f <input_file> [-p <ports>] [-t <timeout>] [-h]"
  echo
  echo -e "Options:"
  echo -e "  -f <input_file>     File containing IP addresses (one per line)"
  echo -e "  -p <ports>          Comma-separated ports to scan (default: 80,443,8080)"
  echo -e "  -t <timeout>        Timeout for each request in seconds (default: 5)"
  echo -e "  -h                  Display this help message"
  exit 1
}

# Validate IPv4 address
validate_ip() {
  local ip=$1
  local IFS=.
  read -r a b c d <<< "$ip"
  for octet in $a $b $c $d; do
    if [[ ! "$octet" =~ ^[0-9]+$ ]] || (( octet < 0 || octet > 255 )); then
      return 1
    fi
  done
  return 0
}

# Default values
PORTS=(80 443 8080)
TIMEOUT=5

# Parse options
while getopts "f:p:t:h" opt; do
  case $opt in
    f) IPS_FILE="$OPTARG" ;;
    p) IFS=',' read -ra PORTS <<< "$OPTARG" ;;
    t) TIMEOUT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Input validation
if [[ -z "$IPS_FILE" ]]; then
  echo -e "${RED}Error: Input file not specified!${NC}"
  usage
fi

if [[ ! -f "$IPS_FILE" ]]; then
  echo -e "${RED}Error: File '$IPS_FILE' not found!${NC}"
  exit 1
fi

# Handle Ctrl+C
trap "echo -e '\n${YELLOW}Interrupted. Exiting...${NC}'; exit 1" SIGINT

# Headers to check
headers_to_check=(
  "Strict-Transport-Security"
  "X-Content-Type-Options"
  "X-Frame-Options"
  "Content-Security-Policy"
  "Referrer-Policy"
  "Permissions-Policy"
  "Cache-Control"
)

# Scan each IP
while IFS= read -r ip || [[ -n "$ip" ]]; do
  ip=$(echo "$ip" | tr -d '\r')
  if ! validate_ip "$ip"; then
    echo -e "${RED}Invalid IP format: $ip${NC}"
    continue
  fi

  echo -e "\n${YELLOW}Checking security headers for $ip...${NC}"
  port_found=0

  for port in "${PORTS[@]}"; do
    protocols=("http" "https")
    [[ "$port" == "443" ]] && protocols=("https")  # Only HTTPS for 443

    for proto in "${protocols[@]}"; do
      if [[ "$proto" == "http" ]]; then
        url="http://$ip:$port"
        curl_opts=""
      else
        url="https://$ip:$port"
        curl_opts="-k"
      fi

      status_code=$(curl -m "$TIMEOUT" -sI $curl_opts -o /dev/null -w "%{http_code}" "$url")

      if [[ "$status_code" -ge 200 && "$status_code" -lt 400 ]]; then
        echo -e "  ${GREEN}${proto^^} service detected on port $port${NC}"
        headers=$(curl -m "$TIMEOUT" -sI $curl_opts "$url")

        for header in "${headers_to_check[@]}"; do
          value=$(echo "$headers" | grep -i "^$header:")
          if [[ -z "$value" ]]; then
            echo -e "    ${RED}Missing ${header}${NC}"
          else
            echo -e "    ${GREEN}Found ${header}: $value${NC}"
          fi
        done

        port_found=1
      fi
    done
  done

  if [[ $port_found -eq 0 ]]; then
    echo -e "  ${RED}No web service detected on specified ports${NC}"
  fi
done < "$IPS_FILE"
