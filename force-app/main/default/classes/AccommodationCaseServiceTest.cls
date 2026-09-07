@IsTest
private class AccommodationCaseServiceTest {

    @IsTest
    static void createCase_CreatesAccommodationRecord() {
        AccommodationCaseService.CreateCaseRequest req = new AccommodationCaseService.CreateCaseRequest();
        req.employeeName = 'Jordan Rivera';
        req.jobRole = 'Software Engineer';
        req.functionalChallenge = 'Difficulty concentrating in open-plan office due to sensory sensitivity';
        req.accommodationType = 'Remote Work';
        req.generatedLetter = 'Dear HR Team, I am writing to request a remote work accommodation...';

        Test.startTest();
        List<AccommodationCaseService.CreateCaseResponse> responses =
            AccommodationCaseService.createCase(
                new List<AccommodationCaseService.CreateCaseRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Expected success but got: ' + responses[0].errorMessage);
        System.assertNotEquals(null, responses[0].caseId);
        System.assertNotEquals(null, responses[0].caseNumber);

        Case c = [
            SELECT Subject, Accommodation_Type__c, Functional_Challenge__c,
                   RecordType.DeveloperName, Plain_Language_Status__c
            FROM Case WHERE Id = :responses[0].caseId
        ];
        System.assertEquals('Accommodation Request: Jordan Rivera', c.Subject);
        System.assertEquals('Remote Work', c.Accommodation_Type__c);
        System.assertEquals('Accommodation_Request', c.RecordType.DeveloperName);
        System.assert(String.isNotBlank(c.Plain_Language_Status__c));
    }
}
