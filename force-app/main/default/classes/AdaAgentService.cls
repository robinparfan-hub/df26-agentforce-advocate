public with sharing class AdaAgentService {
    private static final String AGENT_ID = '0XxgK000002IVdhSAG';
    private static final String ORG_URL = 'https://orgfarm-c018aa6ce8-dev-ed.develop.my.salesforce.com';
    private static final String GATEWAY = 'https://api.salesforce.com';

    private static final String ADA_PROMPT_TEMPLATE = 'Ada_Accommodation_Chat';

    // ── Primary LWC entry point — uses GenAI Prompt Template ─────────────────

    @AuraEnabled
    public static String chat(String userMessage, String conversationHistory) {
        try {
            Map<String, ConnectApi.WrappedValue> inputMap = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue msgVal = new ConnectApi.WrappedValue();
            msgVal.value = userMessage;
            inputMap.put('Input:UserMessage', msgVal);

            ConnectApi.WrappedValue histVal = new ConnectApi.WrappedValue();
            histVal.value = String.isBlank(conversationHistory) ? '(start of conversation)' : conversationHistory;
            inputMap.put('Input:ConversationHistory', histVal);

            ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.isPreview = false;
            input.inputParams = inputMap;
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(ADA_PROMPT_TEMPLATE, input);

            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                return response.generations[0].text;
            }
            return 'I\'m here to help. Could you tell me more about what you\'re experiencing?';
        } catch (Exception e) {
            throw new AuraHandledException('Ada is temporarily unavailable: ' + e.getMessage());
        }
    }

    // ── Legacy Session API methods (kept for reference) ───────────────────────

    @AuraEnabled
    public static String createSession(String externalKey) {
        try {
            return doCreateSession(externalKey, 'callout:SalesforceAPI', null);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String sendMessage(String sessionId, String userMessage, Integer sequenceId) {
        try {
            return doSendMessage(sessionId, userMessage, sequenceId, 'callout:SalesforceAPI', null);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ── Test-friendly methods (use current session token directly) ────────────

    public static String createSessionWithToken(String externalKey, String bearerToken) {
        return doCreateSession(externalKey, GATEWAY, bearerToken);
    }

    public static String sendMessageWithToken(String sessionId, String userMessage, Integer sequenceId, String bearerToken) {
        return doSendMessage(sessionId, userMessage, sequenceId, GATEWAY, bearerToken);
    }

    // ── Full round-trip: create session → send message → return reply ─────────

    public static String invoke(String userMessage, String bearerToken) {
        String externalKey = 'anon-' + String.valueOf(System.now().getTime());
        String sessionJson = createSessionWithToken(externalKey, bearerToken);
        Map<String, Object> sessionData = (Map<String, Object>) JSON.deserializeUntyped(sessionJson);
        String sessionId = (String) sessionData.get('sessionId');
        return sendMessageWithToken(sessionId, userMessage, 1, bearerToken);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static String doCreateSession(String externalKey, String baseUrl, String bearerToken) {
        String bodyJson = JSON.serialize(new Map<String, Object>{
            'externalSessionKey' => externalKey,
            'instanceConfig'     => new Map<String, Object>{ 'endpoint' => ORG_URL },
            'streamingCapabilities' => new Map<String, Object>{ 'chunkTypes' => new List<String>{ 'Text' } },
            'bypassUser'         => true
        });
        HttpRequest req = buildRequest(
            baseUrl + '/einstein/ai-agent/v1/agents/' + AGENT_ID + '/sessions',
            'POST', bodyJson, bearerToken, 30000
        );
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) return res.getBody();
        throw new CalloutException('Session failed ' + res.getStatusCode() + ': ' + res.getBody());
    }

    private static String doSendMessage(String sessionId, String userMessage, Integer sequenceId, String baseUrl, String bearerToken) {
        String bodyJson = JSON.serialize(new Map<String, Object>{
            'message' => new Map<String, Object>{
                'sequenceId' => sequenceId,
                'type'       => 'Text',
                'text'       => userMessage
            }
        });
        HttpRequest req = buildRequest(
            baseUrl + '/einstein/ai-agent/v1/sessions/' + sessionId + '/messages',
            'POST', bodyJson, bearerToken, 60000
        );
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) return res.getBody();
        throw new CalloutException('Message failed ' + res.getStatusCode() + ': ' + res.getBody());
    }

    private static HttpRequest buildRequest(String endpoint, String method, String body, String bearerToken, Integer timeout) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        if (bearerToken != null) req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setBody(body);
        req.setTimeout(timeout);
        return req;
    }
}
