@IsTest
private class ProductRateNormalizationBatchTest {

    @IsTest
    static void batch_normalizesRatesInBulk() {
        List<Product__c> products = new List<Product__c>{
            new Product__c(Name = 'TooLow', Base_Rate__c = 0.001),
            new Product__c(Name = 'TooHigh', Base_Rate__c = 0.2),
            new Product__c(Name = 'InRange', Base_Rate__c = 0.1)
        };
        insert products;

        Test.startTest();
        Database.executeBatch(new ProductRateNormalizationBatch(), 200);
        Test.stopTest();

        List<Product__c> updated = [SELECT Name, Base_Rate__c FROM Product__c WHERE Id IN :products];
        for (Product__c p : updated) {
            if (p.Name == 'TooLow') {
                System.assertEquals(ProductRateNormalizationService.LOWER_RATE, p.Base_Rate__c);
            }
            if (p.Name == 'TooHigh') {
                System.assertEquals(ProductRateNormalizationService.UPPER_RATE, p.Base_Rate__c);
            }
            if (p.Name == 'InRange') {
                System.assertEquals(0.1, p.Base_Rate__c);
            }
        }
    }
}