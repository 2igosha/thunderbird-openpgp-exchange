#!/bin/sh
# https://github.com/2igosha/thunderbird-openpgp-exchange
mkdir /tmp/th
cd /tmp/th
rm -rf /tmp/th/*
cp /usr/lib/thunderbird/omni.ja /tmp/th_omni.ja
7z x /tmp/th_omni.ja
rm /tmp/th_omni.ja
sudo cp /usr/lib/thunderbird/omni.ja /usr/lib/thunderbird/omni.ja.bak || ( echo Failed to back up /usr/lib/thunderbird/omni.ja && exit 1 )
patch -d /tmp/th/chrome/openpgp/content/openpgp -p5 << EOF
diff --git a/mail/extensions/openpgp/content/modules/fixExchangeMsg.jsm b/mail/extensions/openpgp/content/modules/fixExchangeMsg.jsm
--- a/mail/extensions/openpgp/content/modules/fixExchangeMsg.jsm
+++ b/mail/extensions/openpgp/content/modules/fixExchangeMsg.jsm
@@ -185,8 +185,9 @@ var EnigmailFixExchangeMsg = {
     try {
       let isIPGMail =
         msgTree.subParts.length === 3 &&
-        msgTree.subParts[0].headers.get("content-type").type.toLowerCase() ===
-          "text/plain" &&
+        ( ( msgTree.subParts[0].headers.get("content-type").type.toLowerCase() ===
+          "text/plain" ) || ( msgTree.subParts[0].headers.get("content-type").type.toLowerCase() ===
+          "multipart/alternative" ) )  &&
         msgTree.subParts[1].headers.get("content-type").type.toLowerCase() ===
           "application/pgp-encrypted" &&
         msgTree.subParts[2].headers.get("content-type").type.toLowerCase() ===
@@ -290,7 +291,7 @@ var EnigmailFixExchangeMsg = {
     if (
       bodyData
         .substring(skipStart, versionIdent)
-        .search(/^content-type:[ \t]*text\/(plain|html)/im) < 0
+        .search(/^content-type:[ \t]*(text\/(plain|html)|multipart\/alternative)/im) < 0
     ) {
       EnigmailLog.DEBUG(
         "fixExchangeMsg.jsm: getCorrectedExchangeBodyData: first MIME part is not content-type text/plain or text/html\n"
diff --git a/mail/extensions/openpgp/content/ui/enigmailMessengerOverlay.js b/mail/extensions/openpgp/content/ui/enigmailMessengerOverlay.js
--- a/mail/extensions/openpgp/content/ui/enigmailMessengerOverlay.js
+++ b/mail/extensions/openpgp/content/ui/enigmailMessengerOverlay.js
@@ -882,7 +882,7 @@ Enigmail.msg = {
           mimeMsg.fullContentType.search(/multipart\/mixed/i) >= 0 &&
           mimeMsg.subParts[0].fullContentType.search(/multipart\/encrypted/i) <
             0 &&
-          mimeMsg.subParts[0].fullContentType.search(/text\/(plain|html)/i) >=
+          mimeMsg.subParts[0].fullContentType.search(/(text\/(plain|html)|multipart\/alternative)/i) >=
             0 &&
           mimeMsg.subParts[1].fullContentType.search(
             /application\/pgp-encrypted/i
EOF
zip -0DXqr /tmp/th_omni.ja *
ls -la /tmp/th_omni.ja
sudo cp /tmp/th_omni.ja /usr/lib/thunderbird/omni.ja || ( echo Failed to replace /usr/lib/thunderbird/omni.ja && exit 1 )
echo Please try to launch thunderbird now. The backup is in /usr/lib/thunderbird/omni.ja.bak
