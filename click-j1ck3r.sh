#!/bin/bash

#Coded By Machine404! Don't copy this code without giving me credit~
#https://instagram.com/invisibleclay100
#https://twitter.com/whoami4041
#https://www.youtube.com/channel/UCC_aPnmV_zGfdwktCFE9cPQ

# Color definitions for output formatting
NC='\033[0m'          # No Color
RED='\033[1;38;5;196m'
GREEN='\033[1;38;5;040m'
ORANGE='\033[1;38;5;202m'
BLUE='\033[1;38;5;012m'
BLUE2='\033[1;38;5;032m'
PINK='\033[1;38;5;013m'
GRAY='\033[1;38;5;004m'
NEW='\033[1;38;5;154m'
YELLOW='\033[1;38;5;214m'
CG='\033[1;38;5;087m'
CP='\033[1;38;5;221m'
CPO='\033[1;38;5;205m'
CN='\033[1;38;5;247m'
CNC='\033[1;38;5;051m'

# HTML PoC template with proper indentation
# Will be populated with the target URL when vulnerability is found
read -r -d '' POC_HTML << 'EOT'
<html>
    <head>
        <title>ClickJacking POC</title>
        <meta name="author" content="Machine404">
        <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Righteous">
        <style type="text/css">
            body {
                background: white;
                background-color: white;
                height: 90%;
            }
            h1 {
                font-family: Righteous;
                color: Red;
            }
            * {
                margin: 0;
                padding: 0;
            }
            .blink {
                animation: blink 1s infinite;
            }
            @keyframes blink {
                to {
                    opacity: 0;
                }
            }
        </style>
    </head>
    <body>
        <br>
        <center><h1>POC Made By Machine404</h1></center>
        <br>
        <iframe src="TARGET_URL" width="1000" height="550"></iframe>
        <div style="height: 30px;width: 130px;left: 53%;bottom: 39%;background: #789;" class="xss">
            <button>Click me when you finish :)</button>
        </div>
    </body>
</html>
EOT

# Display banner with tool information
function banner() {
    clear
    echo -e ${CP}"     ______ _     ___ ____ _  __         _ _  ____ _  _______ ______       #"
    echo -e ${CP}"    / / ___| |   |_ _/ ___| |/ /        | / |/ ___| |/ /___ /|  _ \ \      #"
    echo -e ${CP}"   | | |   | |    | | |   | ' /_____ _  | | | |   | ' /  |_ \| |_) | |     #"
    echo -e ${CP}"  < <| |___| |___ | | |___| . \_____| |_| | | |___| . \ ___) |  _ < > >    #"
    echo -e ${CP}"   | |\____|_____|___\____|_|\_\     \___/|_|\____|_|\_\____/|_| \_\ |     #"
    echo -e ${CP}"    \_\                                                           /_/      #"
    echo -e ${CNC}"        A Simple Tool To Find ClickJacking Vulnerability With POC          #"
    echo -e ${YELLOW}"                         Coded By: Machine404                              #"
    echo -e ${CP}"          Follow Me On:  ${CPO}Instagram: invisibleclay100                       #"
    echo -e ${CP}"                         ${PINK}Twitter:   whoami4041                             #"
    echo -e ${RED}"############################################################################# ${NC} \n "
}

# Make sure curl is installed
function check_requirements() {
    command -v curl >/dev/null 2>&1 || { echo -e "${RED}[!] curl is required but not installed.${NC}"; exit 1; }
}

