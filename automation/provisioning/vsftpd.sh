#
# Script
#   vsftpd.sh
#
# Current Version
#   v1.2
#
# Description
#   Installs and configures vsftpd as an unsecured service.
#
# Usage
#   vsftpd.sh [ssl_cert_cn ssl_tlsv1 ssl_sslv3 ssl_sslv2]
#
#   For a base Ftp Server with no SSL encoding, omit all arguments:
#       vsftpd.sh
#
#   For a base Ftp Server using SSL encoding (FTPS), specify the common name of the certificate to be generated and which encodings to enable
#   as shown below. For example, to configure an FTPS server with the certificate common name 'FtpServer-SSLv3' to enable only SSLv3 encoding:
#       vsftpd.sh FtpServer-SSLv3 NO YES NO
#
#   Valid values for ssl_tlsv1 ssl_sslv3 and ssl_sslv2 are YES or NO. At least one of these encodings must be set to YES.
#
# Contributors
#   Daniel Schealler, daniel.schealler@gmail.com
#
# Version History
#   Date        Version  Author            Comments
#   2016-09-15  v1.0     Daniel Schealler  First Cut
#   2016-09-15  v1.1     Daniel Schealler  Added Start and End script echos
#   2016-09-28  v1.2     Daniel Schealler  Implemented
#                                            - Copied base.sh implementation to support Ubuntu/Debian and CentOS/RHEL setup
#                                            - Embedded vsftpd.conf into script as a Base64-encoded string variable
#                                            - Tokenization of vsftpd.conf after writing to file
#                                            - Added arguments to the script to enable/disable SSL behaviors
#

scriptName='vsftpd.sh'
echo "[$scriptName] --- start ---"

# Parameterize Arguments
arg1=$1
arg2=$2
arg3=$3
arg4=$4

echo "[$scriptName] Arguments"
echo "  arg1: $arg1"
echo "  arg2: $arg2"
echo "  arg3: $arg3"
echo "  arg4: $arg4"

# Default Parameters
ssl_cert_cn=
ssl_enable=NO
allow_anon_ssl=NO
force_local_data_ssl=NO
force_local_logins_ssl=NO
ssl_tlsv1=NO
ssl_sslv3=NO
ssl_sslv2=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH

encodingSpecified=false

# If the first argument (ssl_cert_cn) is specified, we know that the user has requested FTP over SSL.
if [ -n "$arg1" ]
then
    ssl_cert_cn=$arg1
    ssl_enable=YES
    allow_anon_ssl=NO
    force_local_data_ssl=YES
    force_local_logins_ssl=YES
    ssl_tlsv1=NO
    ssl_sslv3=NO
    ssl_sslv2=NO
    require_ssl_reuse=NO
    ssl_ciphers=HIGH

    # The next argument is for ssl_tlsv1
    if [ -n "$arg2" ]
    then
        if [ "$arg2" = "YES" ]
        then
            ssl_tlsv1=YES
            encodingSpecified=true
        fi
    fi

    # The next argument is for ssl_sslv3
    if [ -n "$arg3" ]
    then
        if [ "$arg3" = "YES" ]
        then
            ssl_sslv3=YES
            encodingSpecified=true
        fi
    fi

    # The next argument is for ssl_sslv2
    if [ -n "$arg4" ]
    then
        if [ "$arg4" = "YES" ]
        then
            ssl_sslv2=YES
            encodingSpecified=true
        fi
    fi
    
    if [ "$encodingSpecified" = false ]
    then
        >&2 echo "[$scriptName] WARNING! An SSL Common Name ($ssl_cert_cn) has been specified, but no SSL encoding methods have been specified. Please refer to the inline documentation of $scriptName for usage examples."
        exit 1
    fi
fi

echo "[$scriptName] Parameters"
echo "  ssl_cert_cn=$ssl_cert_cn"
echo "  ssl_enable=$ssl_enable"
echo "  allow_anon_ssl=$allow_anon_ssl"
echo "  force_local_data_ssl=$force_local_data_ssl"
echo "  force_local_logins_ssl=$force_local_logins_ssl"
echo "  ssl_tlsv1=$ssl_tlsv1"
echo "  ssl_sslv3=$ssl_sslv3"
echo "  ssl_sslv2=$ssl_sslv2"
echo "  require_ssl_reuse=$require_ssl_reuse"
echo "  ssl_ciphers=$ssl_ciphers"

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported"
uname -a
centos=$(uname -a | grep el)

