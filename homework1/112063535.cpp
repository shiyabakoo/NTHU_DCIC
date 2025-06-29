#include <iostream>
#include <vector>
#include <complex>
#include <iomanip>
#include <random>
#include <cmath>
#include <bitset>

const int N = 64;
const double pi = M_PI;
std::complex<double> j(0,1);
using Complex = std::complex<double>;
//--------------------------------------------------------
//caculate power of two
int getPowerOfTwo(int N){
    int power = 0 ;
    while(N > 1){
        N = N >> 1;
        power++;
    }
    return power;
}
//--------------------------------------------------------
// 16QAM modulate
Complex modulate16QAM(int data){
    static const Complex constellation[] = {
        {-3,3}, {-3,1}, {-3,-3}, {-3,-1},
        {-1,3}, {-1,1}, {-1,-3}, {-1,-1},
        {1,3}, {1,1}, {1,-3}, {1,-1},
        {3,3}, {3,1}, {3,-3}, {3,-1} 
    };
    return constellation[data];
}
//--------------------------------------------------------
//bit reverse
int reverse(int m, int NU){
    int IBR = 0;
    for(int I1 = 0; I1 < NU; I1++){
        int J2 =m >> 1;
        IBR = 2 * IBR + (m - 2 * J2);
        m = J2;
    }
    return IBR;
}
//--------------------------------------------------------
// Equal function
bool areEqual(const Complex& a, const Complex& b, double epsilon = 1e-6) {
    return std::abs(a.real() - b.real()) < epsilon && // std::abs, Take the absolute value
        std::abs(a.imag() - b.imag()) < epsilon;
}
//--------------------------------------------------------
//compare result
bool compareResult(std::vector<Complex>& x, std::vector<Complex>& y){
    for (int i = 0; i < N; i++){
        if (!areEqual(x[i], y[i])){
            return false;
        }
    }
    return true;
}
//--------------------------------------------------------
//FFT
void fft(std::vector<Complex>& a, int N, bool inverse){
    //initialization
    int y =getPowerOfTwo(N);
    int NU = y;
    int N2 = N/2; //first dual node spacing
    int NU1 = y - 1; //for Twiddle Factor
    int k = 0; //first element of input
    int l = 1;
    //butterfly operate
    while(l <= y){
        while(k < N - 1){ // if k >= N + 1, go to next stage
            for(int I = 0;I < N2 ; I++){
                // std::cout << "k = "; 
                // std::cout << k <<"\n\n";
                int M = k >> NU1;
                // int M = k / pow(2, NU1);
                int P = reverse(M, y);
                std::complex<double> T1 = std::exp((inverse?j:-j) * (2 * pi * P / N)) * a[k + N2];
                a[k + N2] = a[k] - T1;
                a[k] = a[k] + T1;
                k++;
                }
            k = k + N2;
        }
        l = l + 1; // next stage
        k = 0; //reset k
        N2 = N2 / 2; //smaller dual node spacing
        NU1 = NU1 - 1;    
        }
       
    //unscrambling
    for(k=0; k < N-1; k++){
        int r = reverse(k,y);
        if (k > r){
            std:swap(a[r], a[k]);
        }
    }
    

    if(inverse){
        for(Complex& x : a){
            x /= N;
        }
    }
}
//--------------------------------------------------------
//main function
int main(){
    //input data
    std::vector<Complex> input(N);
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<int> dis(0,1);
    std::bitset<N*4> bitStream;
    // generate bitstream
    for (int i = 0; i < N*4; i++) {
         bitStream[i] = dis(gen);  
    }
    // sample 4 bit data and modulation
    for(int i = 0; i < N; i++){
        int data = 0;
        for(int j = 0; j < 4; j++){
            data = (data << 1) | bitStream[i*4 + j];
        }
        input[i] = modulate16QAM(data);
    }

    std::cout << "input" << "\n";
    for (int i = 0; i < N; ++i) {
        std::ostringstream oss_input;
        oss_input << std::fixed << std::setprecision(3)
        << (std::real(input[i]) >= 0 ? " " : "")
        << std::real(input[i])
        << (std::imag(input[i]) >= 0 ? " + " : " - ")
        << (std::imag(input[i]) >= 0 ?  std::imag(input[i]) : -std::imag(input[i])) << "i";
        std::cout << oss_input.str() <<",\n";
    }
    std::cout << "\n";

    for(int i = 0; i < N; i++){
    input[i] /= std::sqrt(10);  // Divide each complex value by the square root of 10
    }

    //start ifft
    int power = getPowerOfTwo(N);
    std::vector<Complex> ifft_result = input;
    fft(ifft_result, N, true);


    //start fft
    std::vector<Complex> fft_result = ifft_result;
    fft(fft_result, N, false);

 
//--------------------------------------------------------------------------------------------------------------------
    //print result
    std::cout << "ifft_result" << "\n";
    for (int i = 0; i < N; ++i) {
        std::ostringstream oss_ifft;
        oss_ifft << std::fixed << std::setprecision(3)
            << (std::round(std::real(ifft_result[i]) * 1000) / 1000 >= 0 ? " " : "")
            << std::round(std::real(ifft_result[i]) * 1000) / 1000
            << (std::round(std::imag(ifft_result[i]) * 1000) / 1000 >= 0 ? " + " : " - ")
            << std::abs(std::round(std::imag(ifft_result[i]) * 1000) / 1000) << "i";
        std::cout << oss_ifft.str() << ",\n";
    }
    std::cout << "\n";

    std::cout << std::setw(10) << std::left << "index" 
            << std::setw(30) << std::left << "input" // std::setw(30) set string width
            << std::setw(30) << std::left << "ifft_result"
            << std::setw(30) << std::left << "fft_result"
            << "\n";

    for (int i = 0; i < 120; i++){
        std::cout <<"-";
    }
    std::cout <<"\n";    
    for (int i = 0; i < N; ++i) {
            std::ostringstream oss_input, oss_ifft, oss_fft; // Use ostringstream to format each complex number into a complete string
            // input 
            oss_input << std::fixed << std::setprecision(3)
                    << (std::real(input[i]) >= 0 ? " " : "")
                    << std::real(input[i])
                    << (std::imag(input[i]) >= 0 ? " + " : " - ")
                    << (std::imag(input[i]) >= 0 ?  std::imag(input[i]) : -std::imag(input[i])) << "i";

            // ifft_result 
            oss_ifft << std::fixed << std::setprecision(3)
                    << (std::real(ifft_result[i]) >= 0 ? " " : "")
                    << std::real(ifft_result[i])
                    << (std::imag(ifft_result[i]) >= 0 ? " + " : " - ")
                    << (std::imag(ifft_result[i]) >= 0 ?  std::imag(ifft_result[i]) : - std::imag(ifft_result[i])) << "i";

            // fft_result 
            oss_fft << std::fixed << std::setprecision(3)
                    << (std::real(fft_result[i]) >= 0 ? " " : "")
                    << std::real(fft_result[i])
                    << (std::imag(fft_result[i]) >= 0 ? " + " : " - ")
                    << (std::imag(fft_result[i]) >= 0 ?  std::imag(fft_result[i]) : - std::imag(fft_result[i])) << "i";

            // print all 
            std::cout << std::setw(10) << std::left << i+1 
                    << std::setw(30) << std::left << oss_input.str()
                    << std::setw(30) << std::left << oss_ifft.str()
                    << std::setw(30) << std::left << oss_fft.str()
                    << "\n";
        }


    bool match = compareResult(input, fft_result);
    if(match) {
        std::cout << "the input matches the FFT results\n" ;
    }
    else{
        std::cout << "ERROR\n";
    }

    return 0;
}
//--------------------------------------------------------