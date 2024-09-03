const historyRagStuffingVariable = '{{HISTORY}}';
const historyRagStuffingTemplate = '''
The following earlier historical conversation pieces may or may not be beneficial to answer the question:
<relatedHistory>
$historyRagStuffingVariable
</relatedHistory>
''';
