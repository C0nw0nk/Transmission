# Transmission

Windows Transmission command line script for use with a VPN privateinternetaccess for when the port changes to automatically update the port transmission uses as the vpn port so that torrenting works

DONATE! The same as buying me a beer or a cup of tea/coffee :D <3

PayPal : https://paypal.me/wimbledonfc

https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ZH9PFY62YSD7U&source=url

Crypto Currency wallets :

BTC BITCOIN : `3A7dMi552o3UBzwzdzqFQ9cTU1tcYazaA1`

ETH ETHEREUM : `0xeD82e64437D0b706a55c3CeA7d116407E43d7257`

SHIB SHIBA INU : `0x39443a61368D4208775Fd67913358c031eA86D59`

# Script Features

Automatically recheck VPN portforwarding and change Transmission settings to the VPN port

# Optional

If you download compressed archives zip rar 7z gzip etc i did built a script to decompress those to so check it out.

https://github.com/C0nw0nk/ExtractNow

# Setup

All you need is Transmission Installed

A VPN PrivateInternetAccess is the one i built it for i can add other VPNs

# Settings

https://github.com/C0nw0nk/Transmission/blob/main/transmission.cmd#L10

To run this Automatically open `command prompt` and `RUN COMMAND PROMPT AS ADMINISTRATOR` and use the following command :
`SCHTASKS /CREATE /SC HOURLY /TN "Cons Transmission Script" /RU "SYSTEM" /TR "C:\Windows\System32\cmd.exe /c start /B "C:\transmission\transmission.cmd"`
