# modernSecurityHeaderCheck

## Overview

A simple and effective Bash tool that leverages `curl` to check for modern web security headers across specified IPs and ports. Designed for automation in penetration testing workflows, it helps quickly identify missing or misconfigured HTTP response headers such as `Strict-Transport-Security`, `Content-Security-Policy`, and more.


## Usage

1. Navigate to the directory containing the scripts:
   ```bash
   git clone https://github.com/DivyTej/modernSecurityHeaderCheck.git
   cd modernSecurityHeaderCheck
   chmod +x modernSecHeadersCheck.sh
   ./modernSecHeadersCheck.sh -f ips.txt -p 80,443,8443 -t 5
   ```

## Example Workflow

1. Sample Command:
   ```bash
   ./modernSecHeadersCheck.sh -f ips.txt -p 80,443,8443 -t 5

