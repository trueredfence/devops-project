import csv
import re
import ipaddress
from urllib.parse import urlparse

def extract_ipv6_from_url(url):
    # Match IPv6 address pattern with or without protocol prefix
    ipv6_pattern = r'\[([0-9a-fA-F:]+)\]'
    match = re.search(ipv6_pattern, url)
    if match:
        return match.group(1)
    return url

def is_valid_ipv4(ip):
    try:
        # Remove port if exists
        ip = ip.split(':')[0]
        ipaddress.IPv4Address(ip)
        return True
    except ValueError:
        return False

def is_valid_ipv6(ip):
    try:
        # Remove brackets if present
        cleaned_ip = ip.strip('[]')
        ipaddress.IPv6Address(cleaned_ip)
        return True
    except ValueError:
        return False

def is_valid_domain(domain):
    # Basic domain validation pattern that allows domains containing 'http' or 'https'
    pattern = r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
    return bool(re.match(pattern, domain))

def process_url(url):
    # Remove backticks if present
    url = url.strip('`')
    
    # First try to extract IPv6 if present
    ipv6_value = extract_ipv6_from_url(url)
    if is_valid_ipv6(ipv6_value):
        return ipv6_value
    
    # Handle various protocol formats
    protocols = ['http://', 'https://', 'hxxp://', 'hxxps://', 'htxp://']
    lower_url = url.lower()
    
    # Check if URL starts with any of the protocols
    for protocol in protocols:
        if lower_url.startswith(protocol):
            try:
                # Remove protocol and get the host
                host = url[len(protocol):].split('/')[0]
                # Remove port if exists
                return host.split(':')[0]
            except:
                return url
    
    # If no protocol found, check if it starts with an IP
    if '/' in url:
        potential_ip = url.split('/')[0].strip('[]')
        if is_valid_ipv4(potential_ip) or is_valid_ipv6(potential_ip):
            return potential_ip
    
    return url

def main():
    # Initialize lists for different types of data
    ipv4_addresses = []
    ipv6_addresses = []
    domains = []
    others = []
    
    # Read input file
    try:
        with open('input.csv', 'r') as file:
            reader = csv.reader(file)
            for row in reader:
                if not row:  # Skip empty rows
                    continue
                    
                value = row[0].strip()
                
                # Process potential URLs or domains
                processed_value = process_url(value)
                
                # Categorize the data
                if is_valid_ipv4(processed_value):
                    ipv4_addresses.append(processed_value)
                elif is_valid_ipv6(processed_value):
                    # Store IPv6 without adding brackets
                    cleaned_ipv6 = processed_value.strip('[]')
                    ipv6_addresses.append(cleaned_ipv6)
                elif is_valid_domain(processed_value):
                    domains.append(processed_value)
                else:
                    others.append(value)  # Keep original value for unmatched entries
    
        # Write to separate output files
        with open('ipv4_addresses.csv', 'w', newline='') as f:
            writer = csv.writer(f)
            for ip in ipv4_addresses:
                writer.writerow([ip])
        
        with open('ipv6_addresses.csv', 'w', newline='') as f:
            writer = csv.writer(f)
            for ip in ipv6_addresses:
                writer.writerow([ip])
        
        with open('domains.csv', 'w', newline='') as f:
            writer = csv.writer(f)
            for domain in domains:
                writer.writerow([domain])
        
        with open('others.csv', 'w', newline='') as f:
            writer = csv.writer(f)
            for item in others:
                writer.writerow([item])
                
        print("Processing complete! Files created:")
        print("- ipv4_addresses.csv")
        print("- ipv6_addresses.csv")
        print("- domains.csv")
        print("- others.csv")
                
    except FileNotFoundError:
        print("Error: input.csv file not found!")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == '__main__':
    main()
