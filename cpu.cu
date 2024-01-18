#include <iostream>
#include <climits>
#include <random>
#include <ctime>

// 宏定义半径
#define radius 1000

using namespace std;

//初始化随机数引擎
default_random_engine engine;

//x，y坐标使用的随机数生成器，生成范围为-radius到+radius的浮点数
uniform_real_distribution<double> distrib(-radius, radius);

//落在圆内的点数
int cpu_circle_count = 0;

//声明时间变量便于计时
clock_t init_start, calc_start, init_end, calc_end;

//点类
class Point {
public:
    double x;
    double y;

    Point(double x, double y) : x(x), y(y) {}
};

//获取随机点
inline Point getPoint() {
    double x = distrib(engine);
    double y = distrib(engine);
    return Point(x, y);
}

//初始化点数组
void initialize_data(Point *points, int N) {
    for (int i = 0; i < N; i++) {
        Point p = getPoint();
        points[i] = p;
    }
}

//计算落在圆内的点个数
void get_circle_dot_count(Point *points, int N) {
    for (int i = 0; i < N; i++) {
        Point p = points[i];
        double distance_square = p.x * p.x + p.y * p.y;//离原点的距离的平方
        if (distance_square <= radius * radius) {
            cpu_circle_count++;
        }
    }
}

void init(Point *&points, int N) {
    init_start = clock();
    {
        cout << "初始化..." << endl;
        points = (Point *) malloc(N * sizeof(Point));
        initialize_data(points, N);
    }
    init_end = clock();
    cout << "初始化时间:" << double(init_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
}

void calculate(Point *&points, int N) {
    calc_start = clock();
    {
        cout << "计算..." << endl;
        get_circle_dot_count(points, N);
        double result = (double) cpu_circle_count / N * 4;
        printf("结果: π = %lf\n", result);
        free(points);
    }
    calc_end = clock();
    cout << "计算时间:" << double(calc_end - calc_start) / CLOCKS_PER_SEC << "s" << endl;
}

int main() {
    //问题规模，即点的数量
    int N = INT_MAX / 3.5;
    Point *points;

    init(points, N);
    calculate(points, N);

    cout << "总时间:" << double(calc_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
    return 0;
}