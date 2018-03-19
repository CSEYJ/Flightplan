#include <stdint.h>
#include <ap_cint.h>

#include "Encoder.h"

#define PAYLOAD_SIZE (8192)

#define INPUT_PACKET_SIZE (FEC_ETH_HEADER_SIZE + PAYLOAD_SIZE)
#define FEEDBACK_PACKET_SIZE (INPUT_PACKET_SIZE + FEC_HEADER_SIZE)
#define OUTPUT_PACKET_SIZE (FEC_ETH_HEADER_SIZE + FEC_HEADER_SIZE + INPUT_PACKET_SIZE)
#define BYTES_PER_INPUT_PACKET ((INPUT_PACKET_SIZE + 8 - 1) / 8)
#define BYTES_PER_FEEDBACK_PACKET ((FEEDBACK_PACKET_SIZE + 8 - 1) / 8)
#define BYTES_PER_OUTPUT_PACKET ((OUTPUT_PACKET_SIZE + 8 - 1) / 8)
#define WORDS_PER_OUTPUT_PACKET ((OUTPUT_PACKET_SIZE + 64 - 1) / 64)

#define CONCATENATE_INTERNAL(x, y) x ## y
#define CONCATENATE(x, y) CONCATENATE_INTERNAL(x, y)

typedef CONCATENATE(uint, FEC_OFFSET_WIDTH)       offset_type;
typedef CONCATENATE(uint, FEC_PACKET_INDEX_WIDTH) index_type;
typedef CONCATENATE(uint, FEC_OP_WIDTH)           operation_type;

typedef struct
{
  offset_type    Offset;
  index_type     Index;
  operation_type Operation;
  uint1          Valid;
} tuple_interface;

typedef struct
{
  uint1  Error;
  uint4  Count;
  uint64 Data;
  uint1  End_of_frame;
  uint1  Start_of_frame;
} packet_interface;

static fec_sym parity_buffer[BYTES_PER_INPUT_PACKET][FEC_MAX_H];

void Matrix_multiply_HW(fec_sym Data[FEC_MAX_K], fec_sym Parity[FEC_MAX_H], int k, int h);

void RSE_core(tuple_interface Tuple, packet_interface * Data,
    packet_interface Parity[WORDS_PER_OUTPUT_PACKET])
{
#pragma HLS DATA_PACK variable=Tuple
#pragma HLS DATA_PACK variable=Data
#pragma HLS DATA_PACK variable=Parity
#pragma HLS INTERFACE ap_vld port=Tuple
#pragma HLS INTERFACE ap_fifo port=Data
#pragma HLS INTERFACE ap_hs port=Parity

#pragma HLS ARRAY_PARTITION variable=parity_buffer cyclic factor=8 dim=1
#pragma HLS ARRAY_PARTITION variable=parity_buffer complete dim=2

  if (Tuple.Valid == 0)
  {
    int i = 0;
    while (1)
    {
      Parity[i].Data = Data[i].Data;
      Parity[i].End_of_frame = Data[i].End_of_frame;
      Parity[i].Start_of_frame = Data[i].Start_of_frame;
      Parity[i].Count = Data[i].Count;
      Parity[i].Error = Data[i].Error;

      if (Data[i].End_of_frame)
        break;

      i++;
    }
  }
  else if (Tuple.Operation & FEC_OP_ENCODE_PACKET)
  {
    int i = 0;
    while (1)
    {
#pragma HLS DEPENDENCE variable=parity_buffer inter false
#pragma HLS pipeline
      /*
       * The loop over j should not be necessary, but if I remove it and use an unroll pragma instead,
       * the synthesis tool finds false dependencies between different elements of parity_buffer.  I
       * suspect that the compiler tries to save loads and stores by combining loads/stores to adjacent
       * elements.  If I set an HLS dependency pragma to resolve it, the tool fails because it perceives
       * the dependencies as real dependencies.  By separating the loops, we do not flag the new
       * dependencies caused by unrolling as false dependencies.
       */
      uint64 Word = Data[i].Data;
      for (int j = 0; j < 8; j++)
      {
        if (8 * i + j < BYTES_PER_INPUT_PACKET)
        {
          fec_sym Symbol = (Word >> 8 * (7 - j)) & 0xFF;
          Incremental_encode(Symbol, parity_buffer[8 * i + j], Tuple.Index, FEC_MAX_H,
              Tuple.Operation & FEC_OP_START_ENCODER);
        }
      }

      Parity[i].Data = Data[i].Data;
      Parity[i].End_of_frame = Data[i].End_of_frame;
      Parity[i].Start_of_frame = Data[i].Start_of_frame;
      Parity[i].Count = Data[i].Count;
      Parity[i].Error = Data[i].Error;

      if (Data[i].End_of_frame)
        break;

      i++;
    }
  }
  else
  {
    int Input_finished = 0;
    for (int i = 0; i < WORDS_PER_OUTPUT_PACKET; i++)
    {
#pragma HLS DEPENDENCE variable=parity_buffer inter false
#pragma HLS pipeline

      packet_interface Input;
      uint64 Header_word = 0;
      if (!Input_finished)
        Input = Data[i];

      Header_word = Input.Data;
      Input_finished = Input.End_of_frame;

      uint64 Output_word = 0;
      for (int j = 0; j < 8; j++)
      {
        Output_word <<= 8;
        if (64 * i + 8 * j < FEC_ETH_HEADER_SIZE + FEC_HEADER_SIZE)
        {
          Output_word |= (Header_word >> 8 * j) & 0xFF;
        }
        else if (8 * i + j < BYTES_PER_OUTPUT_PACKET)
        {
          int Position = 8 * i + j - (FEC_ETH_HEADER_SIZE + FEC_HEADER_SIZE + 7) / 8;
          Output_word |= parity_buffer[Position][Tuple.Index - FEC_MAX_K] & 0xFF;
        }
      }

      int Last_word = (i == WORDS_PER_OUTPUT_PACKET - 1);

      Parity[i].Data = Output_word;
      Parity[i].Start_of_frame = (i == 0);
      Parity[i].End_of_frame = Last_word;
      Parity[i].Count = Last_word ? 8 - (8 * WORDS_PER_OUTPUT_PACKET - BYTES_PER_OUTPUT_PACKET) : 8;
      Parity[i].Error = 0;
    }
  }
}
