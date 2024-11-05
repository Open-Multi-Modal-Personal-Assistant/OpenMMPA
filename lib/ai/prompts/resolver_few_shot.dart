import 'package:inspector_gadget/ai/prompts/closing_parts.dart';

const resolverSystemInstruction =
    'You are a conversation specialist helping isolating a conversation '
    'piece from a chat history by resolving all references '
    'and removing all possible ambiguity.';
const resolverFewShotVariable = '{{INPUT}}';
const resolverFewShotTemplate = """
Resolve any contextual references and remove any ambiguity from the last user request so it would be perfectly clear and it would able to stand alone as a request without the rest of the interaction. You'll receive the interaction as a context, $outputFormattingLower
<examples>
<example>
<interaction>
user: When was the first world war?
model: The first world war began on July 28, 1914 and ended on November 11, 1918.
user: How many countries participated in it?
model: 30 countries participated in World War I
user: Which was the largest country of those?
model: The largest country that participated in World War I was the Russian Empire, with a population of approximately 170 million people at the time.
user: Where is the capital of that and how many its soldiers fallen?
</interaction>
<response>What is the capital of the Russian Empire? How many Russian soldiers fell in World War I?</response>
</example>

<example>
<interaction>
user: When was the second world war?
model: September 1, 1939 - September 2, 1945
user: Who was the main attacker country?
model: Germany was the main attacker country in World War II.
user: Who was the leader of that?
model: The leader of Nazi Germany during World War II was Adolf Hitler.
user: How many allies did it have?
</interaction>
<response>How many ally countries did Germany had during World War II?</response>
</example>

<example>
<interaction>
user: How many members does the band Aerosmith have?
model: 5
user: Who is the oldest?
model: Joey Kramer
user: Which is their most popular song?
model: Dream On
user: What accolades does it have?
</interaction>
<response>What accolades does the song Dream On of the band Aerosmith has?</response>
</example>

<example>
<interaction>
user: How many plays Shakespeare wrote throughout his lifetime?
model: 39
user: Which one is the most famous?
model: Hamlet
user: Where does it take place?
model: Denmark?
user: What's the population of that?
</interaction>
<response>What is the population of Denmark?</response>
</example>
</examples>

Current interaction:
<interaction>
$resolverFewShotVariable
</interaction>
<response>""";
