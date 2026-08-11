public with sharing class CouponValidationService {

    @AuraEnabled
    public static String validateCoupon(String couponCode) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Courier_API/post'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, String>{ 'couponCode' => couponCode }));
        req.setTimeout(15000);

        Http http = new Http();

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                return 'VALID: Coupon accepted';
            } else {
                return 'INVALID: Could not validate (status ' + res.getStatusCode() + ')';
            }

        } catch (System.CalloutException e) {
            return 'ERROR: Validation service unavailable, please try again';
        }
    }
}
