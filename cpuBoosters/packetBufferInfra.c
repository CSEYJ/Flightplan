
#include "rse.h"

/* ethernet headers are always exactly 14 bytes [1] */
#define SIZE_ETHERNET 14

#define NUM_DATA_PACKETS 3
#define NUM_PARITY_PACKETS 3

int SIZE_FEC_TAG = 0;

typedef struct fec_header {
	uint8_t blockId;
	uint8_t pktId;
} fec_header_t;

void my_packet_handler(
    u_char *args,
    const struct pcap_pkthdr *header,
    const u_char *packet
);
pcap_t *handle; /*PCAP handle*/

int cnt = 0;

char* pkt_buffer[256][NUM_DATA_PACKETS + NUM_PARITY_PACKETS]; /*Global pkt buffer*/

int Default_erase_list[FEC_MAX_N] = {0, 2, 4, FEC_MAX_N};


void* capturePackets(char* deviceToCapture);
bool is_all_pkts_recieved_for_block(int blockId);
int get_packet_index_in_blk(char* packet);
int get_block_index_of_pkt(char* packet);
void invalidate_block_in_pkt_buffer(int blockId);
int get_payload_length_for_pkt(char* packet);
unsigned char* get_payload_start_for_packet(char* packet);
void fec_blk_get(fec_blk p, fec_sym k, fec_sym h, int c, int seed, fec_sym o, int blockId);
void call_fec_blk_get(int blockId);
void simulate_packet_loss();
void encode_block();
void decode_block();
void print_global_fb_block();
int copy_parity_packets_to_pkt_buffer(int blockId);
void free_parity_memory(char* packet);
int get_total_packet_size(char* packet);
u_short compute_csum(struct sniff_ip *ip , int len);
void modify_IP_headers_for_parity_packets(int payloadSize, char* packet);


/**
 * @brief      Initialize packet capture
 *
 * @param      deviceToCapture  The device to capture
 *
 * @return
 */
void* capturePackets(char* deviceToCapture) {
	char *device;
	char error_buffer[PCAP_ERRBUF_SIZE];
	device = deviceToCapture;
	printf("Capturing packets on %s\n", device );
	/* Open device for live capture */
	handle = pcap_open_live(
	             device,
	             BUFSIZ,
	             1, /*set device to promiscous*/
	             0, /*Timeout of 0*/
	             error_buffer
	         );
	if (handle == NULL) {
		fprintf(stderr, "Could not open device %s: %s\n", device, error_buffer);
		return NULL;
	}

	printf("This is the start of capture\n");
	pcap_loop(handle, 0, my_packet_handler, NULL);
	printf("Ths is the end of capture\n");
	printf("Completed Capturing packets on %s\n", device );
	return NULL;
}

/**
 * @brief      Gets the block index of packet.
 *
 * @param      packet  The packet
 *
 * @return     The block index of packet.
 */
int get_block_index_of_pkt(const unsigned char* packet) {
	fec_header_t *fecHeader = (fec_header_t *) (packet + SIZE_ETHERNET);
	return fecHeader->blockId;
}

/**
 * @brief      returns the packet Index within a FEC block for the given packet.
 *
 * @param      packet  The packet
 *
 * @return     The packet index in block.
 */
int get_packet_index_in_blk(const unsigned char* packet) {
	fec_header_t *fecHeader = (fec_header_t *) (packet + SIZE_ETHERNET);
	return fecHeader->pktId;
}

/**
 * @brief      packet handler function for pcap
 *
 * @param      args    The arguments
 * @param[in]  header  The header
 * @param[in]  packet  The packet
 */
