public class NightlyStockSyncScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        Database.executeBatch(new NightlyStockSyncBatch(), 5);
    }
}
