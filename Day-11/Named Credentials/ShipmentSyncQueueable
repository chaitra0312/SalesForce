public class ShipmentSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Id shipmentId;

    public ShipmentSyncQueueable(Id shipmentId) {
        this.shipmentId = shipmentId;
    }

    public void execute(QueueableContext context) {
        // 1. Get the shipment record
        Shipment__c shp = [
            SELECT Id, Name, Order__r.Order_Number__c, Order__r.Customer__r.Name,
                   Order__r.Customer__r.Address__c, Courier_Partner__c,
                   Estimated_Delivery_Date__c
            FROM Shipment__c
            WHERE Id = :shipmentId
        ];

        // 2. Build the JSON body (following our API contract)
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('shipmentId', shp.Name);
        payload.put('orderNumber', shp.Order__r.Order_Number__c);
        payload.put('customerName', shp.Order__r.Customer__r.Name);
        payload.put('address', shp.Order__r.Customer__r.Address__c);
        payload.put('courierPartner', shp.Courier_Partner__c);
        payload.put('expectedDeliveryDate', String.valueOf(shp.Estimated_Delivery_Date__c));

        String jsonBody = JSON.serialize(payload);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Courier_API/post');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);

            shp.Last_Sync_Attempt__c = System.now();

            if (res.getStatusCode() == 200) {
                shp.Integration_Status__c = 'Sent';
                shp.External_Shipment_Id__c = 'MOCK-' + shp.Name;
                shp.Integration_Error__c = null;
            } else if (res.getStatusCode() == 401 || res.getStatusCode() == 403) {
                shp.Integration_Status__c = 'Failed';
                shp.Integration_Error__c = 'Auth error: ' + res.getStatusCode();
            } else if (res.getStatusCode() >= 500) {
                shp.Integration_Status__c = 'Retry Required';
                shp.Integration_Error__c = 'Server error: ' + res.getStatusCode();
            } else {
                shp.Integration_Status__c = 'Failed';
                shp.Integration_Error__c = 'Unexpected status: ' + res.getStatusCode();
            }

        } catch (Exception e) {
            shp.Integration_Status__c = 'Failed';
            shp.Integration_Error__c = 'Callout exception: ' + e.getMessage();
        }

        update shp;
    }
}
