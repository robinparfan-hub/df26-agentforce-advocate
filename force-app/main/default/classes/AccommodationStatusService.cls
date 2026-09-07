public with sharing class AccommodationStatusService {

    public class GetStatusRequest {
        @InvocableVariable(required=true label='Case Id')
        public Id caseId;
    }

    public class GetStatusResponse {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String caseNumber;
        @InvocableVariable public String salesforceStatus;
        @InvocableVariable public String plainLanguageStatus;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Get Accommodation Case Status'
        description='Returns the current status of an accommodation request in plain language'
    )
    public static List<GetStatusResponse> getStatus(List<GetStatusRequest> requests) {
        List<GetStatusResponse> responses = new List<GetStatusResponse>();
        for (GetStatusRequest req : requests) {
            GetStatusResponse resp = new GetStatusResponse();
            try {
                Case c = [
                    SELECT Id, CaseNumber, Status, Plain_Language_Status__c
                    FROM Case WHERE Id = :req.caseId LIMIT 1
                ];
                resp.success = true;
                resp.caseNumber = c.CaseNumber;
                resp.salesforceStatus = c.Status;
                resp.plainLanguageStatus = String.isNotBlank(c.Plain_Language_Status__c)
                    ? c.Plain_Language_Status__c
                    : translateStatus(c.Status);
            } catch (Exception e) {
                resp.success = false;
                resp.errorMessage = e.getMessage();
            }
            responses.add(resp);
        }
        return responses;
    }

    private static String translateStatus(String status) {
        Map<String, String> translations = new Map<String, String>{
            'New'       => 'Your request has been received and is waiting to be assigned.',
            'Working'   => 'Good news — your request is being actively reviewed by HR.',
            'Escalated' => 'Your request has been escalated to a senior HR partner. You\'ll hear back within 2 business days.',
            'Closed'    => 'Your request has been resolved. Please check your email for details on your approved accommodations.'
        };
        return translations.containsKey(status)
            ? translations.get(status)
            : 'Your request status is: ' + status + '. Contact HR if you have questions.';
    }
}
