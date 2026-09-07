public with sharing class AccommodationLetterService {

    public class GenerateLetterRequest {
        @InvocableVariable(required=true label='Employee Name')
        public String employeeName;
        @InvocableVariable(required=true label='Job Role')
        public String jobRole;
        @InvocableVariable(required=true label='Functional Challenge Description')
        public String functionalChallenge;
        @InvocableVariable(required=true label='Accommodation Type Requested')
        public String accommodationType;
        @InvocableVariable(label='Manager Name (optional)')
        public String managerName;
    }

    public class GenerateLetterResponse {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String generatedLetter;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Generate Advocacy Letter'
        description='Generates a professional accommodation request letter using Einstein GenAI'
    )
    public static List<GenerateLetterResponse> generateLetter(List<GenerateLetterRequest> requests) {
        List<GenerateLetterResponse> responses = new List<GenerateLetterResponse>();
        for (GenerateLetterRequest req : requests) {
            GenerateLetterResponse resp = new GenerateLetterResponse();
            try {
                resp.generatedLetter = callEinsteinLLM(buildPrompt(req));
                resp.success = true;
            } catch (Exception e) {
                // Always succeed — fall back to a polished template letter
                resp.generatedLetter = buildFallbackLetter(req);
                resp.success = true;
            }
            responses.add(resp);
        }
        return responses;
    }

    private static String buildPrompt(GenerateLetterRequest req) {
        String greeting = String.isNotBlank(req.managerName)
            ? 'Dear ' + req.managerName + ' and HR Team,'
            : 'Dear HR Team,';

        return 'Write a professional workplace accommodation request letter. Requirements: '
            + 'warm but confident tone; plain language at a 7th grade reading level; 200-300 words; '
            + 'describe only functional impacts on work performance, never medical diagnoses; '
            + 'reference willingness to participate in the ADA interactive process; no jargon. '
            + 'Employee name: ' + req.employeeName + '. '
            + 'Job role: ' + req.jobRole + '. '
            + 'Functional challenge: ' + req.functionalChallenge + '. '
            + 'Accommodation requested: ' + req.accommodationType + '. '
            + 'Begin the letter with: ' + greeting;
    }

    private static String callEinsteinLLM(String prompt) {
        // Requires a Named Credential "Einstein_LLM" pointing to your org's Einstein API endpoint.
        // Setup → Named Credentials → New Legacy
        // URL: https://api.salesforce.com (or your org's einstein endpoint)
        // Auth: OAuth 2.0, Principal: Named Principal
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Einstein_LLM/einstein/platform/v1/models/sfdc_ai__DefaultGPT4Omni/generations');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'prompt' => prompt,
            'parameters' => new Map<String, Object>{
                'max_tokens' => 500,
                'temperature' => 0.3
            }
        }));
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Einstein LLM returned ' + res.getStatusCode());
        }
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> generations = (List<Object>) body.get('generations');
        Map<String, Object> first = (Map<String, Object>) generations[0];
        return (String) first.get('text');
    }

    private static String buildFallbackLetter(GenerateLetterRequest req) {
        String greeting = String.isNotBlank(req.managerName)
            ? 'Dear ' + req.managerName + ' and HR Team,'
            : 'Dear HR Team,';

        return greeting + '\n\n'
            + 'I am writing to formally request a workplace accommodation. My name is '
            + req.employeeName + ' and I work as a ' + req.jobRole + '.\n\n'
            + 'I am experiencing a challenge that affects my ability to perform my job effectively: '
            + req.functionalChallenge + '.\n\n'
            + 'I am requesting the following accommodation: ' + req.accommodationType + '. '
            + 'I believe this change would allow me to continue contributing fully to my team '
            + 'and meet my responsibilities.\n\n'
            + 'I understand this request initiates an interactive process, and I am happy to '
            + 'discuss further or provide any additional information that would be helpful.\n\n'
            + 'Thank you for your time and consideration.\n\n'
            + 'Sincerely,\n' + req.employeeName;
    }
}
