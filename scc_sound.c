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
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "scc_sound.h"
#include "scc_util.h"
#include "scc_fd.h"

static int read_file(scc_fd_t* fd, char** rdata, unsigned *pos, unsigned *size) {
  char* data = rdata[0];
  int r;
  int bs = 0;
  unsigned s = size[0],p = pos[0];
  while(1) {
    if(p == s) {
      s += 2048;
      data = realloc(data,s);
    }
    r = scc_fd_read(fd,data+p,s-p);
    if(r < 0) {
      printf("Error while reading file.\n");
      bs = 0;
      break;
    } else if(r == 0) break;
    p += r;
    bs += r;
  }
  scc_fd_close(fd);
  rdata[0] = data;
  size[0] = s;
  pos[0] = p;
  return bs;
}

static int load_voc(char* path,char** rdata, unsigned *pos, unsigned *size) {
  scc_fd_t *fd = new_scc_fd(path,O_RDONLY,0);
  int r;
  char data[32];

  if(!fd) {
    printf("Failed to open %s.\n",path);
    return 0;
  }

  r = scc_fd_read(fd,data,26);
  if (r < 0 || data[0] != 'C' || ((data[23]<<8) | data[22]) != 266) {
    printf("Invalid voc file %s  %c [%i].\n", path, data[0], (data[23]<<8) | data[23]);
    return 0;
  }

  // Read the rest of the file to data
  return read_file(fd, rdata, pos, size);
}

static int load_file(char* path,char** rdata, unsigned *pos, unsigned *size) {
  scc_fd_t *fd = new_scc_fd(path,O_RDONLY,0);

  if(!fd) {
    printf("Failed to open %s.\n",path);
    return 0;
  }

  return read_file(fd, rdata, pos, size);
}

//Reads header and returns the sound filetype
int scc_sound_gettype(char* path)
{
	scc_fd_t *fd;
	char data[32];
	
	fd = new_scc_fd(path,O_RDONLY,0);
	if(!fd)
	{
		printf("File not found %s\n", path);
		return -1;
	}
	
	scc_fd_read(fd,data,32);

	if (!strncmp(data, "MThd",4))
		return MIDI_FILE;
	if (!strncmp(data, "Crea",4))
		return VOC_FILE;
	if (!strncmp(data, "RIFF",4) && !strncmp(data+8, "WAVE",4))
		return WAVE_FILE;
	if (!strncmp(data, "FORM",4) && !strncmp(data+8, "AIFF",4))
		return AIFF_FILE;
	
	return -1;
}