void my_packet_handler(
    u_char *args,
    const struct pcap_pkthdr *header,
    const u_char *packet
) {

	const struct fec_header *fecHeader;

	int pktId = get_packet_index_in_blk(packet);
	int blockId = get_block_index_of_pkt(packet);

	/*Update the received pkt in the pkt buffer.*/
	if (pkt_buffer[blockId][pktId] == NULL) {
		pkt_buffer[blockId][pktId] = (char* )packet;
	} else { /*This is not good*/
		printf("ERROR: Overwriting existing packet\n");
	}
	printf("The header len is ::::: %d\n", header->len);
	/*check if the block is ready for processing*/
	if (is_all_pkts_recieved_for_block(blockId) == true) {
		/*populate the global fec structure for rse encoder and call the encode.*/
		call_fec_blk_get(blockId);

		/* Encoder */
		encode_block();

		copy_parity_packets_to_pkt_buffer(blockId);

		/* Simulate loss of packets */
		simulate_packet_loss();

		/* Decoder */
		decode_block();

		/*Inject all packets in the block back to the network*/
		for (int i = 0; i < NUM_DATA_PACKETS + NUM_PARITY_PACKETS; i++) {
			char* packetToInject = pkt_buffer[blockId][i];
			size_t outPktLen = get_total_packet_size(packetToInject);
			pcap_inject(handle, packetToInject, outPktLen);
			if (i >= NUM_DATA_PACKETS) {
				free_parity_memory(packetToInject);
			}
		}

		/*Lastly just invalidate the block in the buffer*/
		invalidate_block_in_pkt_buffer(blockId);
	}
	return;
}

void free_parity_memory(char* packet) {
	free(packet);
	return;
}


/**
 * @brief      Wrapper to populate the fec structure.
 *
 * @param[in]  blockId  The block identifier
 */
void call_fec_blk_get(int blockId) {

	int rc;

	/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	fec_sym p[FEC_MAX_N][FEC_MAX_COLS];   /* storage for packets in FEC block (fb) */
	fec_sym k = NUM_DATA_PACKETS; /*TODO: change to macro*/
	fec_sym h = NUM_PARITY_PACKETS; /*TODO: change to macro*/
	fec_sym o = 0;
	fec_sym c = 2;
	fec_sym s = 3;
	/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

	fec_blk_get(p, k, h, c, s, o, blockId);
}

/**
 * @brief      Wrapper to invoke encoder
 */
void encode_block() {
	int rc;
	if ((rc = rse_code(1)) != 0 )  exit(rc);
	fprintf(stderr, "\nSending ");
	D0(fec_block_print());
	// print_global_fb_block();
}

/**
 * @brief      wrapper to simulate packet loss.
 */
void simulate_packet_loss() {
	int e_list[FEC_MAX_N];
	int list_done = (int) FEC_MAX_N;
	e_list[0] = list_done;
	int i;
	/* If no erasure input indices input, then use defaults */
	if ( e_list[0] == list_done) {
		for (i = 0; Default_erase_list[i] != list_done; i++) {
			e_list[i] = Default_erase_list[i];      /* copy default values */
		}
	}
	e_list[i] = list_done; /* put list_done marker at end of input */

	/* Erasure Channel */
	fec_block_delete(e_list);
	fprintf(stderr, "\nReceived ");
	D0(fec_block_print());
}

/**
 * @brief      Wrapper to invoke the decoder
 */
void decode_block() {
	int rc;
	if ((rc = rse_code(1)) != 0 )  exit(rc);
	fprintf(stderr, "\nRecovered ");
	D0(fec_block_print());
}

/**
 * @brief      returns if all packets for a given block are received or not
 *
 * @param[in]  blockId  The block identifier
 *
 * @return     True if all packets recieved for block, False otherwise.
 */
bool is_all_pkts_recieved_for_block(int blockId) {
	int blockSize = NUM_PARITY_PACKETS + NUM_DATA_PACKETS;
	for (int i = 0; i < blockSize; i++) {
		if (pkt_buffer[blockId][i] == NULL) {
			return false;
		}
	}
	return true;
}

/**
 * @brief      Invalidates the given block in the buffer.
 *
 * @param[in]  blockId  The block identifier
 */
void invalidate_block_in_pkt_buffer(int blockId) {
	int blockSize = NUM_PARITY_PACKETS + NUM_DATA_PACKETS;
	for (int i = 0; i < blockSize; i++) { /*TODO: replace 6 with a macro*/
		pkt_buffer[blockId][i] = NULL;
	}
	return;
}

void print_global_fb_block() {
	for (int i = 0; i < fb.block_N; i++) {
		printf("The length of %d packet is %d\n", i, fb.plen[i]);
	}
}


/*
 * Create Random Data and Blank Parity packets and link to the FEC block (fb)
 */
