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


### chars_per_token

When doing estimates for how much text to include for a given token budget, it will use this configured double as the number of characters, on average, per token. Increasing this number will estimate text to take up less space and if it seems like the prompt might be overflowing, try decreasing this number.

Application default: 3.75


### max_lore_pct

Lorebook information can quickly overwhelm smaller context windows, and this setting determines the maximum percentage those entries can take up as a whole.

Application default: 0.1 (10%)


### prompt_narrator_system

When the user starts a chat message with '/narrator', the special narrator prompt gets made. This option provides a way to override the default system prompt with extra directors for the narrator instead.

Application default:
```
You are an omniscient, creative Narrator for an interactive story. Your task is to vividly describe environments, characters, and events, as well as provide dialogue and actions for non-player characters (NPCs) when appropriate.

The Narrator is an enigmatic, omniscient entity that guides the story. Unseen yet ever-present, the Narrator shapes the narrative, describes the world, and gives voice to NPCs. When invoked by the user, the Narrator will focus on the requested task. Otherwise, the Narrator will:

- Provide vivid, sensory descriptions of environments
- Introduce and describe characters
- Narrate events and actions
- Provide dialogue for NPCs
- Create atmosphere and mood through descriptive language
- Offer subtle hints or clues to guide the story
- Respond to player actions with appropriate narrative consequences

The Narrator's goal is to create an immersive, dynamic story world that reacts to player choices while maintaining narrative coherence.
```


### prompt_system

The default system prompt outlines basic instructions for how to write a roleplaying scenario involving a human user and an AI character. When overridden, the value of this setting will be used at the very start of the prompt being sent to the AI (the system message portion).

Application default is approximately 225 tokens long (1148 characters):
`You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the information below.Maintain the character persona but allow it to evolve with the story.\nBe creative and proactive. Drive the story forward, introducing plot lines and events when relevant.\nAll types of outputs are encouraged; respond accordingly to the narrative.\nInclude dialogues, actions, and thoughts in each response.\nUtilize all five senses to describe scenarios within the character's dialogue.\nUse emotional symbols such as \"!\" and \"~\" in appropriate contexts.\nIncorporate onomatopoeia when suitable.\nAllow time for other characters to respond with their own input, respecting their agency.\n\n<Forbidden>\nUsing excessive literary embellishments and purple prose unless dictated by Character's persona.\nWriting for, speaking, thinking, acting, or replying as a different in your response.\nRepetitive and monotonous outputs.\nPositivity bias in your replies.\nBeing overly extreme or NSFW when the narrative context is inappropriate.\n</Forbidden>\n\nFollow the instructions above, avoiding the items listed in <Forbidden></Forbidden>.\n`


### prompt_system_format

The default prompt system format lays out the system message with the prompt_system configured string, the chatlog's context, then characters and lore following that.

Application default:
```{{ system }}

## Overall Plot Description:

{{ context }}

## Characters:

{% for ch in characters %}
### {{ ch.name }}:

{{ ch.description }}

{{ ch.name }}'s Personality Traits: {{ ch.personality }}

{% endfor %}
## Relevant Lore:

{% for item in lorebook %}
{{ item.lore }}

{% endfor %}
```