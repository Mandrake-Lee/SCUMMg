/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2024 Jorge Amorós-Argos
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

#ifndef SCC_SOUND_H
#define SCC_SOUND_H

#include <stdint.h>
/*
The RIFF header!
*/
typedef struct {
	uint32_t ChunkID; //"RIFF"
	uint32_t ChunkSize; //"36 + sizeof(wav_data_t) + data"
	uint32_t Format; // "WAV"
} wav_riff_t;

/*
The FMT header!
*/
typedef struct {
	uint32_t Subchunk1ID; //"fmt "
	uint32_t Subchunk1Size; //16 (PCM)
	uint16_t AudioFormat; // 1 'cause PCM
	uint16_t NumChannels; // mono = 1; stereo = 2
	uint32_t SampleRate; // 8000, 44100, etc.
	uint32_t ByteRate; //== SampleRate * NumChannels * byte
	uint16_t BlockAlign; //== NumChannels * bytePerSample
	uint16_t BytesPerSample; //8 byte = 8, 16 byte = 16, etc.
} wav_fmt_t;

/*
The Data header!
*/
typedef struct {
	uint32_t Subchunk2ID; //"data"
	uint32_t Subchunk2Size; //== NumSamples * NumChannels * bytePerSample/8
} wav_data_t;

/*
The complete header!
*/
typedef struct {
	wav_riff_t Riff;
	wav_fmt_t Fmt;
	wav_data_t Data;
} wav_header_t;

/*
* The sample struct
*/
typedef struct {
	unsigned int Channels;
	unsigned int BytesPerSample;//---size
	unsigned int DataSize;//        |
	void *sampleData; // [chan 1][chan 2][chan 3] ; Pure memory, every channel value needs to be in little endian format
} wav_sample_t;


enum {
	MIDI_FILE=1,
	ADL_FILE,
	ROL_FILE,
	GMD_FILE,
	VOC_FILE,
	SPK_FILE,
	WAVE_FILE,
	AIFF_FILE,
	FLAC_FILE,
};

int scc_sound_gettype(char* path);
int scc_sound_wrapper(char* path, char** dataptr, int filetype, int withheader);
int scc_sound_raw2voc(char* dataraw, unsigned int datasize, int srate, char** vocfile);
int scc_sound_getwavdata(char* wavdata, int* srate, char** ptr, int* length);

#endif