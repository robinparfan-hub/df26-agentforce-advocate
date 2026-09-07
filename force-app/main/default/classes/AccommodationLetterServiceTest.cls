@IsTest
private class AccommodationLetterServiceTest {

    @IsTest
    static void generateLetter_SuccessPath_ReturnsNonEmptyLetter() {
        AccommodationLetterService.GenerateLetterRequest req = new AccommodationLetterService.GenerateLetterRequest();
        req.employeeName = 'Jordan Rivera';
        req.jobRole = 'Software Engineer';
        req.functionalChallenge = 'Difficulty concentrating due to sensory sensitivity to noise in open-plan office';
        req.accommodationType = 'Remote Work';
        req.managerName = 'Alex Chen';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockEinsteinSuccess());
        List<AccommodationLetterService.GenerateLetterResponse> responses =
            AccommodationLetterService.generateLetter(
                new List<AccommodationLetterService.GenerateLetterRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Expected success');
        System.assert(String.isNotBlank(responses[0].generatedLetter));
        System.assert(responses[0].generatedLetter.contains('Jordan Rivera'));
    }

    @IsTest
    static void generateLetter_LLMFailure_ReturnsFallbackLetter() {
        AccommodationLetterService.GenerateLetterRequest req = new AccommodationLetterService.GenerateLetterRequest();
        req.employeeName = 'Jordan Rivera';
        req.jobRole = 'Software Engineer';
        req.functionalChallenge = 'Needs a quieter workspace';
        req.accommodationType = 'Modified Workspace';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockEinsteinFailure());
        List<AccommodationLetterService.GenerateLetterResponse> responses =
            AccommodationLetterService.generateLetter(
                new List<AccommodationLetterService.GenerateLetterRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Fallback should still report success');
        System.assert(String.isNotBlank(responses[0].generatedLetter));
        System.assert(responses[0].generatedLetter.contains('Jordan Rivera'));
        System.assert(responses[0].generatedLetter.contains('Modified Workspace'));
    }

    private class MockEinsteinSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"generations":[{"text":"Dear Alex Chen and HR Team,\\n\\nI am writing to formally request a workplace accommodation. My name is Jordan Rivera and I work as a Software Engineer.\\n\\nDue to sensory sensitivity to noise in our open-plan office, I experience significant difficulty maintaining the focus required to do my best work. I am requesting the ability to work remotely.\\n\\nI am committed to full productivity and availability. I welcome the interactive process.\\n\\nSincerely,\\nJordan Rivera"}]}');
            return res;
        }
    }

    private class MockEinsteinFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Service unavailable"}');
            return res;
        }
    }
}
