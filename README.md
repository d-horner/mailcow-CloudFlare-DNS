# mailcow-CloudFlare-DNS

Simple highly opinionated shell script to add DNS mailserver records.

## Usage

### Requirements

`curl` and a POSIX shell (change the shebang!)

Edit the values within the shell script:

```
#################### CLOUDFLARE ACCOUNT CONFIG #####################
auth_mail="enter-your-cloudflare-email" # CF Email
auth_key="enter-your-cloudflare-api-key" # CF API Key
zone_id="enter-your-cloudflare-zone-key" # CF DNS Zone Key
DOMAIN="your-domain.com" # domain.tld
DMARC_RECORD="v=DMARC1; p=reject; rua=mailto:postmaster@<your domain>" # TRY NOT TO CHANGE other than your domain, of course.
DKIM_SELECTOR="dkim._domainkey" # Replace <dkim>._domainkey if you change the selector
DKIM_RECORD="v=DKIM1;k=rsa;t=s;s=email;p=.....your dkim key...." # Replace with the DKIM generated.
MX="mx.yourdomain.com"
#################### /CLOUDFLARE ACCOUNT CONFIG #####################
```

BEWARE! It is opinionated insofar that the `MX=""` is the FQDN and the shebang will need changing to your env.

I went through a stage of setting up a bunch of domains for various reasons - if this makes anyone's life any easier, I'm glad to lend a hand - although I apologise for the hacky nature and tacky ASCII!