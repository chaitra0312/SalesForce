public class OrderTriggerHandler {

    public static void beforeInsert(List<Order__c> newOrders){

        OrderService.validateOrder(newOrders);

    }

    public static void afterUpdate(
        List<Order__c> newOrders,
        Map<Id, Order__c> oldMap){

        NotificationService.sendOrderNotifications(newOrders, oldMap);

        StatisticsService.updateSalesStatistics(newOrders, oldMap);

    }

}
