#include<iostream> // Підключення стандартної бібліотеки введення/виведення

#include<omp.h> // Підключення бібліотеки OpenMP для паралельних обчислень

const int rows = 100000; // Константа для визначення кількості рядків масиву
const int cols = 1000; // Константа для визначення кількості стовпців масиву

int arr[rows][cols]; // Оголошення двовимірного масиву

// Функція для ініціалізації масиву випадковими числами
void init_arr() {
    srand(time(0)); // Ініціалізація генератора випадкових чисел
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            arr[i][j] = rand() % 100; // Присвоєння випадкового числа від 0 до 99 елементу масиву
        }
    }
}

// Функція для знаходження суми всіх елементів масиву з використанням вказаної кількості потоків
long long get_sum(int num_threads, double& execution_time) {
    long long sum = 0; // Змінна для зберігання суми
    double t1 = omp_get_wtime(); // Запам'ятовування поточного часу
    #pragma omp parallel for num_threads(num_threads) reduction(+:sum)
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            sum += arr[i][j]; // Додавання елементу масиву до суми
        }
    }
    double t2 = omp_get_wtime(); // Запам'ятовування поточного часу після обчислень
    execution_time = t2 - t1; // Обчислення часу виконання
    return sum; // Повернення суми
}

// Функція для знаходження рядка масиву з найменшою сумою елементів з використанням вказаної кількості потоків
void get_min_row(int num_threads, int& min_row, int& min_sum, double& execution_time) {
    min_sum = INT_MAX; // Ініціалізація найменшої суми максимальним значенням int
    min_row = -1; // Ініціалізація індексу рядка з найменшою сумою (-1 - невизначений)
    double t1 = omp_get_wtime(); // Запам'ятовування поточного часу
    #pragma omp parallel for num_threads(num_threads)
    for (int i = 0; i < rows; i++) {
        long long row_sum = 0; // Змінна для зберігання суми елементів поточного рядка
        for (int j = 0; j < cols; j++) {
            row_sum += arr[i][j]; // Додавання елементу масиву до суми рядка
        }
        // Перевірка, чи сума поточного рядка менша за поточну найменшу суму
        if (row_sum < min_sum) {
            #pragma omp critical
            {
                if (row_sum < min_sum) { // Додаткова перевірка в критичній секції для уникнення конфлікту потоків
                    min_sum = row_sum; // Оновлення найменшої суми
                    min_row = i; // Оновлення індексу рядка з найменшою сумою
                }
            }
        }
    }
    double t2 = omp_get_wtime(); // Запам'ятовування поточного часу після обчислень
    execution_time = t2 - t1; // Обчислення часу виконання
}

int main() {
    int const max_thread = 8; // Константа для максимальної кількості потоків
    long long sum[max_thread]; // Масив для зберігання сум для різної кількості потоків
    int min_sum[max_thread]; // Масив для зберігання найменших сум для різної кількості потоків
    int min_row[max_thread]; // Масив для зберігання індексів рядків з найменшою сумою для різної кількості потоків
    double executed_time[2][max_thread]; // Двовимірний масив для зберігання часу виконання для різної кількості потоків

    init_arr(); // Ініціалізація масиву

    omp_set_nested(1); // Дозвіл на вкладені паралельні регіони

    double t1 = omp_get_wtime(); // Запам'ятовування поточного часу перед паралельними обчисленнями

    #pragma omp parallel sections
    {
        #pragma omp section
        {
            for (int i = 0; i < max_thread; i++)
            {
                sum[i] = get_sum(i + 1, executed_time[0][i]); // Обчислення суми з використанням різної кількості потоків
            }
        }
        #pragma omp section
        {
            for (int i = 0; i < max_thread; i++)
            {
                get_min_row(i + 1, min_row[i], min_sum[i], executed_time[1][i]); // Знаходження рядка з найменшою сумою з використанням різної кількості потоків
            }
        }
    }

    double t2 = omp_get_wtime(); // Запам'ятовування поточного часу після паралельних обчислень

    // Виведення результатів обчислення сум для різної кількості потоків
    for (int i = 0; i < max_thread; i++) {
        std::cout << "Threads used: " << i + 1 << ", all sum: " << sum[i] << " and executed time: "
                  << executed_time[0][i] << " seconds" << std::endl;
    }

    // Виведення результатів знаходження рядка з найменшою сумою для різної кількості потоків
    for (int i = 0; i < max_thread; i++) {
        std::cout << "Threads used: " << i + 1 << ", Min row: " << min_row[i] << " with min sum " << min_sum[i]
                  << " and executed time: " << executed_time[1][i] << " seconds" << std::endl;
    }

    std::cout << "Total time - " << t2 - t1 << " seconds" << std::endl; // Виведення загального часу виконання

    return 0;
}