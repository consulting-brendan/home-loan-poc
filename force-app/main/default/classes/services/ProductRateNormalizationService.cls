public with sharing class ProductRateNormalizationService {

    public static final Decimal LOWER_RATE = 0.005;  // 0.5%
    public static final Decimal UPPER_RATE = 0.15;   // 15%

    public static void normalizeProductRates() {
        List<Product__c> productsToNormalize = ProductsSelector.newInstance()
            .selectForRateNormalization();

        if (productsToNormalize.isEmpty()) return;

        List<Product__c> changedProducts = ProductsDomain.normalizeRates(
            productsToNormalize, LOWER_RATE, UPPER_RATE
        );

        if (!changedProducts.isEmpty()) {
            update changedProducts;
        }
    }
}