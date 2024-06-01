enum ModelPromptStyle { alpaca, vicuna, chatML, llama3 }

extension ModelPromptStyleExtension on ModelPromptStyle {
  String nameAsString() => name;
}

ModelPromptStyle modelPromptStyleFromString(String stringValue) {
  return ModelPromptStyle.values
      .firstWhere((style) => style.nameAsString() == stringValue);
}

class ChatLog {
  String name;
  String modelFilepath;
  ModelPromptStyle modelPromptStyle;
  List<ChatLogMessage> messages = [];

  ChatLog(this.name, this.modelFilepath, this.modelPromptStyle);
}

class ChatLogMessage {
  String senderName;
  String message;

  ChatLogMessage(this.senderName, this.message);
}
