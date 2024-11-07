# Application Configuration File

The application configuration file is named `mindmeld.json` and it will be located in the application's folder. If it doesn't exist when the application is run (for instance, when running for the first time), then it will be created.

The application's folder varies depending on the platform. For mobile operating systems, it will be in the specific data storage folder of the application. For MacOS, it will be under `$HOME/Documents/Mindmeld`.

## Overrides

Within the application configuration, it's possible to set a number of 'overrides' for default values used in the application. *All overrides are 'strings' in the JSON file - they will be converted to other types as needed in the application.*

For example, if the `mindmeld.json` file contains an `"options"` field like the following, it will override the maximum allowable percentage of lorebook information that can take up in the prompt:

```json
"options": {
    "max_lore_pct" : "0.2"
}
```

The following sub-sections document all the possible overrides that can be set in the configuration file.


### max_lore_pct

Lorebook information can quickly overwhelm smaller context windows, and this setting determines the maximum percentage those entries can take up as a whole.

Application default: 0.1 (10%)


### prompt_ai_desc

Each AI character gets added to the prompt, and this option controls the formatting of this character's fragment.

The string should include "{{ai_name}}" and "{{ai_desc}}", which will be replaced with the AI character's name and description, respectively. Additionally, "{{ai_personality_frag}}" can be specified to control where the AI's personality description fragment (see also: `prompt_ai_pers`) gets added. If the AI character has an empty personality field, then "{{ai_personality_frag}}" will be replaced with an empty string.

Application default: `### {{ai_name}}\n\n{{ai_desc}}\n{{ai_personality_frag}}`


### prompt_ai_pers

Each AI character gets added to the prompt, and this option controls the formatting of the additional personality fragment.

The string should include "{{ai_name}}" and "{{ai_personality}}", which will be replaced with the AI character's name and personality, respectively.

Application default: `\n{{ai_name}}\'s Personality Traits: {{ai_personality}}\n`


### prompt_characters

This option allows for overriding how the character section is presented in the prompt.

The string should include "{{user_desc}}" and "{{ai_desc}}" which are the fragments for the user and all of the AI characters, respectively. (see also: `prompt_user_desc`, `prompt_ai_desc`, `prompt_ai_pers`)

Application default: `## Characters:\n\n{{user_desc}}\n{{ai_desc}}`


### prompt_chat

This option describes how the overall prompt gets formatted for a normal chat response.

This string should include the following placeholders:
    * "{{system}}" will be replaced with the formatted system prompt (see also: `prompt_system`)
    * "{{story_context}}" will be replaced with the formatted context from the chat log (see also: `prompt_context`)
    * "{{characters}}" will be replaced with the formatted aggregation of the user and AI character descriptions (see also: `prompt_characters`)
    * "{{lorebook}}" will be replaced with the formatted lorebook section and its entries if there are any (see also: `prompt_lorebook`)

Application default: `{{system}}{{story_context}}{{characters}}\n{{lorebook}}`


### prompt_context

This prompt fragment defines how the story context should be formatted when added to the prompt.

The string should include "{{context}}", which will be replaced with the context field from the chatlog.

Application default: `\## Overall Plot Description:\n\n{{context}}\n\n`


### prompt_lorebook

This prompt fragment defines how the lorebook should be formatted as a whole inside the prompt.

The string should include "{{lorebook}}", which will be replaced with the string contents of all the formatted lorebook entries. (See also: `prompt_lorebook_entry`)

Application default: `## Relevant Lore:\n\n{{lorebook}}`


### prompt_lorebook_entry

Each lorebook entry that gets matched and doesn't exceed the allowable percentage of context the lorebook is allowed to take up. (See also: `max_lore_pct`)

The string should include "{{entry_lore}}", which will be replaced with the string contents of the lorebook entry.

Application default: `{{entry_lore}}\n\n`


### prompt_narrator

This option describes how the overall prompt gets formatted for special type of response when last message starts off with '/narrator'.

This string should include the following placeholders:
    * "{{system}}" will be replaced with the formatted system prompt (see also: `prompt_narrator_system`)
    * "{{story_context}}" will be replaced with the formatted context from the chat log (see also: `prompt_context`)
    * "{{characters}}" will be replaced with the formatted aggregation of the user and AI character descriptions (see also: `prompt_characters`)
    * "{{lorebook}}" will be replaced with the formatted lorebook section and its entries if there are any (see also: `prompt_lorebook`)
    * "{{narrator_request}}" will be replaced with the rest of the message after '/narrator ' and the convention is to write like you wish for the narrator to perform an action (see also: `prompt_narrator_system`)
    * "{{narrator_desc}}" will be replaced with the description of the Narrator character. (see also: `prompt_narrator_desc`)

Application default: `{{system}}\nThe user has requested that you {{narrator_request}}\n{{story_context}}{{characters}}\n### Narrator\n\n{{narrator_desc}}\n\n{{lorebook}}`


### prompt_narrator_desc

When the user starts a chat message with '/narrator', the special narrator prompt gets made. This option provides a way to override the default description of the narrator.

Application default:
```
The Narrator is an enigmatic, omniscient entity that guides the story. Unseen yet ever-present, the Narrator shapes the narrative, describes the world, and gives voice to NPCs. When invoked with the '/narrator' command, the Narrator will focus on the requested task. Otherwise, the Narrator will:

- Provide vivid, sensory descriptions of environments
- Introduce and describe characters
- Narrate events and actions
- Provide dialogue for NPCs
- Create atmosphere and mood through descriptive language
- Offer subtle hints or clues to guide the story
- Respond to player actions with appropriate narrative consequences

The Narrator should maintain a neutral tone, avoiding direct interaction with players unless specifically addressed. The goal is to create an immersive, dynamic story world that reacts to player choices while maintaining narrative coherence.
```


### prompt_narrator_system

When the user starts a chat message with '/narrator', the special narrator prompt gets made. This option provides a way to override the default system message for this style of response being generated.

Application default: `You are an omniscient, creative narrator for an interactive story. Your task is to vividly describe environments, characters, and events, as well as provide dialogue and actions for non-player characters (NPCs) when appropriate.`


### prompt_user_desc

The human user has a description under the characters section, just like the other AI characters in the chatlog. Overriding this option changes how this is formatted in the prompt.

The string should include "{{user_name}}" and "{{user_desc}}", which will be replaced with the user's name and description, respectively.

Application default: `### {{user_name}}\n\n{{user_desc}}\n`


### prompt_system

The default system prompt outlines basic instructions for how to write a roleplaying scenario involving a human user and an AI character. When overridden, the value of this setting will be used at the very start of the prompt being sent to the AI (the system message portion).

Application default is approximately 225 tokens long (1148 characters):
`You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the information below.Maintain the character persona but allow it to evolve with the story.\nBe creative and proactive. Drive the story forward, introducing plot lines and events when relevant.\nAll types of outputs are encouraged; respond accordingly to the narrative.\nInclude dialogues, actions, and thoughts in each response.\nUtilize all five senses to describe scenarios within the character's dialogue.\nUse emotional symbols such as \"!\" and \"~\" in appropriate contexts.\nIncorporate onomatopoeia when suitable.\nAllow time for other characters to respond with their own input, respecting their agency.\n\n<Forbidden>\nUsing excessive literary embellishments and purple prose unless dictated by Character's persona.\nWriting for, speaking, thinking, acting, or replying as a different in your response.\nRepetitive and monotonous outputs.\nPositivity bias in your replies.\nBeing overly extreme or NSFW when the narrative context is inappropriate.\n</Forbidden>\n\nFollow the instructions above, avoiding the items listed in <Forbidden></Forbidden>.\n`