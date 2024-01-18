#include <iostream>
#include <climits>
#include <random>
#include <ctime>

// �궨��뾶
#define radius 1000

using namespace std;

//��ʼ�����������
default_random_engine engine;

//x��y����ʹ�õ�����������������ɷ�ΧΪ-radius��+radius�ĸ�����
uniform_real_distribution<double> distrib(-radius, radius);

//����Բ�ڵĵ���
int cpu_circle_count = 0;

//����ʱ��������ڼ�ʱ
clock_t init_start, calc_start, init_end, calc_end;

//����
class Point {
public:
    double x;
    double y;

    Point(double x, double y) : x(x), y(y) {}
};

//��ȡ�����
inline Point getPoint() {
    double x = distrib(engine);
    double y = distrib(engine);
    return Point(x, y);
}

//��ʼ��������
void initialize_data(Point *points, int N) {
    for (int i = 0; i < N; i++) {
        Point p = getPoint();
        points[i] = p;
    }
}

//��������Բ�ڵĵ����
void get_circle_dot_count(Point *points, int N) {
    for (int i = 0; i < N; i++) {
        Point p = points[i];
        double distance_square = p.x * p.x + p.y * p.y;//��ԭ��ľ����ƽ��
        if (distance_square <= radius * radius) {
            cpu_circle_count++;
        }
    }
}

void init(Point *&points, int N) {
    init_start = clock();
    {
        cout << "��ʼ��..." << endl;
        points = (Point *) malloc(N * sizeof(Point));
        initialize_data(points, N);
    }
    init_end = clock();
    cout << "��ʼ��ʱ��:" << double(init_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
}

void calculate(Point *&points, int N) {
    calc_start = clock();
    {
        cout << "����..." << endl;
        get_circle_dot_count(points, N);
        double result = (double) cpu_circle_count / N * 4;
        printf("���: �� = %lf\n", result);
        free(points);
    }
    calc_end = clock();
    cout << "����ʱ��:" << double(calc_end - calc_start) / CLOCKS_PER_SEC << "s" << endl;
}

int main() {
    //�����ģ�����������
    int N = INT_MAX / 3.5;
    Point *points;

    init(points, N);
    calculate(points, N);

    cout << "��ʱ��:" << double(calc_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
    return 0;
}