# SOC Attack Automation (Bash)
A Bash script for automating SOC attack simulations. Includes Nmap scanning, Hydra brute-force, Hping3 DoS, and Metasploit exploits.

## Overview
This Bash script simulates multiple attack types to help SOC teams stay alert and test their readiness.  
It automates:
- **Nmap Port Scan**
- **Hydra Brute Force (SSH)**
- **Hping3 DoS Attack**
- **Metasploit Reverse Shell Attack**

## Features
✅ Detects live network IPs before launching attacks  
✅ Allows choosing a target manually or randomly  
✅ Includes attack logging for post-analysis  
✅ Requires sudo access for full functionality  

## Installation
Run the script:
```bash
chmod +x soc_checker.sh
sudo ./soc_checker.sh