void fec_blk_get(fec_blk p, fec_sym k, fec_sym h, int c, int seed, fec_sym o, int blockId) {
	// fprintf(stderr, "At the top of fec_blk_get\n");
	fec_sym i, y, z;
	int maxPacketLength = 0;
	fb.block_N = k + h; /*TODO: replace this with a macro later.*/

	/* Put C random symbols into each of the K data packets */
	for (i = 0; i < k; i++) {
		if (i >= FEC_MAX_K) {
			fprintf(stderr, "Number of Requested data packet (%d) > FEC_MAX_K (%d)\n", k, FEC_MAX_K);
			exit (33);
		}

		fec_sym* payloadStart = (fec_sym*) get_payload_start_for_packet(pkt_buffer[blockId][i]);
		int payloadLength = get_payload_length_for_pkt(pkt_buffer[blockId][i]);

		fb.pdata[i] = payloadStart;
		fb.cbi[i] = i;
		fb.plen[i] = payloadLength;

		/*  Keep track of maximum packet length to set the block_C field of FEC structure    */
		if (payloadLength > maxPacketLength) {
			maxPacketLength = payloadLength;
		}
		fb.pstat[i] = FEC_FLAG_KNOWN;

	}


	fb.block_C = maxPacketLength + FEC_EXTRA_COLS;    /* One extra for length symbol */


	/* Leave H Parity packets empty */
	for (i = 0; i < h; i++) {
		if (i >= FEC_MAX_H) {
			fprintf(stderr, "Number of Requested parity packet (%d) > FEC_MAX_H (%d)\n", h, FEC_MAX_H);
			exit (34);
		}
		y = k + i;                                  /* FEC block index */
		printf(" The payloadlength for %d is %d\n", y, get_payload_length_for_pkt(pkt_buffer[blockId][y]));
		z = FEC_MAX_N - o - i - 1;             /* Codeword index */
		fb.pdata[y] = p[y];
		fb.cbi[y] = z;
		fb.plen[y] = fb.block_C;
		fb.pstat[y] = FEC_FLAG_WANTED;
	}

	/* shorten last packet, if not: a) 1 symbol/packet, b) lone packet, c) fixed size */
	if ((c > 1) && (k > 1) && (FEC_EXTRA_COLS > 0)) {
		fb.plen[k - 1] -= 1;
		p[k - 1][0] -= 1;
	}
}


unsigned char* get_payload_start_for_packet(char* packet) {
	/*We need to account for the newly added tag after the ethernet heaader.*/
	const struct sniff_ip *ip;              /* The IP header */

	/* compute ip header offset */
	ip = (struct sniff_ip*)(packet + SIZE_ETHERNET + SIZE_FEC_TAG);
	int sizeIP = IP_HL(ip) * 4;
	if (sizeIP < 20) {
		return NULL;
	}

	/* compute payload offset after IP header */
	unsigned char* payload = (u_char *)(packet + SIZE_ETHERNET + SIZE_FEC_TAG + sizeIP);

	return payload;
}

int get_payload_length_for_pkt(char* packet) {
	/*We need to account for the newly added tag after the ethernet heaader.*/
	const struct sniff_ip *ip;              /* The IP header */

	/* compute ip header offset */
	ip = (struct sniff_ip*)(packet + SIZE_ETHERNET + SIZE_FEC_TAG);
	int sizeIP = IP_HL(ip) * 4;
	if (sizeIP < 20) {
		printf("size0\n");
		return -1;
	}

	int sizePayload = ntohs(ip->ip_len) - (sizeIP);
	return sizePayload;
}

int get_total_packet_size(char* packet) {
	/*We need to account for the newly added tag after the ethernet heaader.*/
	const struct sniff_ip *ip;              /* The IP header */
	const struct sniff_tcp *tcp;            /* The TCP header */

	/* compute ip header offset */
	ip = (struct sniff_ip*)(packet + SIZE_ETHERNET + SIZE_FEC_TAG);
	int sizeIP = IP_HL(ip) * 4;
	if (sizeIP < 20) {
		printf("size0\n");
		return -1;
	}

	/* compute tcp header offset */
	tcp = (struct sniff_tcp*)(packet + SIZE_ETHERNET + SIZE_FEC_TAG + sizeIP);
	int sizeTCP = TH_OFF(tcp) * 4;
	if (sizeTCP < 20) {
		printf("size1\n");
		return -1;
	}

	int sizePayload = ntohs(ip->ip_len) - (sizeIP + sizeTCP);
	int totalSize = SIZE_ETHERNET + SIZE_FEC_TAG + sizeIP + sizeTCP + sizePayload;
	return totalSize;
}

