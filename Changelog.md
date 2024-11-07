# Change Log

## v1.2.0

* update: upgraded project dependencies

* feature: new application-level configuration file added called 'mindmeld.json' in the documents folder.
  it has an 'options' map of String to String, which is intended to be used for 'low-level' overrides
  or experimental features. these settings can be set with the `/set <option> <value>` command, 
  unset with the `/unset <option>` command, or just manually edited in the configuration file itself,
  though those settings are only read once at application loading.
* feature: the prompt being constructed and sent to the AI LLM is now configurable through the
  application configuration file. See docs/app_config.md for more information.


## v1.1.0

* update: upstream woolycore and woolydart libraries and updated build scripts to work with the newer versions.

* feature: tokens are now shown 'in flight' as they're getting predicted.
* feature: speed of generation is shown dynamically, 'in flight'.
* feature: exposed upstream support for DRY, XTC and dynamic temperature samplers.
* feature: chatlogs can be duplicated by long-pressing on them and choosing 'Duplicate Chatlog'.
* feature: added 'Copy Message' to the long-press menu on messages which copies the text to the clipboard.
* feature: added 'Stop AI Response'  to the long-press menu on the in-flight message which stops the reply.
* feature: added 'plainText' prompt formatting for using base models (non-instruct tuned).
* feature: added llama 3.2 3B & 1B models to the automatic download list.

* bugfix: fixed an error code 7 type error on prediction that was related to bos tokens.
* bugfix: fixed a problem where changing chat logs didn't necessarily load a new model if they differed in what they used.
* bugfix: fixed a bug where the temperature, frequency and presence penalties settings for the chatlog were not being used.
* bugfix: new prediction functions seem to fix a mysterious bug where llama3 or gemma models had to get changed
  to the chatml prompt format in order to generate a response.
* bugfix: only show the progress circle when the matching chatlog is selected and shown while generating a message.
* bugfix: fixed keyboard type being set to 'number' for the 'matching characters' textfield of a lorebook.
* bugfix: show an error message instead of crashing when a model is selected for the chatlog that no longer exists
  and the user tries to generate a response.
* bugfix: fixed a crash when trying to remove models that no longer exist under the mindmeld model's folder.