@IsTest
private class ProductsSelectorTest {

    @IsTest
    static void selectAllOrderByRateAscReturnsInsertedProductsInCorrectOrder() {
        Product__c highRate = new Product__c(
            Name = 'HighRate',
            Min_Credit_Score__c = 700,
            Base_Rate__c = 10
        );
        Product__c lowRate = new Product__c(
            Name = 'LowRate',
            Min_Credit_Score__c = 600,
            Base_Rate__c = 5
        );
        insert new List<Product__c>{ highRate, lowRate };

        List<Product__c> selected = new ProductsSelector().selectAllOrderByRateAsc();

        System.assertEquals(2, selected.size(), 'Should return both products');
        System.assertEquals(5, selected[0].Base_Rate__c,
            'Lowest rate product should come first');
        System.assertEquals(10, selected[1].Base_Rate__c,
            'Highest rate product should come second');
    }

    @IsTest
    static void selectForRateNormalizationReturnsOutOfRange() {
        Product__c tooLow  = new Product__c(Name = 'TooLow',  Base_Rate__c = 0.001);
        Product__c tooHigh = new Product__c(Name = 'TooHigh', Base_Rate__c = 0.20);
        Product__c inRange = new Product__c(Name = 'InRange', Base_Rate__c = 0.10);
        insert new List<Product__c>{ tooLow, tooHigh, inRange };

        List<Product__c> selected = new ProductsSelector().selectForRateNormalization();

        Set<String> selectedNames = new Set<String>();
        for (Product__c p : selected) {
            selectedNames.add(p.Name);
        }

        System.assert(selectedNames.contains('TooLow'), 'Should include product below range');
        System.assert(selectedNames.contains('TooHigh'), 'Should include product above range');
        System.assert(!selectedNames.contains('InRange'), 'Should exclude product within range');
    }
}