echo "[$scriptName] Install base software (vsftpd)"
if [ -z "$centos" ]; then
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	sudo apt-get update
	sudo apt-get install -y vsftpd
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	sudo yum check-update
	sudo yum install -y vsftpd
fi

if [ -n "$ssl_cert_cn" ]
then
    echo "[$scriptName] Configure SSL Certificate for $ssl_cert_cn"
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/vsftpd.key -out /etc/ssl/certs/vsftpd.pem -subj "/C=NZ/ST=Auckland Region/L=Auckland/O=CDAF.io/OU=QA/CN=$ssl_cert_cn"
fi

configFilePath='/etc/vsftpd.conf';
configFileData='IyBFeGFtcGxlIGNvbmZpZyBmaWxlIC9ldGMvdnNmdHBkLmNvbmYKIwojIFRoZSBkZWZhdWx0IGNvbXBpbGVkIGluIHNldHRpbmdzIGFyZSBmYWlybHkgcGFyYW5vaWQuIFRoaXMgc2FtcGxlIGZpbGUKIyBsb29zZW5zIHRoaW5ncyB1cCBhIGJpdCwgdG8gbWFrZSB0aGUgZnRwIGRhZW1vbiBtb3JlIHVzYWJsZS4KIyBQbGVhc2Ugc2VlIHZzZnRwZC5jb25mLjUgZm9yIGFsbCBjb21waWxlZCBpbiBkZWZhdWx0cy4KIwojIFJFQUQgVEhJUzogVGhpcyBleGFtcGxlIGZpbGUgaXMgTk9UIGFuIGV4aGF1c3RpdmUgbGlzdCBvZiB2c2Z0cGQgb3B0aW9ucy4KIyBQbGVhc2UgcmVhZCB0aGUgdnNmdHBkLmNvbmYuNSBtYW51YWwgcGFnZSB0byBnZXQgYSBmdWxsIGlkZWEgb2YgdnNmdHBkJ3MKIyBjYXBhYmlsaXRpZXMuCiMKIwojIFJ1biBzdGFuZGFsb25lPyAgdnNmdHBkIGNhbiBydW4gZWl0aGVyIGZyb20gYW4gaW5ldGQgb3IgYXMgYSBzdGFuZGFsb25lCiMgZGFlbW9uIHN0YXJ0ZWQgZnJvbSBhbiBpbml0c2NyaXB0LgpsaXN0ZW49WUVTCiMKIyBSdW4gc3RhbmRhbG9uZSB3aXRoIElQdjY/CiMgTGlrZSB0aGUgbGlzdGVuIHBhcmFtZXRlciwgZXhjZXB0IHZzZnRwZCB3aWxsIGxpc3RlbiBvbiBhbiBJUHY2IHNvY2tldAojIGluc3RlYWQgb2YgYW4gSVB2NCBvbmUuIFRoaXMgcGFyYW1ldGVyIGFuZCB0aGUgbGlzdGVuIHBhcmFtZXRlciBhcmUgbXV0dWFsbHkKIyBleGNsdXNpdmUuCiNsaXN0ZW5faXB2Nj1ZRVMKIwojIEFsbG93IGFub255bW91cyBGVFA/IChEaXNhYmxlZCBieSBkZWZhdWx0KQphbm9ueW1vdXNfZW5hYmxlPU5PCiMKIyBVbmNvbW1lbnQgdGhpcyB0byBhbGxvdyBsb2NhbCB1c2VycyB0byBsb2cgaW4uCmxvY2FsX2VuYWJsZT1ZRVMKIwojIFVuY29tbWVudCB0aGlzIHRvIGVuYWJsZSBhbnkgZm9ybSBvZiBGVFAgd3JpdGUgY29tbWFuZC4Kd3JpdGVfZW5hYmxlPVlFUwojCiMgRGVmYXVsdCB1bWFzayBmb3IgbG9jYWwgdXNlcnMgaXMgMDc3LiBZb3UgbWF5IHdpc2ggdG8gY2hhbmdlIHRoaXMgdG8gMDIyLAojIGlmIHlvdXIgdXNlcnMgZXhwZWN0IHRoYXQgKDAyMiBpcyB1c2VkIGJ5IG1vc3Qgb3RoZXIgZnRwZCdzKQpsb2NhbF91bWFzaz0wMjIKIwojIFVuY29tbWVudCB0aGlzIHRvIGFsbG93IHRoZSBhbm9ueW1vdXMgRlRQIHVzZXIgdG8gdXBsb2FkIGZpbGVzLiBUaGlzIG9ubHkKIyBoYXMgYW4gZWZmZWN0IGlmIHRoZSBhYm92ZSBnbG9iYWwgd3JpdGUgZW5hYmxlIGlzIGFjdGl2YXRlZC4gQWxzbywgeW91IHdpbGwKIyBvYnZpb3VzbHkgbmVlZCB0byBjcmVhdGUgYSBkaXJlY3Rvcnkgd3JpdGFibGUgYnkgdGhlIEZUUCB1c2VyLgojYW5vbl91cGxvYWRfZW5hYmxlPVlFUwojCiMgVW5jb21tZW50IHRoaXMgaWYgeW91IHdhbnQgdGhlIGFub255bW91cyBGVFAgdXNlciB0byBiZSBhYmxlIHRvIGNyZWF0ZQojIG5ldyBkaXJlY3Rvcmllcy4KI2Fub25fbWtkaXJfd3JpdGVfZW5hYmxlPVlFUwojCiMgQWN0aXZhdGUgZGlyZWN0b3J5IG1lc3NhZ2VzIC0gbWVzc2FnZXMgZ2l2ZW4gdG8gcmVtb3RlIHVzZXJzIHdoZW4gdGhleQojIGdvIGludG8gYSBjZXJ0YWluIGRpcmVjdG9yeS4KZGlybWVzc2FnZV9lbmFibGU9WUVTCiMKIyBJZiBlbmFibGVkLCB2c2Z0cGQgd2lsbCBkaXNwbGF5IGRpcmVjdG9yeSBsaXN0aW5ncyB3aXRoIHRoZSB0aW1lCiMgaW4gIHlvdXIgIGxvY2FsICB0aW1lICB6b25lLiAgVGhlIGRlZmF1bHQgaXMgdG8gZGlzcGxheSBHTVQuIFRoZQojIHRpbWVzIHJldHVybmVkIGJ5IHRoZSBNRFRNIEZUUCBjb21tYW5kIGFyZSBhbHNvIGFmZmVjdGVkIGJ5IHRoaXMKIyBvcHRpb24uCnVzZV9sb2NhbHRpbWU9WUVTCiMKIyBBY3RpdmF0ZSBsb2dnaW5nIG9mIHVwbG9hZHMvZG93bmxvYWRzLgp4ZmVybG9nX2VuYWJsZT1ZRVMKIwojIE1ha2Ugc3VyZSBQT1JUIHRyYW5zZmVyIGNvbm5lY3Rpb25zIG9yaWdpbmF0ZSBmcm9tIHBvcnQgMjAgKGZ0cC1kYXRhKS4KY29ubmVjdF9mcm9tX3BvcnRfMjA9WUVTCiMKIyBJZiB5b3Ugd2FudCwgeW91IGNhbiBhcnJhbmdlIGZvciB1cGxvYWRlZCBhbm9ueW1vdXMgZmlsZXMgdG8gYmUgb3duZWQgYnkKIyBhIGRpZmZlcmVudCB1c2VyLiBOb3RlISBVc2luZyAicm9vdCIgZm9yIHVwbG9hZGVkIGZpbGVzIGlzIG5vdAojIHJlY29tbWVuZGVkIQojY2hvd25fdXBsb2Fkcz1ZRVMKI2Nob3duX3VzZXJuYW1lPXdob2V2ZXIKIwojIFlvdSBtYXkgb3ZlcnJpZGUgd2hlcmUgdGhlIGxvZyBmaWxlIGdvZXMgaWYgeW91IGxpa2UuIFRoZSBkZWZhdWx0IGlzIHNob3duCiMgYmVsb3cuCiN4ZmVybG9nX2ZpbGU9L3Zhci9sb2cvdnNmdHBkLmxvZwojCiMgSWYgeW91IHdhbnQsIHlvdSBjYW4gaGF2ZSB5b3VyIGxvZyBmaWxlIGluIHN0YW5kYXJkIGZ0cGQgeGZlcmxvZyBmb3JtYXQuCiMgTm90ZSB0aGF0IHRoZSBkZWZhdWx0IGxvZyBmaWxlIGxvY2F0aW9uIGlzIC92YXIvbG9nL3hmZXJsb2cgaW4gdGhpcyBjYXNlLgojeGZlcmxvZ19zdGRfZm9ybWF0PVlFUwojCiMgWW91IG1heSBjaGFuZ2UgdGhlIGRlZmF1bHQgdmFsdWUgZm9yIHRpbWluZyBvdXQgYW4gaWRsZSBzZXNzaW9uLgojaWRsZV9zZXNzaW9uX3RpbWVvdXQ9NjAwCiMKIyBZb3UgbWF5IGNoYW5nZSB0aGUgZGVmYXVsdCB2YWx1ZSBmb3IgdGltaW5nIG91dCBhIGRhdGEgY29ubmVjdGlvbi4KI2RhdGFfY29ubmVjdGlvbl90aW1lb3V0PTEyMAojCiMgSXQgaXMgcmVjb21tZW5kZWQgdGhhdCB5b3UgZGVmaW5lIG9uIHlvdXIgc3lzdGVtIGEgdW5pcXVlIHVzZXIgd2hpY2ggdGhlCiMgZnRwIHNlcnZlciBjYW4gdXNlIGFzIGEgdG90YWxseSBpc29sYXRlZCBhbmQgdW5wcml2aWxlZ2VkIHVzZXIuCiNub3ByaXZfdXNlcj1mdHBzZWN1cmUKIwojIEVuYWJsZSB0aGlzIGFuZCB0aGUgc2VydmVyIHdpbGwgcmVjb2duaXNlIGFzeW5jaHJvbm91cyBBQk9SIHJlcXVlc3RzLiBOb3QKIyByZWNvbW1lbmRlZCBmb3Igc2VjdXJpdHkgKHRoZSBjb2RlIGlzIG5vbi10cml2aWFsKS4gTm90IGVuYWJsaW5nIGl0LAojIGhvd2V2ZXIsIG1heSBjb25mdXNlIG9sZGVyIEZUUCBjbGllbnRzLgojYXN5bmNfYWJvcl9lbmFibGU9WUVTCiMKIyBCeSBkZWZhdWx0IHRoZSBzZXJ2ZXIgd2lsbCBwcmV0ZW5kIHRvIGFsbG93IEFTQ0lJIG1vZGUgYnV0IGluIGZhY3QgaWdub3JlCiMgdGhlIHJlcXVlc3QuIFR1cm4gb24gdGhlIGJlbG93IG9wdGlvbnMgdG8gaGF2ZSB0aGUgc2VydmVyIGFjdHVhbGx5IGRvIEFTQ0lJCiMgbWFuZ2xpbmcgb24gZmlsZXMgd2hlbiBpbiBBU0NJSSBtb2RlLgojIEJld2FyZSB0aGF0IG9uIHNvbWUgRlRQIHNlcnZlcnMsIEFTQ0lJIHN1cHBvcnQgYWxsb3dzIGEgZGVuaWFsIG9mIHNlcnZpY2UKIyBhdHRhY2sgKERvUykgdmlhIHRoZSBjb21tYW5kICJTSVpFIC9iaWcvZmlsZSIgaW4gQVNDSUkgbW9kZS4gdnNmdHBkCiMgcHJlZGljdGVkIHRoaXMgYXR0YWNrIGFuZCBoYXMgYWx3YXlzIGJlZW4gc2FmZSwgcmVwb3J0aW5nIHRoZSBzaXplIG9mIHRoZQojIHJhdyBmaWxlLgojIEFTQ0lJIG1hbmdsaW5nIGlzIGEgaG9ycmlibGUgZmVhdHVyZSBvZiB0aGUgcHJvdG9jb2wuCiNhc2NpaV91cGxvYWRfZW5hYmxlPVlFUwojYXNjaWlfZG93bmxvYWRfZW5hYmxlPVlFUwojCiMgWW91IG1heSBmdWxseSBjdXN0b21pc2UgdGhlIGxvZ2luIGJhbm5lciBzdHJpbmc6CiNmdHBkX2Jhbm5lcj1XZWxjb21lIHRvIGJsYWggRlRQIHNlcnZpY2UuCiMKIyBZb3UgbWF5IHNwZWNpZnkgYSBmaWxlIG9mIGRpc2FsbG93ZWQgYW5vbnltb3VzIGUtbWFpbCBhZGRyZXNzZXMuIEFwcGFyZW50bHkKIyB1c2VmdWwgZm9yIGNvbWJhdHRpbmcgY2VydGFpbiBEb1MgYXR0YWNrcy4KI2RlbnlfZW1haWxfZW5hYmxlPVlFUwojIChkZWZhdWx0IGZvbGxvd3MpCiNiYW5uZWRfZW1haWxfZmlsZT0vZXRjL3ZzZnRwZC5iYW5uZWRfZW1haWxzCiMKIyBZb3UgbWF5IHJlc3RyaWN0IGxvY2FsIHVzZXJzIHRvIHRoZWlyIGhvbWUgZGlyZWN0b3JpZXMuICBTZWUgdGhlIEZBUSBmb3IKIyB0aGUgcG9zc2libGUgcmlza3MgaW4gdGhpcyBiZWZvcmUgdXNpbmcgY2hyb290X2xvY2FsX3VzZXIgb3IKIyBjaHJvb3RfbGlzdF9lbmFibGUgYmVsb3cuCmNocm9vdF9sb2NhbF91c2VyPVlFUwphbGxvd193cml0ZWFibGVfY2hyb290PVlFUwojCiMgWW91IG1heSBzcGVjaWZ5IGFuIGV4cGxpY2l0IGxpc3Qgb2YgbG9jYWwgdXNlcnMgdG8gY2hyb290KCkgdG8gdGhlaXIgaG9tZQojIGRpcmVjdG9yeS4gSWYgY2hyb290X2xvY2FsX3VzZXIgaXMgWUVTLCB0aGVuIHRoaXMgbGlzdCBiZWNvbWVzIGEgbGlzdCBvZgojIHVzZXJzIHRvIE5PVCBjaHJvb3QoKS4KIyAoV2FybmluZyEgY2hyb290J2luZyBjYW4gYmUgdmVyeSBkYW5nZXJvdXMuIElmIHVzaW5nIGNocm9vdCwgbWFrZSBzdXJlIHRoYXQKIyB0aGUgdXNlciBkb2VzIG5vdCBoYXZlIHdyaXRlIGFjY2VzcyB0byB0aGUgdG9wIGxldmVsIGRpcmVjdG9yeSB3aXRoaW4gdGhlCiMgY2hyb290KQojY2hyb290X2xvY2FsX3VzZXI9WUVTCiNjaHJvb3RfbGlzdF9lbmFibGU9WUVTCiMgKGRlZmF1bHQgZm9sbG93cykKI2Nocm9vdF9saXN0X2ZpbGU9L2V0Yy92c2Z0cGQuY2hyb290X2xpc3QKIwojIFlvdSBtYXkgYWN0aXZhdGUgdGhlICItUiIgb3B0aW9uIHRvIHRoZSBidWlsdGluIGxzLiBUaGlzIGlzIGRpc2FibGVkIGJ5CiMgZGVmYXVsdCB0byBhdm9pZCByZW1vdGUgdXNlcnMgYmVpbmcgYWJsZSB0byBjYXVzZSBleGNlc3NpdmUgSS9PIG9uIGxhcmdlCiMgc2l0ZXMuIEhvd2V2ZXIsIHNvbWUgYnJva2VuIEZUUCBjbGllbnRzIHN1Y2ggYXMgIm5jZnRwIiBhbmQgIm1pcnJvciIgYXNzdW1lCiMgdGhlIHByZXNlbmNlIG9mIHRoZSAiLVIiIG9wdGlvbiwgc28gdGhlcmUgaXMgYSBzdHJvbmcgY2FzZSBmb3IgZW5hYmxpbmcgaXQuCiNsc19yZWN1cnNlX2VuYWJsZT1ZRVMKIwojIEN1c3RvbWl6YXRpb24KIwojIFNvbWUgb2YgdnNmdHBkJ3Mgc2V0dGluZ3MgZG9uJ3QgZml0IHRoZSBmaWxlc3lzdGVtIGxheW91dCBieQojIGRlZmF1bHQuCiMKIyBUaGlzIG9wdGlvbiBzaG91bGQgYmUgdGhlIG5hbWUgb2YgYSBkaXJlY3Rvcnkgd2hpY2ggaXMgZW1wdHkuICBBbHNvLCB0aGUKIyBkaXJlY3Rvcnkgc2hvdWxkIG5vdCBiZSB3cml0YWJsZSBieSB0aGUgZnRwIHVzZXIuIFRoaXMgZGlyZWN0b3J5IGlzIHVzZWQKIyBhcyBhIHNlY3VyZSBjaHJvb3QoKSBqYWlsIGF0IHRpbWVzIHZzZnRwZCBkb2VzIG5vdCByZXF1aXJlIGZpbGVzeXN0ZW0KIyBhY2Nlc3MuCnNlY3VyZV9jaHJvb3RfZGlyPS92YXIvcnVuL3ZzZnRwZC9lbXB0eQojCiMgVGhpcyBzdHJpbmcgaXMgdGhlIG5hbWUgb2YgdGhlIFBBTSBzZXJ2aWNlIHZzZnRwZCB3aWxsIHVzZS4KcGFtX3NlcnZpY2VfbmFtZT12c2Z0cGQKIwojIFRoaXMgb3B0aW9uIHNwZWNpZmllcyB0aGUgbG9jYXRpb24gb2YgdGhlIFJTQSBjZXJ0aWZpY2F0ZSB0byB1c2UgZm9yIFNTTAojIGVuY3J5cHRlZCBjb25uZWN0aW9ucy4KcnNhX2NlcnRfZmlsZT0vZXRjL3NzbC9jZXJ0cy92c2Z0cGQucGVtCiMgVGhpcyBvcHRpb24gc3BlY2lmaWVzIHRoZSBsb2NhdGlvbiBvZiB0aGUgUlNBIGtleSB0byB1c2UgZm9yIFNTTAojIGVuY3J5cHRlZCBjb25uZWN0aW9ucy4KcnNhX3ByaXZhdGVfa2V5X2ZpbGU9L2V0Yy9zc2wvcHJpdmF0ZS92c2Z0cGQua2V5CiMKIyBFbmFibGUgUGFzc2l2ZSBNb2RlCnBhc3ZfZW5hYmxlPVlFUwpwYXN2X21pbl9wb3J0PTQwMDAwCnBhc3ZfbWF4X3BvcnQ9NDAxMDAKIwojIEVuYWJsZSBTU0wKc3NsX2VuYWJsZT0lc3NsX2VuYWJsZSUKYWxsb3dfYW5vbl9zc2w9JWFsbG93X2Fub25fc3NsJQpmb3JjZV9sb2NhbF9kYXRhX3NzbD0lZm9yY2VfbG9jYWxfZGF0YV9zc2wlCmZvcmNlX2xvY2FsX2xvZ2luc19zc2w9JWZvcmNlX2xvY2FsX2xvZ2luc19zc2wlCnNzbF90bHN2MT0lc3NsX3Rsc3YxJQpzc2xfc3NsdjI9JXNzbF9zc2x2MiUKc3NsX3NzbHYzPSVzc2xfc3NsdjMlCnJlcXVpcmVfc3NsX3JldXNlPSVyZXF1aXJlX3NzbF9yZXVzZSUKc3NsX2NpcGhlcnM9JXNzbF9jaXBoZXJzJQo='

echo "[$scriptName] Writing vsftpd configuration data to $configFilePath"
sudo echo "$configFileData" | base64 --decode > "$configFilePath"

echo "[$scriptName] Detokenizing $configFilePath"
sudo perl -i -pe "s/%ssl_enable%/$ssl_enable/g; s/%allow_anon_ssl%/$allow_anon_ssl/g; s/%force_local_data_ssl%/$force_local_data_ssl/g; s/%force_local_logins_ssl%/$force_local_logins_ssl/g; s/%ssl_tlsv1%/$ssl_tlsv1/g; s/%ssl_sslv2%/$ssl_sslv2/g; s/%ssl_sslv3%/$ssl_sslv3/g; s/%require_ssl_reuse%/$require_ssl_reuse/g; s/%ssl_ciphers%/$ssl_ciphers/g" "$configFilePath"

echo "[$scriptName] Restart the vsftpd service"
sudo service vsftpd restart

echo "[$scriptName] --- end ---"
exit 0