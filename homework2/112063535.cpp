#include<iostream>
#include<complex>
#include<vector>
#include<bitset>
#include <random>
#include <cmath>
#include <iomanip>
#include <fstream>
const int N = 64; //group size
const size_t bitstream_length = 1 << 25; // bit stream length
const size_t QPSK_symbol_length = bitstream_length >> 1;
const size_t cp_length = N >> 2; //one cp length
const size_t cp_symbol_length = N + cp_length;
const size_t nb_symbols = bitstream_length >> 7; // number of ofdm symbols
const double pi = M_PI;
std::complex<double> j(0,1);
using Complex = std::complex<double>;

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
    for (auto& sample : noise) {
        double real_noise = dis(gen);
        double imag_noise = dis(gen);
        sample = Complex(real_noise, imag_noise);
    }

    std::vector<Complex> noise_signal(signal.size());
    for (size_t i = 0; i < signal.size(); i++) {
        noise_signal[i] = signal[i] + noise[i];
    }
    return noise_signal;
}
//--------------------------------------------------------------------------------------------------------------------------//
//Autocorrelation Function
int AutocorrelationFunction(std::vector<Complex>& signal){
    int C = cp_length;
    double max_gamma_d = 0.0;
    int FFT_boundary = 0;
    int signal_size = nb_symbols * cp_symbol_length;
    for(int d = 0; d < cp_length + N; d++){
        Complex phi_d(0,0);
        double p_d = 0.0;
        for(int m = 0; m < nb_symbols; m++){
            for(int k = 0; k < C ; k++){
                size_t idx = d + k + m * (N + cp_length);
                if (idx >= signal_size || idx + N >= signal_size) {
                    continue;
                }
                phi_d += signal[idx] * std::conj(signal[idx + N]);//step1 calaulate phi_d
                p_d += std::norm(signal[idx + N]);//step2 calaulate p_d
                
            }
        }
        
        double gamma_d = std::norm(phi_d) / (p_d * p_d);//step3 calculation gamma_d

        //step4 find max gamma_d and boundary
        if(gamma_d > max_gamma_d){
            max_gamma_d = gamma_d;
            FFT_boundary = d;
        }

    }
    std::cout << "max_gamma = " << max_gamma_d << "\n";
    std::cout << "start point = " << FFT_boundary << "\n";
    return FFT_boundary;
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
//--------------------------------------------------------------------------------------------------------------------------//

int main(){
    std::vector<double> SNR_db_values;
    std::vector<double> BER_values;

    for (double SNR_db = 0.0; SNR_db <= 24.0; SNR_db += 3.0) {
        //generate random bit stream
        std::cout << "start generator bitstream\n";
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<int> dis(0,1);
        std::vector<bool> bitstream; // each bool is 1 bit
        for (int i = 0; i < bitstream_length; ++i) {
            bitstream.push_back(dis(gen));  
        }

        //start QAM mapping
        std::cout << "start QAM mapping\n";
        std::vector<Complex> QPSK_symbols =  qpsk_symbol_generator(bitstream);
        
        // S/P and IFFT
        std::cout << "start IFFT \n";
        std::vector<Complex> ofdm_symbols = ifftmodulation( QPSK_symbols);
        std::cout << "start cp insertion\n";
        std::vector<Complex> ofdm_symbols_with_cp = insert_cyclic_prefix(ofdm_symbols);
        //plot waveform
        ofdm_symbols_waveform(ofdm_symbols_with_cp);
        

        // AWGN channel
        std::cout << "start add AWGN\n";
        std::vector<Complex> noise_ofdm_symbols = addAWGN(ofdm_symbols_with_cp, SNR_db);
        //plot waveform
        if(SNR_db == 3){
        noise_ofdm_symbols_waveform3db(noise_ofdm_symbols);
        }
        if(SNR_db == 15){
        noise_ofdm_symbols_waveform15db(noise_ofdm_symbols);
        }
        // Autocorrelation and CP removal
        std::cout << "start autocorrelation\n";
        size_t rx_start_point = AutocorrelationFunction(noise_ofdm_symbols);
        std::cout << "start remove cp\n";
        std::vector<Complex> rx_ofdm_symbols = remove_cyclic_prefix(noise_ofdm_symbols, rx_start_point);

        // FFT demodulation
        std::cout << "start FFT demodulation\n";
        std::cout << "rx_ofdm_symbols size: " << rx_ofdm_symbols.size() << std::endl;
        std::vector<Complex> rx_qpsk_symbols = FFT_demodulation(rx_ofdm_symbols);
        // Save the first 192 rx_qpsk_symbols for SNR = 3dB and SNR = 15dB
        if (SNR_db == 3) {
            save_rx_qpsk_symbols(rx_qpsk_symbols, "rx_qpsk_symbols_3db.txt");
        }
        if (SNR_db == 15) {
            save_rx_qpsk_symbols(rx_qpsk_symbols, "rx_qpsk_symbols_15db.txt");
        }

        // QPSK demodulation
        std::cout << "start  QPSK demodulation\n";
        std::vector<bool> rx_bitstream = QPSKdemapping(rx_qpsk_symbols);
        // Calculate BER
        std::cout << "start  Calculate BER\n";
        double BER = calculate_BER(bitstream, rx_bitstream);
        std::cout << "SNR = " << SNR_db << " dB, BER = " << std::fixed << std::setprecision(10) << BER << "\n";

        // Save the SNR and BER values
        SNR_db_values.push_back(SNR_db);
        BER_values.push_back(BER);
    }

    // Output BER vs SNR data to a file for MATLAB plotting
    std::ofstream file("ber_vs_snr.txt");
    for (size_t i = 0; i < SNR_db_values.size(); i++) {
        file << SNR_db_values[i] << " " << BER_values[i] << "\n";
    }
    file.close();
}



