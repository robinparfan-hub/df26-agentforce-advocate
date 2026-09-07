@IsTest
private class AccommodationStatusServiceTest {

    @IsTest
    static void getStatus_ReturnsStoredPlainLanguageStatus() {
        RecordType rt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Case' AND DeveloperName = 'Accommodation_Request' LIMIT 1
        ];
        Case c = new Case(
            Subject = 'Accommodation Request: Test User',
            Status = 'Working',
            RecordTypeId = rt.Id,
            Plain_Language_Status__c = 'Your request is being reviewed by HR.'
        );
        insert c;
        c = [SELECT Id, CaseNumber, Status, Plain_Language_Status__c FROM Case WHERE Id = :c.Id];

        AccommodationStatusService.GetStatusRequest req = new AccommodationStatusService.GetStatusRequest();
        req.caseId = c.Id;

        Test.startTest();
        List<AccommodationStatusService.GetStatusResponse> responses =
            AccommodationStatusService.getStatus(
                new List<AccommodationStatusService.GetStatusRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success);
        System.assertEquals('Working', responses[0].salesforceStatus);
        System.assertEquals('Your request is being reviewed by HR.', responses[0].plainLanguageStatus);
        System.assertEquals(c.CaseNumber, responses[0].caseNumber);
    }

    @IsTest
    static void getStatus_TranslatesStatusWhenPlainLanguageBlank() {
        RecordType rt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Case' AND DeveloperName = 'Accommodation_Request' LIMIT 1
        ];
        Case c = new Case(
            Subject = 'Accommodation Request: Test User',
            Status = 'Escalated',
            RecordTypeId = rt.Id
        );
        insert c;

        AccommodationStatusService.GetStatusRequest req = new AccommodationStatusService.GetStatusRequest();
        req.caseId = c.Id;

        Test.startTest();
        List<AccommodationStatusService.GetStatusResponse> responses =
            AccommodationStatusService.getStatus(
                new List<AccommodationStatusService.GetStatusRequest>{ req }
            );
        Test.stopTest();

        System.assert(responses[0].success);
        System.assert(String.isNotBlank(responses[0].plainLanguageStatus));
        System.assertNotEquals('Escalated', responses[0].plainLanguageStatus,
            'Should return human-readable text, not the raw status code');
    }
}
