#include <iostream>
#include <climits>
#include <random>
#include <ctime>
#include <cassert>
#include <curand_kernel.h>

#define radius 1000

using namespace std;

//����GPU�����Ҫ��CPU��������������ʹ��__managed__
__managed__ int gpu_circle_count;

//����ʱ��������ڼ�ʱ
clock_t init_start, calc_start, init_end, calc_end;

//����
class Point {
public:
    double x;
    double y;

    __device__ Point(double x, double y) : x(x), y(y) {}
};


//GPU��Ļ�ȡ�����
__device__ inline Point getPoint() {
    //����GPU����ʹ��CPUʹ�õ���������棬����ʹ��cuda�ṩ�����������
    curandState state;
    int salt = threadIdx.x + blockDim.x * blockIdx.x;
    //���߳�����Ϊsalt��ϵͳʱ�������Ϊ���������
    curand_init(clock64() + salt, 0, 0, &state);

    //���ɷ�ΧΪ-radius��+radius�ĸ�����
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

//�˺����汾�ĳ�ʼ��������
__global__ void initialize_data(Point *points, int N) {
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int grid_stride = blockDim.x * gridDim.x;

    for (; i < N; i += grid_stride) {
        Point p = getPoint();
        points[i] = p;
    }
}

//�˺����汾�ļ�������Բ�ڵĵ����
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
        cout << "��ʼ��..." << endl;
        checkCuda(cudaMallocManaged(&points, N * sizeof(Point)));
        initialize_data<<<4, 32>>>(points, N);
    }
    init_end = clock();
    cout << "��ʼ��ʱ��:" << double(init_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
}

void calculate(Point *&points, int N) {
    calc_start = clock();
    {
        cout << "����..." << endl;
        get_circle_dot_count<<<4, 32>>>(points, N);
        checkCuda(cudaDeviceSynchronize());
        double gpu_result = (double) gpu_circle_count / N * 4;
        printf("���: �� = %lf\n", gpu_result);
        cudaFree(points);
    }
    calc_end = clock();
    cout << "����ʱ��:" << double(calc_end - calc_start) / CLOCKS_PER_SEC << "s" << endl;
}

int main() {
    Point *points;
    int N = INT_MAX / 3.5;

    init(points, N);
    calculate(points, N);

    cout << "��ʱ��:" << double(calc_end - init_start) / CLOCKS_PER_SEC << "s" << endl;
    return 0;
}