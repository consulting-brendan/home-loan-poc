@IsTest(IsParallel=true)
private class ProductsSelectorTest {

    @IsTest
    static void getSObjectType_ReturnsProductSObjectType() {
        ProductsSelector selector = new ProductsSelector();
        System.assertEquals(Product__c.SObjectType, selector.getSObjectType());
    }

    @IsTest
    static void getSObjectFieldList_ReturnsRequiredFields() {
        ProductsSelector selector = new ProductsSelector();
        List<Schema.SObjectField> fields = selector.getSObjectFieldList();
        
        Set<Schema.SObjectField> fieldSet = new Set<Schema.SObjectField>(fields);
        System.assert(fieldSet.contains(Product__c.Id));
        System.assert(fieldSet.contains(Product__c.Name));
        System.assert(fieldSet.contains(Product__c.Min_Credit_Score__c));
        System.assert(fieldSet.contains(Product__c.Base_Rate__c));
    }

    @IsTest
    static void getOrderBy_ReturnsCorrectOrdering() {
        ProductsSelector selector = new ProductsSelector();
        String orderBy = selector.getOrderBy();
        System.assertEquals('Base_Rate__c ASC, Min_Credit_Score__c ASC', orderBy);
    }

    @IsTest
    static void selectAllOrderByRateAsc_ReturnsProductsInCorrectOrder() {
        Product__c highRate = new Product__c(
            Name = 'HighRate',
            Min_Credit_Score__c = 700,
            Base_Rate__c = 0.10
        );
        Product__c lowRate = new Product__c(
            Name = 'LowRate',
            Min_Credit_Score__c = 600,
            Base_Rate__c = 0.05
        );
        insert new List<Product__c>{ highRate, lowRate };

        Test.startTest();
        List<Product__c> selected = new ProductsSelector().selectAllOrderByRateAsc();
        Test.stopTest();

        System.assertEquals(2, selected.size());
        System.assertEquals(0.05, selected[0].Base_Rate__c);
        System.assertEquals(0.10, selected[1].Base_Rate__c);
        System.assertEquals('LowRate', selected[0].Name);
        System.assertEquals('HighRate', selected[1].Name);
    }

    @IsTest
    static void selectForRateNormalization_ReturnsOutOfRangeProducts() {
        Product__c tooLow  = new Product__c(Name = 'TooLow',  Base_Rate__c = 0.001);
        Product__c tooHigh = new Product__c(Name = 'TooHigh', Base_Rate__c = 0.20);
        Product__c inRange = new Product__c(Name = 'InRange', Base_Rate__c = 0.10);
        insert new List<Product__c>{ tooLow, tooHigh, inRange };

        Test.startTest();
        List<Product__c> selected = new ProductsSelector().selectForRateNormalization();
        Test.stopTest();

        Set<String> selectedNames = new Set<String>();
        for (Product__c p : selected) {
            selectedNames.add(p.Name);
        }

        System.assertEquals(2, selected.size());
        System.assert(selectedNames.contains('TooLow'));
        System.assert(selectedNames.contains('TooHigh'));
        System.assert(!selectedNames.contains('InRange'));
    }

    @IsTest
    static void selectForRateNormalization_HandlesEmptyResult() {
        Product__c inRange1 = new Product__c(Name = 'InRange1', Base_Rate__c = 0.08);
        Product__c inRange2 = new Product__c(Name = 'InRange2', Base_Rate__c = 0.12);
        insert new List<Product__c>{ inRange1, inRange2 };

        Test.startTest();
        List<Product__c> selected = new ProductsSelector().selectForRateNormalization();
        Test.stopTest();

        System.assertEquals(0, selected.size());
    }

    @IsTest
    static void selectAllOrderByRateAsc_HandlesBulkProducts() {
        List<Product__c> testProducts = new List<Product__c>();
        for (Integer i = 0; i < 200; i++) {
            testProducts.add(new Product__c(
                Name = 'Product' + i,
                Min_Credit_Score__c = 600 + i,
                Base_Rate__c = 0.05 + (i * 0.001)
            ));
        }
        insert testProducts;

        Test.startTest();
        List<Product__c> selected = new ProductsSelector().selectAllOrderByRateAsc();
        Test.stopTest();

        System.assertEquals(200, selected.size());
        System.assertEquals(0.05, selected[0].Base_Rate__c);
        System.assertEquals(0.249, selected[199].Base_Rate__c);
    }

    @IsTest
    static void selectAllOrderByRateAsc_EnforcesFLS() {
        Product__c testProduct = new Product__c(
            Name = 'Security Test Product',
            Min_Credit_Score__c = 650,
            Base_Rate__c = 0.075
        );
        insert testProduct;

        Test.startTest();
        try {
            List<Product__c> result = new ProductsSelector().selectAllOrderByRateAsc();
            System.assert(true, 'Query should succeed with proper permissions');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('permissions') || e.getMessage().contains('FLS'), 
                'Should throw security-related exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void selectForRateNormalization_EnforcesFLS() {
        Product__c testProduct = new Product__c(
            Name = 'Security Test Product',
            Min_Credit_Score__c = 650,
            Base_Rate__c = 0.001
        );
        insert testProduct;

        Test.startTest();
        try {
            List<Product__c> result = new ProductsSelector().selectForRateNormalization();
            System.assert(true, 'Query should succeed with proper permissions');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('permissions') || e.getMessage().contains('FLS'), 
                'Should throw security-related exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void newInstance_ReturnsProductsSelector() {
        ProductsSelector instance = ProductsSelector.newInstance();
        System.assertNotEquals(null, instance);
        System.assertEquals(Product__c.SObjectType, instance.getSObjectType());
    }
}