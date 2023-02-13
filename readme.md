The planed Structure

``` 
/etc/asterisk/extensions.conf
/etc/asterisk/extensions.d/
  /etc/asterisk/extensions.d/global/
    features.conf
    settings.conf
    outbound.conf
  /etc/asterisk/extensions.d/failover/
    features.conf
    settings.conf
    outbound.conf
  /etc/asterisk/extensions.d/tenants/
  /etc/asterisk/extensions.d/tenants/tenet1/
    users.conf
    inbound.conf
    outbound.conf
    routes.conf
  /etc/asterisk/extensions.d/tenants/tenet2/
    users.conf
    inbound.conf
    outbound.conf
    routes.conf
```


    
in 
extensions.conf 
[general]
 
[global]
#include extensions.d/global/*.conf

[tenets]
#include extensions.d/tenants/*/*.conf

[failover]
#include extensions.d/failover/*.conf
  
