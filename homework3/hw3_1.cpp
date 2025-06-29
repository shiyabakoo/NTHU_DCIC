#include<iostream>
#include<complex>
#include<vector>
#include<bitset>
#include <random>
#include <cstdint>
#include <cmath>
#include <iomanip>
#include <fstream>
#include <iterator>
#include <algorithm>
const int N = 64; //group size
const size_t bitstream_length = 1 << 25; // bit stream length
const size_t QPSK_symbol_length = bitstream_length >> 1;
const size_t cp_length = N >> 2; //one cp length
const size_t cp_symbol_length = N + cp_length;
const size_t nb_symbols = bitstream_length >> 7; // number of ofdm symbols
const double pi = M_PI;
std::complex<double> j(0,1);
using Complex = std::complex<double>;
using ComplexFixed = std::complex<int64_t>;
//--------------------------------------------------------FFT part---------------------------------------------------------//
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

//FFT main function
void fft(std::vector<Complex>& a, int N, bool inverse){
    //initialization
    int y = 6;
    int NU = y;
    int N2 = N/2; //first dual node spacing
    int NU1 = y - 1; //for Twiddle Factor
    int k = 0; //first element of input
    int l = 1;
    //butterfly operate
    while(l <= y){
        while(k < N - 1){ // if k >= N + 1, go to next stage
            for(int I = 0;I < N2 ; I++){
                int M = k >> NU1;
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
    
    // for IFFT
    if(inverse){
        for(Complex& x : a){
            x /= N;
        }
    }
}
//-------------------------------------------------------------------------------------------------------------------------//
//QPSK modulation
Complex QPSKmodulation(int data){
    static const Complex constellation[] = {
        {1,1}, {1,-1}, {-1,1}, {-1,-1}
    };
    return constellation[data];
}
//-------------------------------------------------------------------------------------------------------------------------//
//QPSKsymbols generate
std::vector<Complex>qpsk_symbol_generator(std::vector<bool>& bitstream){
    std::vector<Complex> QPSK_symbols;
    for (int i = 0; i < bitstream_length; i += 2) {            
        int data = (bitstream[i] << 1) | bitstream[i + 1];  
        QPSK_symbols.push_back(QPSKmodulation(data) / std::sqrt(2));  
    }
    return QPSK_symbols;
}

//--------------------------------------------------------------------------------------------------------------------------//
//IFFT function
std::vector<Complex> ifftmodulation(std::vector<Complex>& signal){
        std::vector<Complex> ofdm_symbols(nb_symbols * N); 
        for (int i = 0; i < nb_symbols; i++) {
            int start_point = i * N;
            std::vector<Complex> group(signal.begin() + start_point, signal.begin() + start_point + N);
            fft(group, N, true);  // IFFT
            std::copy(group.begin(), group.end(), ofdm_symbols.begin() + start_point); 
        }
        return ofdm_symbols;
}
//--------------------------------------------------------------------------------------------------------------------------//
//insert cp
std::vector<Complex> insert_cyclic_prefix(const std::vector<Complex>& symbols) {
    std::vector<Complex> output;
    output.reserve(nb_symbols * cp_symbol_length); 

    for (size_t i = 0; i < nb_symbols; i++) {
        size_t start = i * N;
        //cp first
        output.insert(output.end(), symbols.begin() + start + N - cp_length, symbols.begin() + start + N);
        //then ofdm_symbol
        output.insert(output.end(), symbols.begin() + start, symbols.begin() + start + N);
    }

    return output;
}
//--------------------------------------------------------------------------------------------------------------------------//
//add AWGN channel
std::vector<Complex> addAWGN(std::vector<Complex>& signal, double SNR_db){
    //calculate power of signal
    double signal_power = 0.0;
    for(const auto& sample : signal ){
        signal_power += std::norm(sample);
    }
    
    signal_power = signal_power/signal.size();//calaulate average power

    double SNR_linear = pow(10,SNR_db/10);
    double noise_power = signal_power/SNR_linear;

    //Add noise to the signal
    std::random_device rd;
    std::mt19937 gen(rd());
    std::normal_distribution<> dis(0, std::sqrt(noise_power / 2));
    
    std::vector<Complex> noise(signal.size());
    std::vector<Complex> noise_signal(signal.size());
    for (size_t i = 0; i < signal.size(); i++) {
        double real_noise = dis(gen);
        double imag_noise = dis(gen);
        noise_signal[i] = signal[i] + Complex(real_noise, imag_noise);
    }
    return noise_signal;
}
//--------------------------------------------------------------------------------------------------------------------------//
//Autocorrelation Function
std::vector<double> AutocorrelationFunction(std::vector<Complex>& signal) {
    int C = 16;
    int signal_size = nb_symbols * (N + cp_length);
    std::vector<double> peak_point(100000, 0.0); 
    
    for(int group = 0; group < 100000; group++) {
        int FFT_boundary = 0;
        double max_gamma_d = 0;
        
        for(int d = 0; d < cp_length + N; d++) {
            Complex phi_d(0, 0);
            double p_d = 0.0;
            
            for(int m = 0; m < 10; m++) {
                for(int k = 0; k < C; k++) {
                    size_t idx = group * (N + cp_length) + d + k + m * (N + cp_length);
                    if (idx >= signal_size || idx + N >= signal_size) {
                        continue;
                    }

                    phi_d += signal[idx] * std::conj(signal[idx + N]); 
                    p_d += std::norm(signal[idx + N]); 
                }
            }

            double gamma_d = std::norm(phi_d) / (p_d * p_d); 

            
            if (gamma_d >= max_gamma_d) {
                max_gamma_d = gamma_d;
                FFT_boundary = d;
            }
        }

        peak_point[group] = FFT_boundary; // save peak point of each group 
    }
    
    return peak_point;
}


//--------------------------------------------------------------------------------------------------------------------------//
// Remove CP function
std::vector<Complex> remove_cyclic_prefix(const std::vector<Complex>& signal, int rx_start_point) {
    std::vector<Complex> output;
    output.reserve(nb_symbols * N); 
    for (size_t i = 0; i < nb_symbols; i++) {
        size_t start = i * cp_symbol_length + rx_start_point + cp_length; // start point for remove cp
        output.insert(output.end(), signal.begin() + start, signal.begin() + start + N); // remove cp
    }
    return output;
}

//--------------------------------------------------------------------------------------------------------------------------//
//QPSK demodulation function
std::vector<bool> QPSKdemapping(const std::vector<Complex>& symbols) {
    std::vector<bool> rx_bitstream;
    rx_bitstream.reserve(bitstream_length);
    for (size_t i = 0; i < QPSK_symbol_length; i++) {
        // Undo the normalization by multiplying by sqrt(2)
        Complex normalized_symbol = symbols[i] * std::sqrt(2);
        // Determine the first bit (real part)
        int real_bit = std::real(normalized_symbol) >= 0 ? 0 : 1;

        // Determine the second bit (imaginary part)
        int imag_bit = std::imag(normalized_symbol) >= 0 ? 0 : 1;
        rx_bitstream.push_back(real_bit);
        rx_bitstream.push_back(imag_bit);
    }

    return rx_bitstream;
}

//--------------------------------------------------------------------------------------------------------------------------//
// Bit Error Rate (BER) calculation
double calculate_BER(const std::vector<bool>& original_bitstream, const std::vector<bool>& rx_bitstream) {
    size_t error_bits = 0;
    
    for (size_t i = 0; i < original_bitstream.size(); i++) {
        if (original_bitstream[i] != rx_bitstream[i]) {
            error_bits++;
        }
    }

    double BER = static_cast<double>(error_bits) / original_bitstream.size();
    return BER;
}

//--------------------------------------------------------------------------------------------------------------------------//
//FFT demodulation function
std::vector<Complex> FFT_demodulation(std::vector<Complex>& signal){
    std::vector<Complex> output;
    output.reserve(nb_symbols * N);
        for (int i = 0; i < nb_symbols; i++) {
            int start_point = i * N;
            std::vector<Complex> group(signal.begin() + start_point, signal.begin() + start_point + N);
            fft(group, N, false);  
            output.insert(output.end(), group.begin(), group.end()); 
        }
        return output;
}
//----------------------------------------------------------fixed point version------------------------------------------------------------//
//floating to fixed point 
int64_t floatToFixedPoint(double value, int scalingFactor) {
    int64_t fixedPointValue = static_cast<int>(std::round(value * scalingFactor));
    return fixedPointValue;
}
//--------------------------------------------------------------------------------------------------------------------------//
//floating point convert to fixed point 
std::vector<ComplexFixed> floatingToFixedpoint(std::vector<Complex>& floating_symbol, int scaling_factor) {
    std::vector<ComplexFixed> fixedPointSymbol;
    fixedPointSymbol.reserve(floating_symbol.size()); 

    for (const auto& symbol : floating_symbol) {
        int64_t real_part = floatToFixedPoint(symbol.real(), scaling_factor);
        int64_t imag_part = floatToFixedPoint(symbol.imag(), scaling_factor);
        fixedPointSymbol.emplace_back(real_part, imag_part);
    }

    return fixedPointSymbol;
}
//--------------------------------------------------------------------------------------------------------------------------//
//fixed point to floating point
double fixedToFloat(int64_t fixedPointValue, int scalingFactor) {
    return static_cast<double>(fixedPointValue) / scalingFactor;
}
//--------------------------------------------------------------------------------------------------------------------------//
//convert fixed point vector to floating
std::vector<Complex> fixedToFloatingPoint(const std::vector<ComplexFixed>& fixedPointSymbols, int scalingFactor) {
    std::vector<Complex> floatingSymbols;
    floatingSymbols.reserve(fixedPointSymbols.size()); 

    for (const auto& symbol : fixedPointSymbols) {
        float realPart = fixedToFloat(symbol.real(), scalingFactor);
        float imagPart = fixedToFloat(symbol.imag(), scalingFactor);
        floatingSymbols.emplace_back(realPart, imagPart);
    }

    return floatingSymbols;
}
//--------------------------------------------------------------------------------------------------------------------------//
//conjuate for fixed point
ComplexFixed conjugate(const ComplexFixed& value) {
    return ComplexFixed(value.real(), -value.imag());
}
//--------------------------------------------------------------------------------------------------------------------------//
// fixed point multiplication
// int64_t fixedPointMul(int64_t a, int64_t b, int scalingFactor) {
//     int64_t result = static_cast<int64_t>(a) * static_cast<int64_t>(b);// 32 bit is to prevent overflow
//     return result / scalingFactor;
// }
int64_t fixedPointMul(int64_t a, int64_t b, int scalingFactor) {
    // 使用 __int128 來儲存和計算超過 64 位的結果
    int64_t result = static_cast<int64_t>(a) * static_cast<int64_t>(b);
    result /= scalingFactor;

    return static_cast<int64_t>(result);
}
//--------------------------------------------------------------------------------------------------------------------------//
//multiplication for complex
ComplexFixed fixedPointComplexMul(const ComplexFixed& a, const ComplexFixed& b, int scalingFactor) {
    int64_t realPart = fixedPointMul(a.real(), b.real(), scalingFactor) 
                       - fixedPointMul(a.imag(), b.imag(), scalingFactor);
    int64_t imagPart = fixedPointMul(a.real(), b.imag(), scalingFactor) 
                       + fixedPointMul(a.imag(), b.real(), scalingFactor);
    return ComplexFixed(realPart, imagPart);
}
//--------------------------------------------------------------------------------------------------------------------------//
// norm for fixed point
int64_t normFixed(std::complex<int64_t> value, int scalingFactor) {
    int64_t realSq = value.real() * value.real();
    int64_t imagSq = value.imag() * value.imag();
    return (realSq + imagSq) / scalingFactor;
}

//--------------------------------------------------------------------------------------------------------------------------//
//fixed point Autocorrelation Function
std::vector<double> AutocorrelationFunction_fixed_point(std::vector<ComplexFixed>& signal, int scalingFactor) {
    int C = 16;
    int signal_size = nb_symbols * (N + cp_length);
    std::vector<double> peak_point(100000, 0.0);
    for(int group = 0; group < 100000; group++) {
        double FFT_boundary = 0;
        double max_gamma_d = 0;
        
        for(int d = 0; d < cp_length ; d++) {
            std::complex<int64_t> phi_d(0, 0);
            int64_t p_d = 0;

            for(int m = 0; m < 10; m++) {
                for(int k = 0; k < C; k++) {
                    size_t idx = group * (N + cp_length) + d + k + m * (N + cp_length);
                    if (idx >= signal_size || idx + N >= signal_size) {
                        continue;
                    }

                    std::complex<int64_t> product = fixedPointComplexMul(signal[idx], conjugate(signal[idx + N]), scalingFactor);
                    phi_d.real(phi_d.real() + product.real());
                    phi_d.imag(phi_d.imag() + product.imag());
                    p_d += normFixed(signal[idx + N], scalingFactor);
                }
            }
            //std::cout <<"d = " << d << "phi_d = (" << phi_d.real() << ","<< phi_d.imag() << ")"<< "\n";
            //int64_t phi_d_norm = normFixed(phi_d, scalingFactor);
            int64_t realSq = phi_d.real() * phi_d.real();
            int64_t imagSq = phi_d.imag() * phi_d.imag();
            int64_t phi_d_norm = realSq + imagSq;
            //std::cout << "phi_d(norm) = " << phi_d_norm << "\n"; 
            //if(p_d > 0){
                double gamma_d = static_cast<double>(phi_d_norm)  / p_d * p_d;
                int64_t fixed_gammad = std::round(gamma_d * scalingFactor);
                //std::cout << "gammad = " << gamma_d << "\n";
                    if (gamma_d >= max_gamma_d) {
                        max_gamma_d = gamma_d;
                        FFT_boundary = d;
                    }
            //}
        }

         peak_point[group] = FFT_boundary;  // 儲存每個 group 的 max_gamma_d
    }
    
    return peak_point;
}

//--------------------------------------------------------------------------------------------------------------------------//
// Remove CP function(fixed point)
std::vector<ComplexFixed> remove_cyclic_prefix_fixed_point(const std::vector<ComplexFixed>& signal, int rx_start_point) {
    std::vector<ComplexFixed> output;
    output.reserve(nb_symbols * N); 
    for (size_t i = 0; i < nb_symbols; i++) {
        size_t start = i * cp_symbol_length + rx_start_point + cp_length; // start point for remove cp
        output.insert(output.end(), signal.begin() + start, signal.begin() + start + N); // remove cp
    }
    return output;
}
//--------------------------------------------------------FFT part(fixed point)---------------------------------------------------------//
//exp for fixed point
ComplexFixed fixedPointExp(int P, int N, int scalingFactor, bool inverse) {

    double angle = 2 * pi * P / N;
    if (!inverse) {
        angle = -angle; 
    }

    double real_part = std::cos(angle);//exp = cos + j * sin
    double imag_part = std::sin(angle);

    int64_t realFixed = static_cast<int64_t>(std::round(real_part * scalingFactor));
    int64_t imagFixed = static_cast<int64_t>(std::round(imag_part * scalingFactor));


    return ComplexFixed(realFixed, imagFixed);
}

//FFT main function
void fft_fixed(std::vector<ComplexFixed>& a, int N, bool inverse, int scalingFactor){
    //initialization
    int y = 6;
    int NU = y;
    int N2 = N/2; //first dual node spacing
    int NU1 = y - 1; //for Twiddle Factor
    int k = 0; //first element of input
    int l = 1;
    //butterfly operate
    while(l <= y){
        while(k < N - 1){ // if k >= N + 1, go to next stage
            for(int I = 0;I < N2 ; I++){
                int M = k >> NU1;
                int P = reverse(M, y);
                ComplexFixed twiddle = fixedPointExp(P, N, scalingFactor, inverse);
                ComplexFixed T1 = fixedPointComplexMul(twiddle, a[k + N2], scalingFactor);
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
    
    // for IFFT
    if(inverse){
        for(ComplexFixed& x : a){
            x /= N;
        }
    }
}
//--------------------------------------------------------------------------------------------------------------------------//
//FFT demodulation (fixed point)
std::vector<ComplexFixed> FFT_demodulation_fixed(std::vector<ComplexFixed>& signal, int scalingFactor){
    std::vector<ComplexFixed> output;
    output.reserve(nb_symbols * N);
        for (int i = 0; i < nb_symbols; i++) {
            int start_point = i * N;
            std::vector<ComplexFixed> group(signal.begin() + start_point, signal.begin() + start_point + N);
            fft_fixed(group, N, false, scalingFactor);  
            output.insert(output.end(), group.begin(), group.end()); 
        }
        return output;
}
//--------------------------------------------------------------------------------------------------------------------------//
//QPSK demodulation function fixed point
std::vector<bool> QPSKdemapping_fixed_point(const std::vector<ComplexFixed>& symbols, int scalingFactor) {
    std::vector<bool> rx_bitstream;
    rx_bitstream.reserve(bitstream_length);
    int64_t fixed_sqrt2 = static_cast<int64_t>(std::round(std::sqrt(2) * scalingFactor));
    for (size_t i = 0; i < QPSK_symbol_length; i++) {
        // Undo the normalization by multiplying by sqrt(2)
        int64_t real_part = fixedPointMul(std::real(symbols[i]), fixed_sqrt2, scalingFactor);
        int64_t imag_part = fixedPointMul(std::imag(symbols[i]), fixed_sqrt2, scalingFactor);
        // Determine the first bit (real part)
        int real_bit = real_part >= 0 ? 0 : 1;

        // Determine the second bit (imaginary part)
        int imag_bit = imag_part >= 0 ? 0 : 1;
        rx_bitstream.push_back(real_bit);
        rx_bitstream.push_back(imag_bit);
    }

    return rx_bitstream;
}
//--------------------------------------------------------------------------------------------------------------------------//
int countNonZero(const std::vector<double>& vec) {
    int count = 0;
    for (int value : vec) {
        if (value != 0) {
            count++;
        }
    }
    return count;
}
//--------------------------------------------------------------------------------------------------------------------------//
int calculate_error(const std::vector<double>& vec, const std::vector<double>& ref ) {
    int count = 0;
    size_t size = std::min(vec.size(), ref.size());
    for (size_t i = 0; i < size; ++i) { 
        if(vec[i] != ref[i]){
            count++;
        }
    }
    return count;
}
//--------------------------------------------------------matlab plot----------------------------------------------------------------//
//output ofdm_stmbols for matlab
void ofdm_symbols_waveform(std::vector<Complex>& signal){
    std::ofstream file("ofdm_symbols.txt");
    for (int i = 0; i < 240; i++) {
        file << std::real(signal[i]) << " " << std::imag(signal[i]) << "\n";
    }
    file.close();
}
void noise_ofdm_symbols_waveform3db(std::vector<Complex>& signal){
    std::ofstream file_noise_ofdm("noise_ofdm_symbols_3db.txt");
    for (int i = 0; i < 240; i++) {
        file_noise_ofdm << std::real(signal[i]) << " " << std::imag(signal[i]) << "\n";
    }
    file_noise_ofdm.close();
}
void noise_ofdm_symbols_waveform15db(std::vector<Complex>& signal){
    std::ofstream file_noise_ofdm("noise_ofdm_symbols_15db.txt");
    for (int i = 0; i < 240; i++) {
        file_noise_ofdm << std::real(signal[i]) << " " << std::imag(signal[i]) << "\n";
    }
    file_noise_ofdm.close();
}
// Save the first 192 rx_qpsk_symbols to a file for MATLAB plotting
void save_rx_qpsk_symbols(const std::vector<Complex>& rx_qpsk_symbols, const std::string& filename) {
    std::ofstream file(filename);
    for (int i = 0; i < 192; i++) {
        file << std::real(rx_qpsk_symbols[i]) * std::sqrt(2) << " " << std::imag(rx_qpsk_symbols[i]) * std::sqrt(2) << "\n";
    }
    file.close();
}
// ouput error
void OutputErrorToTXT(const std::vector<double>& errors, const std::vector<int>& wordLengths, const std::string& filename) {
    std::ofstream file(filename);
    if (file.is_open()) {
        file << "WordLength\tError\n";
        for (size_t i = 0; i < errors.size(); ++i) {
            file << wordLengths[i] << "\t" << errors[i] << "\n";
        }
        file.close();
        std::cout << "Error data successfully written to " << filename << "\n";
    } else {
        std::cerr << "Unable to open file " << filename << "\n";
    }
}
//--------------------------------------------------------print part----------------------------------------------------------------//

//print the vector
void print_rx_bitstream(const std::vector<bool>& rx_bitstream) {
    std::cout << "rx_bitstream: ";
    for (size_t i = 0; i < rx_bitstream.size(); i++) {
        std::cout << rx_bitstream[i];
        if (i % 8 == 7) {
            std::cout << " ";  // Insert space every 8 bits for readability
        }
    }
    std::cout << std::endl;
}
//print fixed point and origin for comparsion
void printComplexVector(const std::vector<Complex>& vec, const std::string& vec_name) {
    std::cout << vec_name << " 前 10 個元素:\n";
    for (size_t i = 0; i < 320 && i < vec.size(); ++i) {
        std::cout << "Element " << i << ": (" << std::real(vec[i]) << ", " << std::imag(vec[i]) << ")\n";
    }
}

void printComplexFixedVector(const std::vector<std::complex<int16_t>>& vec, const std::string& name, int scalingFactor) {
    std::cout << "前 10 個 " << name << ":\n";
    for (size_t i = 0; i < std::min(vec.size(), static_cast<size_t>(10)); ++i) {
        double real = static_cast<double>(vec[i].real()) / scalingFactor;
        double imag = static_cast<double>(vec[i].imag()) / scalingFactor;
        std::cout << name << "[" << i << "] = (" << real << ", " << imag << ")\n";
    }
}
//--------------------------------------------------------------------------------------------------------------------------//

int main(){

     //for (int run = 0; run < 1000; ++run) {
        //generate random bit stream
        std::cout << "start generator bitstream\n";
        std::cout << "============================================\n";
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<int> dis(0,1);
        std::vector<bool> bitstream; // each bool is 1 bit
        for (int i = 0; i < bitstream_length; ++i) {
            bitstream.push_back(dis(gen));  
        }

        //start QAM mapping
        std::cout << "start QAM mapping\n";
        std::cout << "============================================\n";
        std::vector<Complex> QPSK_symbols =  qpsk_symbol_generator(bitstream);
        
        // S/P and IFFT
        std::cout << "start IFFT \n";
        std::cout << "============================================\n";
        std::vector<Complex> ofdm_symbols = ifftmodulation( QPSK_symbols);
        std::cout << "start cp insertion\n";
        std::cout << "============================================\n";
        std::vector<Complex> ofdm_symbols_with_cp = insert_cyclic_prefix(ofdm_symbols);
        //plot waveform
        ofdm_symbols_waveform(ofdm_symbols_with_cp);
        

        // AWGN channel
        std::cout << "start add AWGN\n";
        std::cout << "============================================\n";
        double SNR = 6;
        std::vector<Complex> noise_ofdm_symbols = addAWGN(ofdm_symbols_with_cp, SNR);
        //Autocorrelation  
        std::cout << "start autocorrelation\n";
        std::cout << "============================================\n";
        std::vector<double> peak_point_floating = AutocorrelationFunction(noise_ofdm_symbols);
        int error =countNonZero(peak_point_floating);
        std::cout << "error = " << error << "\n";
        // size_t rx_start_point = AutocorrelationFunction(ofdm_symbols_with_cp);
        // Autocorrelation(fixed point)
        int scalingFactor_8bit = 1 << 4;
        int scalingFactor_10bit = 1 << 5;
        int scalingFactor_12bit = 1 << 6;
        int scalingFactor_14bit = 1 << 7;
        int scalingFactor_16bit = 1 << 8;
        int scalingFactor_18bit = 1 << 9;
        int scalingFactor_20bit = 1 << 10;;
        
        //std::vector<ComplexFixed> noise_ofdm_symbols_8bit_fixed_point = floatingToFixedpoint(ofdm_symbols_with_cp, scalingFactor_8bit );
        std::vector<ComplexFixed> noise_ofdm_symbols_8bit_fixed_point = floatingToFixedpoint(noise_ofdm_symbols, scalingFactor_8bit );
        std::vector<ComplexFixed> noise_ofdm_symbols_10bit_fixed_point = floatingToFixedpoint(noise_ofdm_symbols, scalingFactor_10bit );
        std::vector<ComplexFixed> noise_ofdm_symbols_12bit_fixed_point = floatingToFixedpoint(noise_ofdm_symbols, scalingFactor_12bit );
        std::vector<ComplexFixed> noise_ofdm_symbols_14bit_fixed_point = floatingToFixedpoint(noise_ofdm_symbols, scalingFactor_14bit );
        std::vector<ComplexFixed> noise_ofdm_symbols_16bit_fixed_point = floatingToFixedpoint(noise_ofdm_symbols, scalingFactor_16bit);
        std::vector<ComplexFixed> noise_ofdm_symbols_18bit_fixed_point = floatingToFixedpoint(noise_ofdm_symbols, scalingFactor_18bit );
        std::vector<ComplexFixed> noise_ofdm_symbols_20bit_fixed_point = floatingToFixedpoint(noise_ofdm_symbols, scalingFactor_20bit );


    std::ofstream errorFile("percentage_error_results.txt");
    if (!errorFile.is_open()) {
        std::cerr << "Failed to open file for writing." << std::endl;
        return 1;
    }

    std::cout << "start autocorrelation 8bit fixed point version\n";
    std::cout << "============================================\n";
    std::vector<double> peak_point_8bit = AutocorrelationFunction_fixed_point(noise_ofdm_symbols_8bit_fixed_point, scalingFactor_8bit);
    int error_8bit = calculate_error(peak_point_8bit, peak_point_floating);
    double percentage_error_8bit = error_8bit / 100000.0;
    errorFile << "8 " << percentage_error_8bit << "\n";
    std::cout << "percentage_error_8bit = " << percentage_error_8bit << "\n";

    std::cout << "start autocorrelation 10bit fixed point version\n";
    std::cout << "============================================\n";
    std::vector<double> peak_point_10bit = AutocorrelationFunction_fixed_point(noise_ofdm_symbols_10bit_fixed_point, scalingFactor_10bit);
    int error_10bit = calculate_error(peak_point_10bit, peak_point_floating);
    double percentage_error_10bit = error_10bit / 100000.0;
    errorFile << "10 " << percentage_error_10bit << "\n";
    std::cout << "percentage_error_10bit = " << percentage_error_10bit << "\n";

    std::cout << "start autocorrelation 12bit fixed point version\n";
    std::cout << "============================================\n";
    std::vector<double> peak_point_12bit = AutocorrelationFunction_fixed_point(noise_ofdm_symbols_12bit_fixed_point, scalingFactor_12bit);
    int error_12bit = calculate_error(peak_point_12bit, peak_point_floating);
    double percentage_error_12bit = error_12bit / 100000.0;
    errorFile << "12 " << percentage_error_12bit << "\n";
    std::cout << "percentage_error_12bit = " << percentage_error_12bit << "\n";

    std::cout << "start autocorrelation 14bit fixed point version\n";
    std::cout << "============================================\n";
    std::vector<double> peak_point_14bit = AutocorrelationFunction_fixed_point(noise_ofdm_symbols_14bit_fixed_point, scalingFactor_14bit);
    int error_14bit = calculate_error(peak_point_14bit, peak_point_floating);
    double percentage_error_14bit = error_14bit / 100000.0;
    errorFile << "14 " << percentage_error_14bit << "\n";
    std::cout << "percentage_error_14bit = " << percentage_error_14bit << "\n";

    std::cout << "start autocorrelation 16bit fixed point version\n";
    std::cout << "============================================\n";
    std::vector<double> peak_point_16bit = AutocorrelationFunction_fixed_point(noise_ofdm_symbols_16bit_fixed_point, scalingFactor_16bit);
    int error_16bit = calculate_error(peak_point_16bit, peak_point_floating);
    double percentage_error_16bit = error_16bit / 100000.0;
    errorFile << "16 " << percentage_error_16bit << "\n";
    std::cout << "percentage_error_16bit = " << percentage_error_16bit << "\n";

    std::cout << "start autocorrelation 18bit fixed point version\n";
    std::cout << "============================================\n";
    std::vector<double> peak_point_18bit = AutocorrelationFunction_fixed_point(noise_ofdm_symbols_18bit_fixed_point, scalingFactor_18bit);
    int error_18bit = calculate_error(peak_point_18bit, peak_point_floating);
    double percentage_error_18bit = error_18bit / 100000.0;
    errorFile << "18 " << percentage_error_18bit << "\n";
    std::cout << "percentage_error_18bit = " << percentage_error_18bit << "\n";

    std::cout << "start autocorrelation 20bit fixed point version\n";
    std::cout << "============================================\n";
    std::vector<double> peak_point_20bit = AutocorrelationFunction_fixed_point(noise_ofdm_symbols_20bit_fixed_point, scalingFactor_20bit);
    int error_20bit = calculate_error(peak_point_20bit, peak_point_floating);
    double percentage_error_20bit = error_20bit / 100000.0;
    errorFile << "20 " << percentage_error_20bit << "\n";
    std::cout << "percentage_error_20bit = " << percentage_error_20bit << "\n";

    errorFile.close();
    return 0;

}




