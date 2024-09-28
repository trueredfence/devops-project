# Apache

Install apache2 latest on ubuntu machine with SSL default port is **80 & 443**

## Requirements

1. Host entry in ansible host file
2. This file is for ubuntu only
3. If there's a web application file in the `app` folder, all files from the `app` folder will be automatically copied to the root directory as specified in the variable `app_name`."

## Role Variables

- **app_name**: redfence **_Used in foldername at /var/www/ and /etc/ssl/.. application_**
- **domain_name**: redfence.in
- **server_alias**: "192.168.56.112" **_alias www.redfence.in_**
- **tls_cert_file**: redfence.crt
- **tls_key_file**: redfence.pem
- **csr_path**: /tmp/redfence.csr
- **self_signed**: true **_default it will generate self signed crt_**

## Dependencies

- If the variable `self_signed` is set to **false**, the `tls_key_file` and `tls_cert_file` should be placed in the `files/ssl/` directory with the same names as specified for both the certificate and key.

## Default Sample

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
---
- hosts: all
  become: true
  tasks:
    - block:
        - name: Install Apache2 on Ubuntu
          include_role:
            name: apache
          vars:
            ssl: true # if you want to enable SSL configuration in apache
            self_signed: true # if you have own certificate else set to true
      when: "'lamp' in group_names" # Install only on lamp group
```

## License

BSD

## Author Information

@trueredfence (TP Singh)
