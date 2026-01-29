#include <stdint.h>
#include <string.h>

// SHA-256 constants (first 32 bits of the fractional parts of the cube roots of the first 64 primes)
static const uint32_t K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

// Rotate right operation
#define ROTR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

// SHA-256 functions
#define CH(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTR(x, 2) ^ ROTR(x, 13) ^ ROTR(x, 22))
#define EP1(x) (ROTR(x, 6) ^ ROTR(x, 11) ^ ROTR(x, 25))
#define SIG0(x) (ROTR(x, 7) ^ ROTR(x, 18) ^ ((x) >> 3))
#define SIG1(x) (ROTR(x, 17) ^ ROTR(x, 19) ^ ((x) >> 10))

// Transform a 512-bit block
static void sha256_transform(uint32_t state[8], const uint8_t block[64]) {
    uint32_t W[64];
    uint32_t a, b, c, d, e, f, g, h, t1, t2;
    int i;

    // Prepare message schedule
    for (i = 0; i < 16; i++) {
        W[i] = ((uint32_t)block[i * 4] << 24) |
               ((uint32_t)block[i * 4 + 1] << 16) |
               ((uint32_t)block[i * 4 + 2] << 8) |
               ((uint32_t)block[i * 4 + 3]);
    }
    
    for (i = 16; i < 64; i++) {
        W[i] = SIG1(W[i - 2]) + W[i - 7] + SIG0(W[i - 15]) + W[i - 16];
    }

    // Initialize working variables
    a = state[0];
    b = state[1];
    c = state[2];
    d = state[3];
    e = state[4];
    f = state[5];
    g = state[6];
    h = state[7];

    // Main compression loop
    for (i = 0; i < 64; i++) {
        t1 = h + EP1(e) + CH(e, f, g) + K[i] + W[i];
        t2 = EP0(a) + MAJ(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }

    // Update state
    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
    state[5] += f;
    state[6] += g;
    state[7] += h;
}

/**
 * DPI-C function to compute SHA-256 hash
 * 
 * @param message: Input message to hash
 * @param msg_len: Length of input message in bytes
 * @param hash: Output buffer for 32-byte (256-bit) hash
 */
void sha256_hash(const char *message, int msg_len, unsigned char hash[32]) {
    uint32_t state[8];
    uint8_t block[64];
    uint64_t bitlen;
    int i, block_idx;

    // Initialize hash values (first 32 bits of the fractional parts of the square roots of the first 8 primes)
    state[0] = 0x6a09e667;
    state[1] = 0xbb67ae85;
    state[2] = 0x3c6ef372;
    state[3] = 0xa54ff53a;
    state[4] = 0x510e527f;
    state[5] = 0x9b05688c;
    state[6] = 0x1f83d9ab;
    state[7] = 0x5be0cd19;

    bitlen = (uint64_t)msg_len * 8;
    block_idx = 0;

    // Process complete blocks
    for (i = 0; i < msg_len; i++) {
        block[block_idx++] = (uint8_t)message[i];
        
        if (block_idx == 64) {
            sha256_transform(state, block);
            block_idx = 0;
        }
    }

    // Add padding
    block[block_idx++] = 0x80;

    // If not enough space for length, process this block and start a new one
    if (block_idx > 56) {
        while (block_idx < 64) {
            block[block_idx++] = 0x00;
        }
        sha256_transform(state, block);
        block_idx = 0;
    }

    // Pad with zeros until we have 8 bytes left for the length
    while (block_idx < 56) {
        block[block_idx++] = 0x00;
    }

    // Append message length in bits (big-endian)
    block[56] = (uint8_t)(bitlen >> 56);
    block[57] = (uint8_t)(bitlen >> 48);
    block[58] = (uint8_t)(bitlen >> 40);
    block[59] = (uint8_t)(bitlen >> 32);
    block[60] = (uint8_t)(bitlen >> 24);
    block[61] = (uint8_t)(bitlen >> 16);
    block[62] = (uint8_t)(bitlen >> 8);
    block[63] = (uint8_t)(bitlen);

    sha256_transform(state, block);

    // Convert hash state to byte array (big-endian)
    for (i = 0; i < 8; i++) {
        hash[i * 4] = (uint8_t)(state[i] >> 24);
        hash[i * 4 + 1] = (uint8_t)(state[i] >> 16);
        hash[i * 4 + 2] = (uint8_t)(state[i] >> 8);
        hash[i * 4 + 3] = (uint8_t)(state[i]);
    }
}

/**
 * Helper DPI-C function to convert hash bytes to hex string
 * 
 * @param hash: 32-byte hash input
 * @param hex_str: Output buffer for 64-character hex string (plus null terminator)
 */
void sha256_to_hex(const unsigned char hash[32], char hex_str[65]) {
    const char hex_chars[] = "0123456789abcdef";
    int i;
    
    for (i = 0; i < 32; i++) {
        hex_str[i * 2] = hex_chars[(hash[i] >> 4) & 0xF];
        hex_str[i * 2 + 1] = hex_chars[hash[i] & 0xF];
    }
    hex_str[64] = '\0';
}