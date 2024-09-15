# MindMeld (Alpha Release)

A simple-to-use, open source GUI for local AI chat.

Supported platforms: iOS, Android (un-accelerated), MacOS, Linux

In-Development platforms: Windows

![Example of Mindmeld in action - chatting with the default character, Vox](docs/images/demo_240913A.png)

## Features

* Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) and supports any model supported by that project in GGUF form.
* Graphical user interface, tailored towards chatting with AI, which is mobile compatible.
* Create multiple chat logs, each with their own parameters, story context and characters
* Customizable character portrait images.
* Automatic model downloading from HuggingFace.
* Built-in 'narrator' using the slash-command '/narrator' at the start of a message.
* Lorebook support: customizable lists of 'lore' text that gets added behind the scenes
  to the LLM prompt when a pattern is matched in the chat log context or recent messages.
  Lorebooks are active across all chats and are enabled if a character name from the chat
  log pattern matches.
* Fast regeneration of AI chat replies with prompt caching.


## Instructions

See the documentation for the [quick start guide](docs/first_run.md).


## Building From Source

See the documentation for the [build instructions](docs/build.md) for all supported platforms.


## License

This project is licensed under the GPL v3 terms, as specified in the `LICENSE` file.

The project is built around [woolycore](https://github.com/tbogdala/woolycore), 
[woolydart](https://github.com/tbogdala/woolydart) for the language bindings and of course the 
great [llama.cpp](https://github.com/ggerganov/llama.cpp) library. All three of these libraries
are licensed under the MIT license.