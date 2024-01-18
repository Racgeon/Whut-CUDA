#include <iostream>
#include <climits>
#include <random>
#include <ctime>
#include <cassert>
#include <curand_kernel.h>

#define radius 1000

using namespace std;

//由于GPU计算后要在CPU内输出结果，所以使用__managed__
__managed__ int gpu_circle_count;

//声明时间变量便于计时
clock_t init_start, calc_start, init_end, calc_end;

//点类
class Point {
public:
    double x;
    double y;

    __device__ Point(double x, double y) : x(x), y(y) {}
};


//GPU版的获取随机点
__device__ inline Point getPoint() {
    //由于GPU不能使用CPU使用的随机数引擎，所以使用cuda提供的随机数引擎
    curandState state;
    int salt = threadIdx.x + blockDim.x * blockIdx.x;
    //以线程索引为salt和系统时间相加作为随机数种子
    curand_init(clock64() + salt, 0, 0, &state);

    //生成范围为-radius到+radius的浮点数
    double x = (curand(&state) % (2 * radius * 100)) / 100.0 - radius;
    double y = (curand(&state) % (2 * radius * 100)) / 100.0 - radius;
    return Point(x, y);
}

inline cudaError_t checkCuda(cudaError_t result) {
    if (result != cudaSuccess) {
        fprintf(stderr, "%s\n", cudaGetErrorString(result));
        assert(result == cudaSuccess);
    }
    return result;
}

//核函数版本的初始化点数组
__global__ void initialize_data(Point *points, int N) {
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int grid_stride = blockDim.x * gridDim.x;

    for (; i < N; i += grid_stride) {
        Point p = getPoint();
        points[i] = p;
    }
}

//核函数版本的计算落在圆内的点个数
__global__ void get_circle_dot_count(Point *points, int N) {
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int grid_stride = blockDim.x * gridDim.x;

    for (; i < N; i += grid_stride) {
        Point p = points[i];
        double distance_square = p.x * p.x + p.y * p.y;
        if (distance_square <= radius * radius) {
            atomicAdd(&gpu_circle_count, 1);
        }
    }
}


void init(Point *&points, int N) {
    init_start = clock();
    {
        cout << "初始化..." << endl;
        checkCuda(cudaMallocManaged(&points, N * sizeof(Point)));
        initialize_data<<<4, 32>>>(points, N);
    }
    init_end = clock();
    cout << "初始化时间:" << double(init_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
}

void calculate(Point *&points, int N) {
    calc_start = clock();
    {
        cout << "计算..." << endl;
        get_circle_dot_count<<<4, 32>>>(points, N);
        checkCuda(cudaDeviceSynchronize());
        double gpu_result = (double) gpu_circle_count / N * 4;
        printf("结果: π = %lf\n", gpu_result);
        cudaFree(points);
    }
    calc_end = clock();
    cout << "计算时间:" << double(calc_end - calc_start) / CLOCKS_PER_SEC << "s" << endl;
}

int main() {
    Point *points;
    int N = INT_MAX / 3.5;

    init(points, N);
    calculate(points, N);

    cout << "总时间:" << double(calc_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
    return 0;
}