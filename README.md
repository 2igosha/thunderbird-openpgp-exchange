# Patch for Thunderbird to handle broken OpenPGP messages

This patch modifies the code that is supposed to detect broken OpenPGP messages. If you are getting blank messages with attachments named "encrypted.asc" and "PGPMIME version identification", and the MIME source also include a part of type "multipart/alternative", this patch will help.

The patch utility should be applied at -p5 (that is, removing the 5 leading directory names), or just by manually editing two files in the archive "omni.ja" that comes with your Thunderbird distribution. You need to unpack "omni.ja" with 7-zip or Windows unzip feature, apply the patch and then zip it back. There are just a few lines to be modified in two files:

*chrome/openpgp/content/openpgp/modules/fixExchangeMsg.js*
```diff
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

```

*chrome/openpgp/content/openpgp/ui/enigmailMessengerOverlay.js*
```diff
@@ -882,7 +882,7 @@ Enigmail.msg = {
           mimeMsg.fullContentType.search(/multipart\/mixed/i) >= 0 &&
           mimeMsg.subParts[0].fullContentType.search(/multipart\/encrypted/i) <
             0 &&
-          mimeMsg.subParts[0].fullContentType.search(/text\/(plain|html)/i) >=
+          mimeMsg.subParts[0].fullContentType.search(/(text\/(plain|html)|multipart\/alternative)/i) >=
             0 &&
           mimeMsg.subParts[1].fullContentType.search(
             /application\/pgp-encrypted/i
```


The [original Mozilla's](https://developer.mozilla.org/en-US/docs/Mozilla/About_omni.ja_(formerly_omni.jar)) description states that "omni.ja" has to be repacked  in a very specific way:

```
omni.ja is also incompatible with Zip files in the other direction; editing extracted files won't affect Firefox, and repacking edited files may break Firefox if you do not use the right options when packing the extracted files. The correct command to pack omni.ja is:

zip -0DXqr omni.ja *

The working directory must be at the root directory of the files from the omni.ja file. zip -0DXqr omni.ja path/to/omni/* will not work.
```

Then, you need to replace the original "omni.ja" and restart Thunderbird. Now, for every broken message there will be a yellow band with a "Repair" button. Once repaired, the message will stay in the proper OpenPGP format in your inbox.

I created [bug 1689086](https://bugzilla.mozilla.org/show_bug.cgi?id=1689086) on Bugzilla suggesting the patch. There is also a Bash script (patch.sh) that will attempt to apply the patch and repack everything automatically, if Thunderbird is installed in "/usr/lib/thunderbird".


