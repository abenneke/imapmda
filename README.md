# imapmda
Simple perl based local mail delivery agent to an IMAP server

## Motivation

If you host your mail accounts at IONOS, you are also affected by a recent change (Jan 2024) in their policy of only accepting mails with a sender that matches the login on the mail server. Other mails will be rejected with `Sender address is not allowed`.

While this policy is perfectly reasonable on its own, it breaks the delivery of mail from fetchmail. 
The mails fetchmail collects almost never have a sender that matches the new policy. 
After discussing this back and forth with IONOS support, they could not offer me a simple solution. (One would have been to accept not only a sender matching the domain, but also if the recipient is from the given domain).

**Example**

* Fetchmail fetches a mail from `someone@somewhere.com` to `mymail@web.de`.
* Fetchmail then tries to forward this mail to `me@mydomain.com` using the local MTA (in this case postfix).
* Postfix is configured to deliver mail to the `smtp` server with `user@mydomain.com` as login.
* But with the new policy, the `smtp` server will reject such a mail with `Sender address is not allowed`.
    * because `*@somewhere.com` does not match `@mydomain.com`.

My workaround is now not to use SMTP for forwarding, but to append the mails directly to the users' IMAP folders.

## Preconditions

* have Perl installed
* have `libmail-imapclient-perl` installed

## Setup

* Copy the `mapmda.pl` to a folder (e. g. `/usr/local/bin`)
* Make it executable for the same user that runs the fetchmail daemon (`fetchmail` in my case)
* Create a `/etc/imapmda/localuser` file (directory configured in `mapmda.pl`) for each user `localuser` you want to deliver mails to.
* These files have the following content:

```
    {
        server => 'your.imap.server.de',
        user => 'username-on-imap-server',
        password  => 'password-on-imap-server',
        folder => 'INBOX',
    }
```

* Make `/etc/imapmda/` and the files in it readable only by the user running the fetchmail daemon (`fetchmail` in my case).
* Add `mda "/usr/local/bin/imapmda.pl %T"` to your `/etc/fetchmailrc`.
* Replace the local mail addresses with the `localuser` names

After this, my `/etc/fetchmailrc` basically looks like this

    defaults
        fetchall
        ssl
        mda "/usr/local/bin/imapmda.pl %T"

    poll imap.web.de protocol IMAP:
        user "mymail@web.de" with password "my-password-at-web-de" is localuser here

## How it works

* Fetchmail calls the script with the `localuser` as a command line parameter (`%T` in the `mda` configuration)
* and passes the downloaded mail to `STDIN`.
* `mapmda.pl` reads the configuration file,
* joins the lines of the mail into a single `$mail` variable,
* connects to the IMAP server,
* and appends the mail to the configured folder.
* When done, it disconnects from the server.

## Troubleshooting

* The script will fail with an error if the mail could not be delivered. 
* This should stop fetchmail from flushing the mail from the source.
* Fetchmail will log the (error) output of the script to its usual logging target (`/var/log/mail.log` in my case).
* Look there first to see what went wrong.

*Hope this helps someone!*
