public with sharing class AccommodationCaseService {

    public class CreateCaseRequest {
        @InvocableVariable(required=true label='Employee Name')
        public String employeeName;
        @InvocableVariable(required=true label='Job Role')
        public String jobRole;
        @InvocableVariable(required=true label='Functional Challenge')
        public String functionalChallenge;
        @InvocableVariable(required=true label='Accommodation Type')
        public String accommodationType;
        @InvocableVariable(required=true label='Generated Advocacy Letter')
        public String generatedLetter;
    }

    public class CreateCaseResponse {
        @InvocableVariable public Boolean success;
        @InvocableVariable public Id caseId;
        @InvocableVariable public String caseNumber;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(
        label='Create Accommodation Case'
        description='Creates a formal accommodation request case in Salesforce'
    )
    public static List<CreateCaseResponse> createCase(List<CreateCaseRequest> requests) {
        List<CreateCaseResponse> responses = new List<CreateCaseResponse>();
        for (CreateCaseRequest req : requests) {
            CreateCaseResponse resp = new CreateCaseResponse();
            try {
                RecordType rt = [
                    SELECT Id FROM RecordType
                    WHERE SObjectType = 'Case' AND DeveloperName = 'Accommodation_Request'
                    LIMIT 1
                ];
                Case c = new Case(
                    Subject = 'Accommodation Request: ' + req.employeeName,
                    Description = req.functionalChallenge,
                    Accommodation_Type__c = req.accommodationType,
                    Functional_Challenge__c = req.functionalChallenge,
                    Generated_Letter__c = req.generatedLetter,
                    Status = 'New',
                    Origin = 'Web',
                    RecordTypeId = rt.Id,
                    Plain_Language_Status__c = 'Your request has been received. HR will confirm within 1 business day.'
                );
                insert c;
                Case inserted = [SELECT Id, CaseNumber FROM Case WHERE Id = :c.Id];
                resp.success = true;
                resp.caseId = inserted.Id;
                resp.caseNumber = inserted.CaseNumber;
            } catch (Exception e) {
                resp.success = false;
                resp.errorMessage = e.getMessage();
            }
            responses.add(resp);
        }
        return responses;
    }
}
