#!/usr/local/bin/zsh
#
scriptVersion="v0.9"
# Manual Config (0 input)
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
#####################################################################
# !!! DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING !!! #
#####################################################################
#
# Add CloudFlare DNS records for mail - not a chance in hell i was configuring anymore domains with this many records!
#                                 .^,
#                                 ||)\
#                                 ||{,\
#                                 ||{@}\
#                                 || \{@\
#                                 ||--\@}\
#                                /||   \{&\
#                               //||====\#\\
#                              // ||(GBR)\#}\
#                             //==||======\}}\
#                            //   ||       \(}\
#                           //====||--------\{(\
#                          // GBR ||         \@@),
#                         //======||ññññññññññ\{*},
#                        //-------||  /\\ ''   `/}`
#                       //________||,`  \\ -=={/___
#                     <<<+,_______##_____\\___[£££]
#                          \-==-"TODO LIST"-==-/|dD]
# ~~~~~~~~~~~~~~~~~~~~~~~~~~\--0--0--0--0--0--/~P#,)~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~\_______________/~~L.D)~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# TODO: commandline args
# TODO logic to check if config file exists, check params are set and if not, check if they are hardcoded in, if not then as to set defaults.
#      - write the changes to config file.
# TODO: function to update status of record creation.
# TODO: error handling for curl status codes if != 200 --> check public DNS w/ dig? --> failing that use zonal lookup via CF - maybe not populated yet.
# TODO: Add conditional logic if the fields above are not set to read input from stdin
# echo -e "Cloudflare Email: \n"
# read auth_mail
# echo -e "Cloudflare API Key: \n"
# read auth_key
# echo -e "Domain: \n"
# read DOMAIN
# echo -e "ZoneID: \n"
# read ZONEID

CLR="\e[0m"
redFG="\e[91m"
redBG="\e[101m"
greenFG="\e[92m"
blueFG="\e[34m"
greenBG="\e[102m"
greyBG="\e[100m"
BLD="\e[1m"
DIM="\e[2m"
BLI="\e[5m"
UL="\e[4m"
greenBGd="\e[100m\e[1m"

RECORDNAME="imap"
RECORDPORT=143
clear
echo -e "${greenBG}                                                     ${CLR}${greenBGd}  ${CLR}"
echo -e "${greenBG}  ${greyBG}${BLD} ${scriptVersion} - CloudFlare mailserver DNS record config ${CLR}${greenBG}   ${CLR}${greenBGd}  ${CLR}"
echo -e "${greenBG}                                                     ${CLR}${greenBGd}  ${CLR}"
echo -e "${greenBG}  ${greyBG}${BLD} (c) Dan Horner ${CLR}${greenBG}                                   ${CLR}${greenBGd}  ${CLR}"
echo -e "${greenBG}                                                     ${CLR}${greenBGd}  ${CLR}"
echo -e "${greenBGd}                                                       ${CLR}\n\n\n"

_post_cf_srv () {
     RES=$(curl -w '%{http_code}\n' -so /dev/null -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
     -H "X-Auth-Email: "$auth_mail \
     -H "X-Auth-Key: "$auth_key \
     -H "Content-Type: application/json" \
     --data "{\"type\": \"SRV\", \"name\": \"_${RECORDNAME}._tcp.${DOMAIN}.\", \"content\": \"SRV 0 1 ${RECORDPORT} ${MX}.\", \"ttl\": 1, \"data\": {\"priority\": 0, \"weight\": 1, \"port\": ${RECORDPORT}, \"target\": \"${TARGET}.\", \"service\": \"_${RECORDNAME}\", \"proto\": \"_tcp\", \"name\": \"${DOMAIN}.\"},\"proxied\": false}");
     if [[ $RES -eq 200 ]]; then
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG} ${BLD}SRV ${CLR}]" "_${RECORDNAME}._tcp.${DOMAIN}." "IN SRV 0 1" "${RECORDPORT} ${MX}." "[${greenBG}${BLD} OK ${CLR}]"); echo $OUT >&2
     else
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG} ${BLD}SRV ${CLR}]" "_${RECORDNAME}._tcp.${DOMAIN}." "IN SRV 0 1" "${RECORDPORT} ${MX}." "[${redBG}${BLD}${BLI}ERROR${CLR}]"); echo $OUT >&2
     fi
}

_post_cf_cname () {
     RES=$(curl -w '%{http_code}\n' -so /dev/null -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
     -H "X-Auth-Email: "$auth_mail \
     -H "X-Auth-Key: "$auth_key \
     -H "Content-Type: application/json" \
     --data "{\"type\": \"CNAME\", \"name\": \"${RECORDNAME}\", \"content\": \"${TARGET}.\", \"ttl\": 120, \"priority\": 0, \"proxied\": true}");
     if [[ $RES -eq 200 ]]; then
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG}${BLD}CNAME${CLR}]" "${RECORDNAME}" "IN CNAME" "${TARGET}." "[${greenBG}${BLD} OK ${CLR}]"); echo $OUT >&2
     else
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG}${BLD}CNAME${CLR}]" "${RECORDNAME}" "IN CNAME" "${TARGET}." "[${redBG}${BLD}${BLI}ERROR${CLR}]"); echo $OUT >&2
     fi
}

