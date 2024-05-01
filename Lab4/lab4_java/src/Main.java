import java.util.concurrent.Semaphore;

public class Main {
    public static void PhilosopherRoomStart(int n){
        ForkSem[] forks = new ForkSem[n];
        PhilosopherRoom[] philosophers = new PhilosopherRoom[n];
        Semaphore diningRoom = new Semaphore(2); // Initialize the dining room with a semaphore to limit the number of philosophers

        for (int i = 0; i < forks.length; i++) {
            forks[i] = new ForkSem(i);
        }

        for (int i = 0; i < 5; i++) {
            philosophers[i] = new PhilosopherRoom(i, forks[i], forks[(i + 1) % 5], diningRoom);
            new Thread(philosophers[i]).start();
        }
    }

    public static Philosopher[] createPhilosophers(int n) {

        Fork[] forks = new Fork[n];

        for (int i = 0; i < n; i++) {
            forks[i] = new Fork(i);
        }

        Philosopher[] philosophers = new Philosopher[n];

        for (int i = 0; i < n; i++) {

            Fork leftFork = forks[i];
            Fork rightFork = forks[(i + 1) % n];

            philosophers[i] = new Philosopher(i, leftFork, rightFork);

        }

        return philosophers;

    }


    public static void main(String[] args) {
        int numPhilosophers = 5;

        /*Philosopher[] philosophers = createPhilosophers(numPhilosophers);

        for (Philosopher philosopher : philosophers) {
            philosopher.start();
        }*/



        PhilosopherRoomStart(numPhilosophers);

    }
}