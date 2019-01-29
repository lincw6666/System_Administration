SA Homework 05
===

---

## NFS Service

----

### NFS Server

- Edit `/etc/rc.conf`.
```shell=
rpcbind_enable="YES"
nfs_server_enable="YES"
nfs_server_flags="-u -t -n 4"
nfsv4_server_enable="YES"
mountd_enable="YES"
mountd_flags="-r"
nfsuserd_enable="YES"
nfsuserd_flags="-domain SA-HW -manage-gids"
```

----

### NFS Client

- Edit `/etc/rc.conf`.
```shell=
nfs_client_enable="YES"
autofs_enablve="YES"
nfsuserd_enablve="YES"
nfsuserd_flags="-domain SA-HW"
```

---

## NIS Service

----

### NIS Master

- Edit `/etc/rc.conf`.
```shell=
nisdomainnmae="SA-HW"
nis_server_enable="YES"
nis_yppasswdd_enable="YES"
nis_yppasswdd_flags="-t /var/yp/src/master.passwd"
```

----

### NIS Slave

- Edit `/etc/rc.conf`.
```shell=
nisdomainname="SA-HW"
nis_server_enable="YES"
```

----

### NIS Client

- Edit `/etc/rc.conf`.
```shell=
nis_client_enable="YES"
nis_client_flags="-s -m -S SA-HW,storage,account"
```
- `-S` follow by nis_domain_name,server1,server2... Up to 10 servers can be specified. The last server specified gains the highest privilege. In this case, account has higher privilege than storage.

---

## Bonus 1
share autofs.map by nis

----

### /var/yp/Makefile
Only NIS master needs it.
- Add the path to your autofs map.
    ```makefile=131
    AUTOMAP = $(YPSRCDIR)/auto_share
    ```
- Add whatever you want to map into `TARGETS`.
    ```makefile=205
    .if exists($(AUTOMAP))
    TARGETS+= automap
    .else
    AUTOMAP= /dev/null
    .endif
    ```
    ```makefile=230
    automap: auto_behind auto_front
    ```
    - Remark: You can add automap to `TARGETS` directly. But if autofs map does not exist, it will cry something failed blablabla... However, it still works. It will not crash. I just don't like these fucking warnings.
- Copy `amd.map` (at the end of the file).
    - Modify amd.map to **auto_behind** or **auto_front**.
    - Replace `AMDHOST` with `AUTOMAP`.
- Differences.
    ```make=
    129,131c129
    < 
    < # SA bonus1
    < AUTOMAP   = $(YPSRCDIR)/auto_share
    ---
    > #AMDHOST   = $(YPSRCDIR)/autofs.map
    205,210d202
    < .if exists($(AUTOMAP))
    < TARGETS+= automap
    < .else
    < AUTOMAP= /dev/null
    < .endif
    < 
    230d221
    < automap:   auto_behind auto_front
    241,279d231
    < 
    < auto_behind: $(AUTOMAP)
    < 	@echo "Updating $@..."
    < 	@$(AWK) '$$1 !~ "^#.*"  { \    
    < 	  for (i = 1; i <= NF; i++) \
    < 	  if (i == NF) { \
    < 	    if (substr($$i, length($$i), 1) == "\\") \
    < 	      printf("%s", substr($$i, 1, length($$i) - 1)); \
    < 	    else \
    < 	      printf("%s\n", $$i); \
    < 	  } \
    < 	  else \
    < 	    printf("%s ", $$i); \
    < 	}' $(AUTOMAP) | \
    < 	$(DBLOAD) -i $(AUTOMAP) -o $(YPMAPDIR)/$@ - $(TMP); \
    < 		$(RMV) $(TMP) $@
    < 	@$(DBLOAD) -c
    < 	@if [ ! $(NOPUSH) ]; then $(YPPUSH) -d $(DOMAIN) $@; fi
    < 	@if [ ! $(NOPUSH) ]; then echo "Pushed $@ map." ; fi
    < 
    < auto_front: $(AUTOMAP)
    < 	@echo "Updating $@..."
    < 	@$(AWK) '$$1 !~ "^#.*"  { \
    < 	  for (i = 1; i <= NF; i++) \
    < 	  if (i == NF) { \
    < 	    if (substr($$i, length($$i), 1) == "\\") \
    < 	      printf("%s", substr($$i, 1, length($$i) - 1)); \
    < 	    else \
    < 	      printf("%s\n", $$i); \
    < 	  } \
    < 	  else \
    < 	    printf("%s ", $$i); \
    < 	}' $(AUTOMAP) | \
    < 	$(DBLOAD) -i $(AUTOMAP) -o $(YPMAPDIR)/$@ - $(TMP); \
    < 		$(RMV) $(TMP) $@
    < 	@$(DBLOAD) -c
    < 	@if [ ! $(NOPUSH) ]; then $(YPPUSH) -d $(DOMAIN) $@; fi
    < 	@if [ ! $(NOPUSH) ]; then echo "Pushed $@ map." ; fi
    < 
    ```
----

### auto_master
- Link `/etc/autofs/include` to `/etc/autofs/include_nis`.
    ```sh=
    sudo ln -s /etc/autofs/include_nis /etc/autofs/include
    ```

---

## Bonus 2
Create accounts on NIS with random password.

----

### autocreate
I am lazy zzz. Trace the code and you will understand haha.
- How to use
    ```sh=
    sudo ./autocreate <group> <account-list>
    ```
    - It works under any directory.
    - It will update NIS map automatically.