# Validate and normalize URL
function validate_url() {
    local input_url=$1
    # Validate URL format
    if [[ ! $input_url =~ ^https?:// ]]; then
        input_url="https://$input_url"
    fi
    
    # Remove trailing slashes
    input_url=${input_url%/}
    
    # Basic domain validation - accepts domain names and IPs
    if [[ $input_url =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} ]]; then
        echo "$input_url"
        return 0
    fi
    
    echo ""
    return 1
}

# Get valid URL input from user
function get_url_input() {
    local url=""
    
    while true; do
        printf "${BLUE}[+] Enter domain name (e.g., example.com or https://example.com): ${NC}" >&2
        read -r url || return 1

        [[ -z "$url" ]] && {
            echo -e "${RED}[!] URL cannot be empty. Please try again.${NC}"
            continue
        }
        
        if validated_url=$(validate_url "$url"); then
            echo "$validated_url"
            return 0
        else
            echo -e "${RED}[!] Invalid URL format. Please try again.${NC}"
        fi
    done
}

# Check single URL for clickjacking vulnerability
function single_url() {
    banner
    url=$(get_url_input)
    
    echo -e "${ORANGE}[*] Testing $url for clickjacking vulnerability...${NC}"
    
    # Validate URL
    validated_url=$(validate_url "$url")
    if [ -z "$validated_url" ]; then
        echo -e "${RED}[!] Error: Invalid URL format${NC}"
        return
    fi
    
    # Check if site is accessible
    check=$(curl -s -L -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" \
            --connect-timeout 5 --max-time 10 --head "$validated_url" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[!] Error: Could not connect to $url${NC}"
        return
    fi
    
    echo -e "${BLUE}[*] Analyzing security headers...${NC}"
    
    # Check X-Frame-Options header
    local is_vulnerable=true
    if echo "$check" | grep -iE "X-Frame-Options: (DENY|SAMEORIGIN)" &>/dev/null; then
        is_vulnerable=false
        echo -e "${RED}[✗] X-Frame-Options header found and properly configured (Protected, Not Vulnerable)${NC}"
    elif echo "$check" | grep -i "X-Frame-Options:" &>/dev/null; then
        echo -e "${YELLOW}[!] X-Frame-Options header found but may be misconfigured (Potentially Vulnerable)${NC}"
    else
        echo -e "${GREEN}[✓] No X-Frame-Options header found (Unprotected, Vulnerable)${NC}"
    fi

    # Check Content-Security-Policy frame-ancestors
    if echo "$check" | grep -i "Content-Security-Policy:" | grep -iE "frame-ancestors\s+(\'none\'|\'self\')" &>/dev/null; then
        is_vulnerable=false
        echo -e "${RED}[✗] Content-Security-Policy frame-ancestors directive found and properly configured (Protected, Not Vulnerable)${NC}"
    elif echo "$check" | grep -i "Content-Security-Policy:" &>/dev/null; then
        echo -e "${YELLOW}[!] Content-Security-Policy header found but frame-ancestors directive may be missing (Potentially Vulnerable)${NC}"
    else
        echo -e "${GREEN}[✓] No Content-Security-Policy header found (Unprotected, Vulnerable)${NC}"
    fi

    # Check for HTML meta tags (as fallback)
    local page_content
    page_content=$(curl -s -L -A "Mozilla/5.0" "$url" 2>/dev/null)
    if echo "$page_content" | grep -iE "<meta[^>]+http-equiv=[\"']X-Frame-Options[\"'][^>]*>" &>/dev/null; then
        echo -e "${YELLOW}[!] X-Frame-Options meta tag found (not as effective as HTTP header, yet potentially protected)${NC}"
    fi

    if [ "$is_vulnerable" = true ]; then
        echo -e "${GRAY}[!] $url is potentially vulnerable to clickjacking!${NC}"
        
        # Generate PoC file
        echo -e "${BLUE}[*] Generating PoC...${NC}"
        poc_filename="clickjacking_poc_$(date +%s).html"
        echo "$POC_HTML" | sed "s|TARGET_URL|$url|g" > "$poc_filename"
        echo -e "${GREEN}[✓] PoC has been generated as ${poc_filename}${NC}"
        echo -e "${YELLOW}[*] Open this file in a browser to test the vulnerability${NC}"

        echo -e "${PINK}\n[?] Would you like to open the PoC right now? (y/n) : ${NC}"
        read -r poc_press
        if [ "$poc_press" = "y" ] || [ "$poc_press" = "Y" ]; then
            open "$poc_filename" &>/dev/null
            echo -e "${GREEN}[✓] PoC opened in the default browser${NC}"
        fi
    else
        echo -e "${RED}[✗] $url appears to be protected against clickjacking${NC}"
    fi
    
    echo -e -n "${CP}\n[?] Would you like to go back to main menu? (y/n) : ${NC}"
    read -r back_press
    if [ "$back_press" = "y" ] || [ "$back_press" = "Y" ]; then
        menu
    else
        echo -e "${GRAY}[!] Exiting...${NC}"
        exit 0
    fi
}

# Check multiple URLs from a file
function mul_url() {
    banner
    local url_file=""
    
    while [ -z "$url_file" ] || [ ! -f "$url_file" ]; do
        echo -e -n "${CP}\n[+] Enter path to URL list file: ${NC}"
        read -r url_file
        
        if [ -z "$url_file" ]; then
            echo -e "${RED}[!] File path cannot be empty. Please try again.${NC}"
        elif [ ! -f "$url_file" ]; then
            echo -e "${RED}[!] File not found: $url_file${NC}"
        fi
    done
    
    echo -e "${ORANGE}[*] Testing URLs from $url_file...${NC}"
    
    summary_file="clickjacking_summary_$(date +%s).txt"
    touch "$summary_file"
    
    while IFS= read -r url; do
        url=$(validate_url "$url")
        echo -e "\n${BLUE}[*] Testing $url${NC}"
        
        check=$(curl -s -L -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" \
                --connect-timeout 5 --max-time 10 --head "$validated_url" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}[✗] Could not connect to $validated_url${NC}"
            echo "[$validated_url] - Connection failed" >> "$summary_file"
            continue
        fi
        
        echo -e "${BLUE}[*] Analyzing security headers...${NC}"
        
        # Check X-Frame-Options header
        local is_vulnerable=true
        if echo "$check" | grep -iE "X-Frame-Options: (DENY|SAMEORIGIN)" &>/dev/null; then
            is_vulnerable=false
            echo -e "${RED}[✗] X-Frame-Options header found and properly configured (Protected, Not Vulnerable)${NC}"
        elif echo "$check" | grep -i "X-Frame-Options:" &>/dev/null; then
            echo -e "${YELLOW}[!] X-Frame-Options header found but may be misconfigured (Potentially Vulnerable)${NC}"
        else
            echo -e "${GREEN}[✓] No X-Frame-Options header found (Unprotected, Vulnerable)${NC}"
        fi

        # Check Content-Security-Policy frame-ancestors
        if echo "$check" | grep -i "Content-Security-Policy:" | grep -iE "frame-ancestors\s+(\'none\'|\'self\')" &>/dev/null; then
            is_vulnerable=false
            echo -e "${RED}[✗] Content-Security-Policy frame-ancestors directive found and properly configured (Protected, Not Vulnerable)${NC}"
        elif echo "$check" | grep -i "Content-Security-Policy:" &>/dev/null; then
            echo -e "${YELLOW}[!] Content-Security-Policy header found but frame-ancestors directive may be missing (Potentially Vulnerable)${NC}"
        else
            echo -e "${GREEN}[✓] No Content-Security-Policy header found (Unprotected, Vulnerable)${NC}"
        fi

        if [ "$is_vulnerable" = true ]; then
            echo -e "${GRAY}[!] $validated_url is potentially vulnerable to clickjacking!${NC}"
            echo "[$validated_url] - VULNERABLE" >> "$summary_file"
            
            # Generate PoC for vulnerable sites
            poc_filename="$results_dir/poc_$(echo "$validated_url" | sed 's/[^a-zA-Z0-9]/_/g').html"
            echo "$POC_HTML" | sed "s|TARGET_URL|$validated_url|g" > "$poc_filename"
            echo -e "${GREEN}[✓] PoC has been generated: $poc_filename${NC}"
        else
            echo -e "${GREEN}[✓] $validated_url is protected${NC}"
            echo "[$validated_url] - Protected" >> "$summary_file"
        fi
    done < "$url_file"
    
    echo -e -n "${CP}\n[?] Would you like to go back to main menu? (y/n) : ${NC}"
    read -r back_press
    if [ "$back_press" = "y" ] || [ "$back_press" = "Y" ]; then
        menu
    else
        echo -e "${GRAY}[!] Exiting...${NC}"
        exit 0
    fi
}

# Handle ctrl+c gracefully
trap ctrl_c INT
function ctrl_c() {
    echo -e "${RED}\n[!] Ctrl+C pressed. Exiting...${NC}"
    exit 1
}

# Main menu
function menu() {
    banner

    check_requirements

    echo -e "${YELLOW}[1] Scan Single URL${NC}"
    echo -e "${BLUE2}[2] Scan Multiple URLs${NC}"
    echo -e "${RED}[3] Exit${NC}"
    
    while true; do
        echo -e -n "${CP}\n[+] Select an option: ${NC}"
        read -r choice
        case $choice in
            1) single_url ;;
            2) mul_url ;;
            3) echo -e "${RED}[!] Exiting...${NC}" ; exit 0 ;;
            *) echo -e "${RED}[!] Invalid option. Please try again.${NC}" ;;
        esac
    done
}

# Start the script
menu