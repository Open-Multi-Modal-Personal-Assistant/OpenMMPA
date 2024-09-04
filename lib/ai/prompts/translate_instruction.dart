const translateTaskInstruction = 'Your current task is language translation. '
    'You will be given the input to be translated and '
    'the target language locale. '
    "Stay on point and don't add any explanation or extra. Examples:";

const translationSubjectVariable = '{{SUBJECT}}';
const translationTargetLocaleVariable = '{{LOCALE}}';
const translationExamples = '''
<examples>
<example>
<request>
<user>Milyen lesz az idő ezen a héten?</user>
<targetLocale>en-US</targetLocale>
</request>
<response>What will the weather be like this week?</response>
</example>

<example>
<request>
<user>What will the weather be like this week?</user>
<targetLocale>hu-HU</targetLocale>
</request>
<response>Milyen lesz az idő ezen a héten?</response>
</example>

<example>
<request>
<user>Compré entradas de cine para la función de las cuatro y media en el Cine Maya.</user>
<targetLocale>en-US</targetLocale>
</request>
<response>I bought movie tickets for the half past four showing at the Maya Cinemas.</response>
</example>

<example>
<request>
<user>Compré entradas de cine para la función de las cuatro y media en el Cine Maya.</user>
<targetLocale>es-MX</targetLocale>
</request>
<response>I bought movie tickets for the half past four showing at the Maya Cinemas.</response>
</example>
</examples>
''';

const translateOutputInstruction = '''
Actual case:
<request>
<user>$translationSubjectVariable</user>
<targetLocale>$translationTargetLocaleVariable</targetLocale>
</request>
<response>
''';

const translateInstruction = '''
$translateTaskInstruction
$translationExamples
$translateOutputInstruction
''';
