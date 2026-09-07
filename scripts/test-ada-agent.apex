// Anonymous Apex — invoke Ada agent end-to-end
// Run: sf apex run --file scripts/test-ada-agent.apex --target-org <alias>

String token = UserInfo.getSessionId();
String question = 'What accommodation types are available for employees with mobility impairments?';

System.debug('=== Ada Agent Test ===');
System.debug('Running as: ' + UserInfo.getUserName());
System.debug('Question: ' + question);

try {
    String reply = AdaAgentService.invoke(question, token);
    System.debug('=== RAW RESPONSE ===');
    System.debug(reply);

    // Pretty-print the agent reply text if present
    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(reply);
    List<Object> messages = (List<Object>) data.get('messages');
    if (messages != null && !messages.isEmpty()) {
        for (Object m : messages) {
            Map<String, Object> msg = (Map<String, Object>) m;
            if ('Text'.equals(msg.get('type'))) {
                System.debug('=== Ada says ===');
                System.debug((String) msg.get('text'));
            }
        }
    }
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
