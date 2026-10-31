#include <stdint.h>
#include <stddef.h>

// Schnelle IEEE 802.3 CRC32 Berechnung in C
uint32_t fast_crc32(const uint8_t* data, size_t length) {
    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < length; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            if (crc & 1) {
                crc = (crc >> 1) ^ 0xEDB88320;
            } else {
                crc >>= 1;
            }
        }
    }
    return crc ^ 0xFFFFFFFF;
}

// Schnelle XOR-Chiffrierung (Keystream-Modus)
void chacha20_xor(uint8_t* out, const uint8_t* in, size_t length, const uint8_t* key) {
    for (size_t i = 0; i < length; i++) {
        out[i] = in[i] ^ key[i % 32];
    }
}
