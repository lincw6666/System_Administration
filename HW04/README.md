SA Homework 04
===
林正偉

----

### Outline
- Apache Server
- Nginx Server

---

## Apache Server
* Remind: If you have any problem starting an apache server, "/var/log/httpd-error.log" is very helpful.

----

### Install

```shell=
cd /usr/ports/www/apacheXX    # XX is the version of apache server.
sudo make install clean
```

----

### Get Domain Name

- Goto [https://www.nctucs.net/](https://www.nctucs.net)
- Login by NCTU student account.
- Hosts > Create hosts
    - Host: your_domain_name
    - Record: your_server's_ip_address
- Edit `/usr/local/etc/apacheXX/httpd.conf`.
    - ServerName your_domain_name:80

----

### Check Working

- Portforwarding if you use VM.
    - port 80: HTTP
    - port 443: HTTPS
    - Customize port number
- Type domain name or ip address on your browser.
    - Success: show "Its works"
    - Failed: page not found

----

### Virtual Host

- Setup name-based virtual hosts.
    - Share same ip address.
    - Different server's name show different contents.
- Create document root.
    - All access to the server will be rooted under this directory.
    - EX: /usr/local/www/your_domain_name_document_root
- Edit `/usr/local/etc/apacheXX/extra/httpd-vhosts.conf`.
    - DocumentRoot "path/to/your_document_root"
        - In this HW you need 2 different document root.
            - One for access from ip address.
            - Another for access from domain name.
    - ServerName your_server's_name
        - Different server's name but share the same ip address.
        - The first virtual host in the config file is the default host.
        - In this HW you need 2 server's name.
            - your_domain_name
            - your_ip_address
    - ServerAlias: alias server's name.
    - ErrorLog
    - CustomLog
- EX
    ```
    <VirtualHost *:80>
        DocumentRoot "your_document_root_for_domain_name"
        ServerName your_domain_name
        ServerAlias http://your_domain_name
    </VirtualHost>

    <VirtualHost *: 80>
        DocumentRoot "your_document_root_for_ip_address"
        ServerName your_ip_address
    </VirtualHost>
    ```
- Edit `/usr/local/etc/apacheXX/httpd.conf`.
    - Uncomment `Include etc/apacheXX/extra/httpd-vhosts.conf`.
- Trouble shooting: No Permission access.
    - Edit `/usr/local/etc/apacheXX/httpd.conf`.
        - Directory should be "Require all granted".
        ```
        <Directory "your_document_root">
            AllowOverride None
            Require all granted
        </Directory>
        ```

----

### Indexing

- If you want to let other people visit your directory, you need to add `index.html` in it.
    - EX
    ```htmlmixed=
    <html><body><h1><pre>Welcome</pre></h1></body></html>
    ```
- Create directory /public.
    - Add index.html
    - EX
    ```htmlmixed=
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
    <html>
        <head>
            <title>Index of /public</title>
        </head>
        <body>
            <h1>Index of /public</h1>
            <ul>
                <li><a href="/"> Parent Directory</a></li>
                <li><a href="test1"> test1</a></li>
                <li><a href="test2"> test2</a></li>
                <li><a href="test3"> test3</a></li>
            </ul>
        </body>
    </html>
    ```
- Create file: test1, test2, test3

----

### htaccess

- Create directory /public/admin and its index.html file.
- Create user and password.
    - Create a directory where user can't access.
        - EX: If your_document_root is "/usr/local/www/test", you can create a directory "/usr/local/www/passwd"
    - `sudo htpasswd -c path/to/passwd/your_passwd_file username`
        - In this HW "username" is "admin".
- Edit `/usr/local/etc/apacheXX/httpd.conf`.

    ```
    <Directory "your_document_root/public/admin">
        AllowOverride AuthConfig
        AuthType Basic
        AuthName "Things you want to tell the user. EX: hint."
        AuthBasicProvider file
        AuthUserFile "path/to/passwd/your_passwd_file"
        Require user admin
    </Directory>
    ```
- [Reference](http://httpd.apache.org/docs/2.4/howto/auth.html)

----

### Reverse Proxy

- Edit `/usr/local/etc/apacheXX/httpd.conf`.
    - Uncomment
        - `LoadModule watchdog_module libexec/apacheXX/mod_watchdog.so`
        - `LoadModule proxy_module libexec/apacheXX/mod_proxy.so`
        - `LoadModule proxy_http_module libexec/apacheXX/mod_proxy_http.so`
        - `LoadModule proxy_balancer_module libexec/apacheXX/mod_proxy_balancer.so`
        - `LoadModule proxy_hcheck_module libexec/apacheXX/mod_proxy_hcheck.so`
        - `LoadModule slotmem_shm_module libexec/apacheXX/mod_slotmem_shm.so`
        - `LoadModule lbmethod_byrequests_module libexec/apacheXX/mod_lbmethod_byrequests.so`
        - `Include etc/apacheXX/extra/httpd-default.conf`
    - Add
    ```
    <Proxy balancer://myset>
        BalancerMember http://other_domain_name1
        BalancerMember http://other_domain_name2
    </Proxy>
    
    ProxyPass "/public/reverse/" "balancer://myset/"
    ProxyPassReverse "/public/reverse/" "balancer://myset/"
    ```
- [Reference](http://httpd.apache.org/docs/2.4/howto/reverse_proxy.html)

----

### Hide Server Token

- Install mod_security
    ```shell=
    cd /usr/ports/www/mod_security
    make install clean
    ```
- Edit `/usr/local/etc/apacheXX/modules.d/280_mod_security.conf`.
    - Uncomment last 3 lines.
    ```
    LoadModule unique_id_module libexec/apacheXX/mod_unique_id.so
    LoadModule security2_module libexec/apacheXX/mod_security2.so
    Include /usr/local/etc/modsecurity/*.conf
    ```
- Edit `/usr/local/etc/apacheXX/httpd.conf`.
    - Add
    ```
    ServerTokens Full
    SecServerSignature server's_name_you_want
    ```
- [Reference](https://vannilabetter.blogspot.com/2017/12/freebsd-apachephp.html)

----

### HTTPS

- Edit `/usr/local/etc/apacheXX/httpd.conf`.
    - Uncomment
        - `LoadModule socache_shmcb_module libexec/apacheXX/mod_socache_shmcb.so`
        - `LoadModule ssl_module libexec/apacheXX/mod_ssl.so`
        - `Inclue etc/apacheXX/extra/httpd-ssl.conf`
- Create ssl certificate file and key.
    - `openssl req -newkey rsa:2048 -nodes -keyout key.key -x509 -days 365 -out certificate.crt`
    - Review the created certificate
        - `openssl x509 -text -noout -in certificate.crt`
- Edit `/usr/local/etc/apacheXX/extra/httpd-ssl.conf`.
    - Change
        - `DocumentRoot`
        - `ServerName`
        - `SSLEngin on`
        - `SSLCertificateFile "path/to/certificate.crt"`
        - `SSLCertificateKeyFile "path/to/key.key"`
- [Reference](https://vannilabetter.blogspot.com/2017/12/freebsd-apachephp.html)

----

### Auto redirect

- Edit `/usr/local/etc/apacheXX/extra/httpd-vhosts.conf`.
    - Add `Redirect "/" "https://your_domain_name"` in your virtual host.
- [Reference](https://vannilabetter.blogspot.com/2017/12/freebsd-apachephp.html)

---

## Nginx

----

### Install

- Use pkg: Can't customize server token.
    ```shell=
    sudo pkg install nginx
    ```
    - If you want to customize server token, you need to download the tarball or zip file from [here](https://github.com/openresty/headers-more-nginx-module). Configure it by yourself. I didn't try it haha XD
- Use ports:
    ```shell=
    cd /usr/ports/www/nginx
    sudo make install clean
    ```
    - Select `headers-more-nginx-module` while configuring. (To hide server token)
    ![](https://i.imgur.com/GJudBqt.png)
    - You can modify the source code to hide the server token either.

----

### Getting Start

- Read the document [Beginner's guide](https://nginx.org/en/docs/beginners_guide.html)

----

### Virtual Host

- Edit `/usr/local/etc/nginx/nginx.conf`.
    - Add these in http context. (If you don't know what is a context, please refer to the beginner's guide)
    ```
    # Domain name server.
    server {
        listen        80;
        server_name   your_domain_name;
        
        location / {
            root    your_domain_name's_document_root;
            index   index.html index.htm;
        }
    }
    
    # IP address server.
    server {
        listen        80;
        server_name   140.113.66.35;
        
        location / {
            root    your_IP_address's_document_root;
            index   index.html index.htm;
        }
    }
    ```
- [Reference](https://nginx.org/en/docs/http/request_processing.html)

----

### Indexing

- Same as apache server.
- If you use the same document root as your apache server, you don't have to do anything.

----

### htaccess

- Edit `/usr/local/etc/nginx/nginx.conf`.
    - Add these in your server context.
    ```
    location /public/admin/ {
        root    your_document_root;
        index   index.html index.htm;
        auth_basic            "Things you want to tell the user.";
        auth_basic_user_file  path/to/your_user_file;
    }
    ```
    - You can use the same user file as your apache server.
- [Reference](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/)

----

### Reverse Proxy

- Edit `/usr/local/etc/nginx/nginx.conf`.
    - Add these in your http context.
    ```
    upstream backend {
        server http://other_domain_name1;
        server http://other_domain_name2;
    }
    ```
    - Add these in your server context.
    ```
    location /publib/reverse/ {
        root    your_document_root;
        index   index.html index.htm;
        proxy_pass http://backend/;
    }
    ```
- References
    - [Load Balance](https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/)
    - [Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

----

### Hide Server Token

- Method 1: Use `headers-more-nginx-module`.
    - Install module: `headers-more-nginx-module`.
        - Install by ports
        - Download it from github and compile it.
    - Load module we installed.
        - Add it in the beginning of `/usr/local/etc/nginx/nginx.conf`.

            ```
            load_module path/to/your_module/ngx_http_headers_more_filter_module.so;
            ```
        -  If you install the module by ports, the default path will show on the screen while installing it.
        -  But, I know you won't fucking care about this information.
            -  Default path: /usr/local/libexec/nginx/.
    - Change the server token.
        - Add it in the server context.
            ```
            more_set_headers "Server: name_you_prefer";
            ```
    - [Reference](https://github.com/openresty/headers-more-nginx-module#more_set_headers)
- Method 2: Edit source code.
    - Edit source code.
        - Extract `/usr/ports/distfiles/nginx-1.14.1.tar.gz`.
        - Edit `nginx-1.14.1/src/http/ngx_http_header_filter_module.c`.
        - Modify line 49 - 51.
            ```C=49
            static u_char ngx_http_server_string[] = "Server: tree_HTTP_Server" CRLF;
            static u_char ngx_http_server_full_string[] = "Server: tree_HTTP_Server" CRLF;
            static u_char ngx_http_server_build_string[] = "Server: tree_HTTP_Server" CRLF;
            ```
        - Compress it: `tar zcvf nginx-1.14.1.tar.gz nginx-1.14.1/`
    - Calculate checksum and size.
        ```shell=
        openssl dgst -sha256 nginx-1.14.1.tar.gz    # Get checksum.
        ls -l | grep nginx-1.14.1.tar.gz            # Get size.
        ```
        ![Uploading file..._fr4i1nf4u]()

    - Edit `/usr/ports/www/nginx/distinfo`.
        - Modify the checksum and size of nginx-1.14.1.tar.gz
    - Reinstall nginx.
        ```shell=
        ## Stop nginx if it is running.
        ## sudo service nginx stop
        cd /usr/ports/www/nginx/
        sudo make deinstall
        sudo make install clean
        ```
    - Restart nginx.
        ```shell=
        sudo service nginx start
        ```

----

### HTTPS

- User can use same certificate and key as your apache server.
    - Copy your certificate and key under `/usr/local/etc/nginx/`.
    - If you store them under other directory, you need to use full path on the later configuration.
- Edit `/usr/loca/etc/nginx/nginx.conf`.
    - Add these in http context.
    ```
    server {
        listen        443 ssl;
        server_name   your_domain_name;
        
        ssl_certificate        your_certificate;
        ssl_certificate_key    your_key;
        
        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m
        
        ssl_ciphers    HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers    on;
        
            .
            .
            .
        same as above (EX: location ...)
            .
            .
            .
    }
    ```
- [Reference](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/)

----

### Auto Redirection

- Edit `/usr/loca/etc/nginx/nginx.conf`.
    - Add these in http context.
    ```
    server {
        listen        80;
        server_name   your_domain_name;
        return 302 https://$host$request_uri;
    }
    ```
- [Reference](https://serversforhackers.com/c/redirect-http-to-https-nginx)

---