_post_cf_txt () {
     RES=$(curl -w '%{http_code}\n' -so /dev/null -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
     -H "X-Auth-Email: "$auth_mail \
     -H "X-Auth-Key: "$auth_key \
     -H "Content-Type: application/json" \
     --data "{\"type\": \"TXT\", \"name\": \"${RECORDNAME}\", \"content\": \"${TXT}\", \"ttl\": 120, \"priority\": 0}");
     if [[ $RES -eq 200 ]]; then
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG} ${BLD}TXT ${CLR}]" "${RECORDNAME}" "IN TXT" "$(printf %-.20s ${TXT})" "[${greenBG}${BLD} OK ${CLR}]"); echo $OUT >&2
     else
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG} ${BLD}TXT ${CLR}]" "${RECORDNAME}" "IN TXT" "$(printf %-.20s ${TXT})" "[${redBG}${BLD}${BLI}ERROR${CLR}]"); echo $OUT >&2
     fi
}

_post_cf_mx () {
     RES=$(curl -w '%{http_code}\n' -so /dev/null -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
     -H "X-Auth-Email: "$auth_mail \
     -H "X-Auth-Key: "$auth_key \
     -H "Content-Type: application/json" \
     --data "{\"type\": \"MX\", \"name\": \"@\", \"content\": \"${MX}\", \"ttl\": 120, \"priority\": 10}");

     if [[ $RES -eq 200 ]]; then
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG} ${BLD}MX  ${CLR}]" "@" "IN MX 10" "${MX}" "[${greenBG}${BLD} OK ${CLR}]"); echo $OUT >&2
     else
          OUT=$(printf "%7s  %30s  %20s  %20s  %7s\n" "[${greyBG} ${BLD}MX  ${CLR}]" "@" "IN MX 10" "${MX}" "[${redBG}${BLD}${BLI}ERROR${CLR}]"); echo $OUT >&2
     fi
}

# imap
RECORDPORT=143
RECORDNAME="imap"
TARGET=${MX}
$(_post_cf_srv)

# imaps
RECORDPORT=993
RECORDNAME="imaps"
TARGET=${MX}
$(_post_cf_srv)

# pop3
RECORDPORT=110
RECORDNAME="pop3"
TARGET=${MX}
$(_post_cf_srv)

# pop3s
RECORDPORT=995
RECORDNAME="pop3s"
TARGET=${MX}
$(_post_cf_srv)

# submission
RECORDPORT=587
RECORDNAME="submission"
TARGET=${MX}
$(_post_cf_srv)

# smtps
RECORDPORT=465
RECORDNAME="smtps"
TARGET=${MX}
$(_post_cf_srv)

# sieve
RECORDPORT=4190
RECORDNAME="sieve"
TARGET=${MX}
$(_post_cf_srv)

# autodiscover
RECORDPORT=443
RECORDNAME="autodiscover"
TARGET=${MX}
$(_post_cf_srv)

# MX: to mailhost TODO: add other SRV record
RECORDNAME="mail.${DOMAIN}"
TARGET=${MX}
$(_post_cf_mx)


# TODO: autoconfig
RECORDNAME="autodiscover.${DOMAIN}"
TARGET=${MX}
$(_post_cf_cname)

RECORDNAME="autoconfig.${DOMAIN}"
TARGET=${MX}
$(_post_cf_cname)

# carddavs
RECORDPORT=443
RECORDNAME="carddavs"
TARGET=${MX}
$(_post_cf_srv)

# --DONE-- add txt record for carddavs
RECORDNAME="_carddavs._tcp"
TXT="path=/SOGo/dav/"
$(_post_cf_txt)

# SRV: caldavs
RECORDPORT=443
RECORDNAME="caldavs"
TARGET=${MX}
$(_post_cf_srv)


# TXT: caldavs
RECORDNAME="_caldavs._tcp"
TXT="path=/SOGo/dav/"
$(_post_cf_txt)

# SPF:
RECORDNAME="@"
TXT="v=spf1 mx ~all"
$(_post_cf_txt)

# TODO: add _dmarc txt record
# echo -e "[ ? ] What is the _dmarc RECORD?\n"
# read TXT
RECORDNAME="_dmarc"
TXT=${DMARC_RECORD}
$(_post_cf_txt)


# TODO: add dkim TXT record
# echo -e "[ ? ] What is the _dkim SELECTOR?\n"
# read RECORDNAME
# echo -e "[ ? ] What is the _dkim RECORD?\n"
# read TXT
RECORDNAME=${DKIM_SELECTOR}
TXT=${DKIM_RECORD}
$(_post_cf_txt)


# TODO: add CNAME to mail --> mxhost
echo -e "\n\n\n"
echo -e "[${greenBG} *** ${CLR}]${greyBG} ${CLR}[${greenBG}${BLD} GOOGLE POSTMASTER ${CLR}]${greyBG}   Setup TXT record on ${DOMAIN} @ ${UL}${blueFG}https://postmaster.google.com/ ${CLR}"
echo -e "\n\n\n"