int copy_parity_packets_to_pkt_buffer(int blockId) {
	int startIndexOfParityPacket = 0 + NUM_DATA_PACKETS;
	int sizeOfParityPackets = fb.plen[startIndexOfParityPacket];
	printf("This is inside copy packets \n");
	/*For each parity packet*/
	for (int i = startIndexOfParityPacket; i < (startIndexOfParityPacket + NUM_PARITY_PACKETS); i++) {
		char* packet = pkt_buffer[blockId][i];

		/*We need to account for the newly added tag after the ethernet heaader.*/
		const struct sniff_ip *ip;              /* The IP header */
		const struct sniff_tcp *tcp;            /* The TCP header */

		/* compute ip header offset */
		ip = (struct sniff_ip*)(packet + SIZE_ETHERNET + SIZE_FEC_TAG);
		int sizeIP = IP_HL(ip) * 4;
		if (sizeIP < 20) {
			printf("size0\n");
			return -1;
		}

		/* compute tcp header offset */
		tcp = (struct sniff_tcp*)(packet + SIZE_ETHERNET + SIZE_FEC_TAG + sizeIP);
		int sizeTCP = TH_OFF(tcp) * 4;
		if (sizeTCP < 20) {
			printf("size1\n");
			return -1;
		}

		int totalMallocSize = SIZE_ETHERNET + SIZE_FEC_TAG + sizeIP + sizeTCP + sizeOfParityPackets;
		int totalHeaderSize =  SIZE_ETHERNET + SIZE_FEC_TAG + sizeIP ;

		printf("The totalMallocSize is ::::%d\n", totalMallocSize);

		char* parityPacket = (char *) malloc(totalMallocSize);

		/*update the parity packet in the pkt buffer.*/
		pkt_buffer[blockId][i] = parityPacket;

		/*copy headers from the original packet.*/
		memcpy(parityPacket, packet, totalHeaderSize);

		/*Copy payload from the global fec struct*/
		memcpy(parityPacket + totalHeaderSize, fb.pdata[i], sizeOfParityPackets);

		/*Update the the payload lenght and checksum*/
		modify_IP_headers_for_parity_packets(sizeOfParityPackets, parityPacket);
	}
}

void modify_IP_headers_for_parity_packets(int payloadSize, char* packet) {
	struct sniff_ip *ip;              /* The IP header */

	/* compute ip header offset */
	ip = (struct sniff_ip*)(packet + SIZE_ETHERNET + SIZE_FEC_TAG);
	int sizeIP = IP_HL(ip) * 4;
	if (sizeIP < 20) {
		printf("size0\n");
		return;
	}

	/*TODO: Need to verify this. */
	ip->ip_len = payloadSize + sizeIP;

	/*Compute checksum*/
	ip->ip_sum =  compute_csum(ip, sizeIP);
}

/* Computes the checksum of the IP header. */
u_short compute_csum(struct sniff_ip *ipHeader , int len) {
	long sum = 0;  /* assume 32 bit long, 16 bit short */
	int i = 0;
	unsigned short* ip = (unsigned short*) ipHeader;
	while (len > 1) {
		sum += *ip;
		ip++;
		if (sum & 0x80000000)  /* if high order bit set, fold */
			sum = (sum & 0xFFFF) + (sum >> 16);
		len -= 2;
	}

	if (len)      /* take care of left over byte */
		sum += (unsigned short) * (unsigned char *)ip;

	while (sum >> 16)
		sum = (sum & 0xFFFF) + (sum >> 16);

	return ~sum;
}

int main (int argc, char** argv) {
	char* deviceToCapture;
	int opt = 0;
	int rc;

	/* initialize fec codewords */
	if ((rc = rse_init()) != 0 ) exit(rc);

	SIZE_FEC_TAG = sizeof(fec_header_t);

	while ((opt =  getopt(argc, argv, "i:")) != EOF)
	{
		switch (opt)
		{
		case 'i':
			deviceToCapture = optarg;
			break;
		default:
			printf("\nNot yet defined opt = %d\n", opt);
			abort();
		}
	}
	/* start packet capture on the specified interface.*/
	capturePackets(deviceToCapture);
}