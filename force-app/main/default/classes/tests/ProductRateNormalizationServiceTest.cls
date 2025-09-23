@IsTest
private class ProductRateNormalizationServiceTest {

    @IsTest
    static void service_updatesRatesBelowLowerBound() {
        Product__c lowRate = new Product__c(Name = 'LowRate', Base_Rate__c = 0.001);
        Product__c normalRate = new Product__c(Name = 'NormalRate', Base_Rate__c = 0.05);
        insert new List<Product__c>{ lowRate, normalRate };

        Test.startTest();
        ProductRateNormalizationService.normalizeProductRates();
        Test.stopTest();

        Product__c updatedLow = [SELECT Base_Rate__c FROM Product__c WHERE Id = :lowRate.Id];
        Product__c updatedNormal = [SELECT Base_Rate__c FROM Product__c WHERE Id = :normalRate.Id];

        System.assertEquals(ProductRateNormalizationService.LOWER_RATE, updatedLow.Base_Rate__c);
        System.assertEquals(normalRate.Base_Rate__c, updatedNormal.Base_Rate__c);
    }

    @IsTest
    static void service_updatesRatesAboveUpperBound() {
        Product__c highRate = new Product__c(Name = 'HighRate', Base_Rate__c = 0.2);
        insert highRate;

        Test.startTest();
        ProductRateNormalizationService.normalizeProductRates();
        Test.stopTest();

        Product__c updatedHigh = [SELECT Base_Rate__c FROM Product__c WHERE Id = :highRate.Id];
        System.assertEquals(ProductRateNormalizationService.UPPER_RATE, updatedHigh.Base_Rate__c);
    }

    @IsTest
    static void service_handlesNoOutOfRangeRates() {
        Product__c p1 = new Product__c(Name = 'Ok1', Base_Rate__c = 0.1);
        Product__c p2 = new Product__c(Name = 'Ok2', Base_Rate__c = 0.05);
        insert new List<Product__c>{ p1, p2 };

        Test.startTest();
        ProductRateNormalizationService.normalizeProductRates();
        Test.stopTest();

        List<Product__c> results = [SELECT Base_Rate__c FROM Product__c WHERE Id IN :new List<Id>{ p1.Id, p2.Id }];
        System.assertEquals(0.1, results[0].Base_Rate__c);
        System.assertEquals(0.05, results[1].Base_Rate__c);
    }
}
