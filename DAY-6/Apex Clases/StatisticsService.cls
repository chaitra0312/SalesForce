public class StatisticsService {

    public static void updateSalesStatistics(
        List<Order__c> newOrders,
        Map<Id, Order__c> oldMap
    ) {

        Integer deliveredOrders = 0;

        for(Order__c ord : newOrders){

            if(ord.Status__c == 'Delivered'){
                deliveredOrders++;
            }

        }

        System.debug('Delivered Orders : ' + deliveredOrders);

    }

}
