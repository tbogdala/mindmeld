# Change Log

## v1.1.0

* update: upstream woolycore and woolydart libraries and updated build scripts to work with the newer versions.

* feature: tokens are now showed 'in flight' as they're getting predicted.
* feature: speed of generation is shown dynamically, 'in flight'.
* feature: chatlogs can be duplicated by long-pressing on them and choosing 'Duplicate Chatlog'.
* feature: added 'Copy Message' to the long-press menu on messages which copies the text to the clipboard.

* bugfix: fixed an error code 7 type error on prediction that was related to bos tokens.
* bugfix: fixed a problem where changing chat logs didn't necessarily load a new model if they differed in what they used.
* bugfix: fixed a bug where the temperature, frequency and presence penalties settings for the chatlog wasn't being used.
* bugfix: new prediction functions seem to fix a mysterious bug where llama3 or gemma models had to get changed
  to the chatml prompt format in order to generate a response.
* bugfix: only show the progress circle when the matching chatlog is selected and shown while generating a message.
* bugfix: fixed keyboard type being set to 'number' for the 'matching characters' textfield of a lorebook.
