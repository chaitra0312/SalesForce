public class NightlyStockSyncBatch implements Database.Batchable<Product__c>, Database.AllowsCallouts {

    public Iterable<Product__c> start(Database.BatchableContext context) {
        return [SELECT Id, SKU__c, Stock_Quantity__c FROM Product__c WHERE Active__c = true];
    }

    public void execute(Database.BatchableContext context, List<Product__c> scope) {
        List<Product__c> toUpdate = new List<Product__c>();

        for (Product__c prod : scope) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Courier_API/post'); // mock endpoint for practice
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String, String>{ 'sku' => prod.SKU__c }));
            req.setTimeout(30000);

            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 200) {
                    prod.Stock_Quantity__c = prod.Stock_Quantity__c + 10;
                    toUpdate.add(prod);
                }
            } catch (System.CalloutException e) {
                System.debug('Stock sync failed for ' + prod.SKU__c + ': ' + e.getMessage());
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Nightly stock sync completed.');
    }
}