//Return soundfile wrapped with tags compatible with SCUMM v6
//We can choose to have SOUN header or not
int scc_sound_wrapper(char* path, char** dataptr, int filetype, int withheader)
{
	char* out;
	scc_fd_t *fd;
	unsigned size = 2048,pos = 0, sizepos;
	char *data;
	int s,ssize = 0,spos,ahpos;

	//Sanity check
	if (!dataptr)
		return -1;

	data = malloc(size);
	if (!data)
		return -1;
	
	if (withheader)
	{
		SCC_SET_32(data,pos,MKID('S','O','U','N'));
		pos +=8;
		ssize +=8;
	}

	if(filetype == MIDI_FILE)
	{
		SCC_SET_32(data,pos,MKID('M','I','D','I'));
		pos += 8;
		sizepos = pos-4;
		if(!(s = load_file(path,&data,&pos,&size))) return -1;
		SCC_SET_32BE(data,sizepos,s + 8);
		ssize += s+8;
	}
	else
	{
		SCC_SET_32(data,pos,MKID('S','O','U',' '));
		pos += 8;
		sizepos = pos-4;

		switch(filetype)
		{
			case ADL_FILE:
					SCC_SET_32(data,pos,MKID('A','D','L',' '));
					spos = pos + 4;
					pos += 8;
					if(!(s = load_file(path,&data,&pos,&size))) return 1;
					SCC_SET_32BE(data,spos,s + 8);
					ssize += s + 8;
					break;
			
			case ROL_FILE:
					SCC_SET_32(data,pos,MKID('R','O','L',' '));
					spos = pos + 4;
					pos += 8;
					if(!(s = load_file(path,&data,&pos,&size))) return 1;
					SCC_SET_32BE(data,spos,s + 8);
					ssize += s + 8;
					break;

			case GMD_FILE:
					SCC_SET_32(data,pos,MKID('G','M','D',' '));
					spos = pos + 4;
					pos += 8;
					if(!(s = load_file(path,&data,&pos,&size))) return 1;
					SCC_SET_32BE(data,spos,s + 8);
					ssize += s + 8;
					break;

			case VOC_FILE:
					SCC_SET_32(data,pos,MKID('S','B','L',' '));
					spos = pos + 4;
					pos += 8; // hdr+block size
					SCC_SET_32(data,pos,MKID('A','U','h','d'));
					SCC_SET_32BE(data,pos+4,3);
					pos += 8; // ahdr+block size
					data[pos] = 0x00;
					data[pos+1] = 0x00;
					data[pos+2] = 0x80;
					pos += 3;
					SCC_SET_32(data,pos,MKID('A','U','d','t'));
					ahpos = pos + 4;
					pos += 8; // ahdr+block size

					if(!(s = load_voc(path,&data,&pos,&size))) return 1;

					SCC_SET_32BE(data,spos,s + 8 + 8 + 8 + 3);
					SCC_SET_32BE(data,ahpos,s + 8);

					ssize += s + 8 + 8 + 8 + 3;
					break;

			case SPK_FILE:
					SCC_SET_32(data,pos,MKID('S','P','K',' '));
					spos = pos + 4;
					pos += 8;
					if(!(s = load_file(path,&data,&pos,&size))) return 1;
					SCC_SET_32BE(data,spos,s + 8);
					ssize += s + 8;
					break;
			default:
		}
		SCC_SET_32BE(data,sizepos,ssize + 8);	
	}

	if (withheader)
		SCC_SET_32BE(data,4,pos);

	*dataptr = data;
	return ssize;
}


//WARNING! Because of VOC & SPUTM6 limitations, rawdata must be 8bit mono
int scc_sound_raw2voc(char* dataraw, unsigned int datasize, int srate, char** vocfile)
{
	unsigned dlen = 26 + 1 + 3 + 2;
	char* data;
	int r,blen;

	*vocfile = NULL;
	
	data = malloc(datasize + dlen);

	if(!data)
		return -1;

	// write the voc header
	memcpy(data,"Creative Voice File",19);
	data[19] = 0x1A; // eof
	data[20] = 0x1A; // header size
	data[21] = 0;
	data[22] = 0x0A; // version
	data[23] = 0x01;
	data[24] = 0x29; // magic number
	data[25] = 0x11;

	// write the header of the first block
	blen = dlen - 30;
	data[26] = 0x01;                 // block type
	data[27] = blen & 0xFF;          // block size
	data[28] = (blen >> 8) & 0xFF;
	data[29] = (blen >> 16) & 0xFF;

	data[30] = 256-(1000000/srate);  // sample rate
	data[31] = 0;                    // packing

	memcpy(data+31, dataraw, datasize);
	data[datasize+dlen-1] = 0x0;		//Terminator byte

	*vocfile = data;
	
	return datasize+dlen;
}

//Returns position of data in ptr and also size of data
int scc_sound_getwavdata(char* wavdata, int* srate, char** ptr, int* length)
{
	wav_header_t *wav;
	int size;
	
	//Sanity
	if (!wavdata)
		return -1;
	
	wav = (wav_header_t*) wavdata;
	
	//Some verifications
	if( SCC_GET_32(&wav->Riff.ChunkID,0) != MKID('R','I','F','F'))
		return -2;
	if( SCC_GET_32(&wav->Riff.Format,0) != MKID('W','A','V','E'))
		return -3;	
	if( SCC_GET_16LE(&wav->Fmt.AudioFormat, 0) != 1)	//Must be PCM
		return -4;
	if (SCC_GET_16LE(&wav->Fmt.NumChannels, 0) != 1)	//Must be mono
		return -5;
	if (SCC_GET_16LE(&wav->Fmt.BytesPerSample, 0) != 8)	//Must be 8bits/sample
		return -6;
	
	//Results
	*srate = SCC_GET_32LE(&wav->Fmt.SampleRate, 0);
	*length = SCC_GET_32LE(&wav->Data.Subchunk2Size, 0);
	*ptr = wavdata + sizeof(wav_header_t);
	
	return 0;
}