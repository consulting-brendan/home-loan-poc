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

        System.assertEquals(ProductRateNormalizationService.LOWER_RATE, updatedLow.Base_Rate__c,
            'Low rate should be normalized to lower bound');
        System.assertEquals(normalRate.Base_Rate__c, updatedNormal.Base_Rate__c,
            'Normal rate should remain unchanged');
    }

    @IsTest
    static void service_updatesRatesAboveUpperBound() {
        Product__c highRate = new Product__c(Name = 'HighRate', Base_Rate__c = 0.2);
        insert highRate;

        Test.startTest();
        ProductRateNormalizationService.normalizeProductRates();
        Test.stopTest();

        Product__c updatedHigh = [SELECT Base_Rate__c FROM Product__c WHERE Id = :highRate.Id];
        System.assertEquals(ProductRateNormalizationService.UPPER_RATE, updatedHigh.Base_Rate__c,
            'High rate should be normalized to upper bound');
    }

    @IsTest
    static void service_handlesNoOutOfRangeRates() {
        Product__c p1 = new Product__c(Name = 'Ok1', Base_Rate__c = 0.1);
        Product__c p2 = new Product__c(Name = 'Ok2', Base_Rate__c = 0.05);
        insert new List<Product__c>{ p1, p2 };

        Test.startTest();
        ProductRateNormalizationService.normalizeProductRates();
        Test.stopTest();

        List<Product__c> results = [SELECT Name, Base_Rate__c FROM Product__c WHERE Id IN :new List<Id>{ p1.Id, p2.Id }];
        Map<String, Decimal> rates = new Map<String, Decimal>();
        for (Product__c prod : results) {
            rates.put(prod.Name, prod.Base_Rate__c);
        }

        System.assertEquals(0.1, rates.get('Ok1'), 'In-range product should not change');
        System.assertEquals(0.05, rates.get('Ok2'), 'In-range product should not change');
    }

    @IsTest
    static void service_handlesEmptyProductList() {
        Test.startTest();
        ProductRateNormalizationService.normalizeProductRates();
        Test.stopTest();
        // Just making sure it doesn’t throw an exception
        System.assertEquals(0, [SELECT COUNT() FROM Product__c],
            'No products should exist in this test');
    }

    @IsTest
    static void service_normalizesMixedRates() {
        Product__c lowRate = new Product__c(Name = 'TooLow', Base_Rate__c = 0.001);
        Product__c highRate = new Product__c(Name = 'TooHigh', Base_Rate__c = 0.20);
        insert new List<Product__c>{ lowRate, highRate };

        Test.startTest();
        ProductRateNormalizationService.normalizeProductRates();
        Test.stopTest();

        Map<String, Decimal> updatedRates = new Map<String, Decimal>();
        for (Product__c p : [
            SELECT Name, Base_Rate__c FROM Product__c WHERE Id IN :new List<Id>{ lowRate.Id, highRate.Id }
        ]) {
            updatedRates.put(p.Name, p.Base_Rate__c);
        }

        System.assertEquals(ProductRateNormalizationService.LOWER_RATE, updatedRates.get('TooLow'),
            'Too low rate should be corrected');
        System.assertEquals(ProductRateNormalizationService.UPPER_RATE, updatedRates.get('TooHigh'),
            'Too high rate should be corrected');
    }
}
