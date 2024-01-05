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
 
 #include "cost_parse.h"
 
 
// load an image and encode it with the strange vertical RLE
static int cost_pic_load(cost_pic_t* pic,char* file) {  
  scc_img_t* img = scc_img_open(file);
  int color,rep,shr,max_rep,x,y;

  if(!img) return 0;

  if(img->ncol != pal_size)
    printf("Warning, image %s doesn't have the same number of colors as the palette: %d != %d.\n",file,img->ncol,pal_size);

  pic->width = img->w;
  pic->height = img->h;

  // encode the pic
  // alloc enouth mem for the worst case
  pic->data = malloc(img->w*img->h);

  // set the params
  switch(pal_size) {
  case 16:
    shr = 4;
    max_rep = 0x0F;
    break;
  case 32:
    shr = 3;
    max_rep = 0x07;
    break;
  default:
    scc_log(LOG_ERR,"Palette needs to have 16 or 32 colors!\n");
    return 0;
  }

  // take the initial color
  color = img->data[0];
  if(color >= pal_size) color = pal_size-1;
  rep = 0;
  for(x = 0 ; x < img->w ; x++)
    for(y = 0 ; y < img->h ; y++) {
      if(rep < 255 && // can repeat ??
         img->data[y*img->w+x] == color) {
        rep++;
        continue;
      }
      // write the repetition
      if(rep > max_rep) {
        pic->data[pic->data_size] = (color << shr);
        pic->data_size++;
        pic->data[pic->data_size] = rep;
        pic->data_size++;
      } else {
        pic->data[pic->data_size] = (color << shr) | rep;
        pic->data_size++;
      }

      color = img->data[y*img->w+x];
      if(color >= pal_size) color = pal_size-1;
      rep = 1;
    }
  // write the last repetition
  if(rep > 0) {
    if(rep > max_rep) {
      pic->data[pic->data_size] = (color << shr);
      pic->data_size++;
      pic->data[pic->data_size] = rep;
      pic->data_size++;
    } else {
      pic->data[pic->data_size] = (color << shr) | rep;
      pic->data_size++;
    }
  }

  if(pic->data_size < img->w*img->h)
    pic->data = realloc(pic->data,pic->data_size);

  scc_img_free(img);
  return 1;
}

// compute the whole size of the costume
static int cost_get_size(int *na,unsigned* coff,unsigned* aoff,unsigned* loff) {
  cost_pic_t* p;
  int i,j,num_anim,clen = 0;
  int size = 4 + // size
    2 + // header
    1 + // num anim
    1 + // format
    pal_size + // palette
    2 + // cmds offset
    2*16; // limbs offset
    
  // get the highest anim id
  for(i = COST_MAX_ANIMS-1 ; i >= 0 ; i--)
    if(anims[i].name) break;
  num_anim = i+1;

  size += 2*COST_MAX_DIR*num_anim; // anim offsets

  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++) {
    cost_anim_dir_t* anim = &anims[i/COST_MAX_DIR].dir[i%COST_MAX_DIR];
    if(aoff) {
      if(anim->limb_mask)
        aoff[i] = size-clen;
      else
        aoff[i] = 0;
    }
    size += 2; // limb mask
    if(!anim->limb_mask) continue;
    for(j = COST_MAX_LIMBS-1 ; j >= 0 ; j--) {
      if(!(anim->limb_mask & (1 << j))) continue;
      if(anim->limb[j].len) {
        size += 2 + 1 + anim->limb[j].len; // limb start/len + cmds
        clen += anim->limb[j].len;
      } else
        size += 2;
    }
  }
  if(coff) coff[0] = size-clen;

  // limbs table
  for(i = COST_MAX_LIMBS-1 ; i >= 0 ; i--) {
    if(loff) {
      if(limbs[i].num_pic > 0)
        loff[i] = size;
      else
        loff[i] = 0;
    }
    size += 2*limbs[i].num_pic;
  }
    
  // pictures
  //  for(p = pic_list ; p ; p = p->next)
  for(i = COST_MAX_LIMBS-1 ; i >= 0 ; i--) // pictures
    for(j = 0 ; j < limbs[i].num_pic ; j++) {
      if(!(p = limbs[i].pic[j])) continue;
      if(p->ref && !p->offset) {
        p->offset = size;
        size += p->data_size + 6*2;
      }
    }

  na[0] = num_anim;
  return size;
}

// Get the id of a picture inside a limb.
// If the picture is not present in the limb it is added to it.
static int cost_get_pic_limb_id(int limb_n, cost_pic_t* pic) {
  cost_limb_t* limb = &limbs[limb_n];
  int n;
  for(n = 0 ; n < limb->num_pic ; n++)
    if(limb->pic[n] == pic) break;
  if(n < limb->num_pic) return n;
  if(n+1 >= LIMB_MAX_PICTURES) {
      printf("Too many pictures in limb %d (max %d)\n",
             limb_n,LIMB_MAX_PICTURES);
      return -1;
  }
  limb->pic[n] = pic;
  limb->num_pic++;
  return n;
}

static int cost_create_limbs(void) {
  int a,d,l;
  for(a = 0 ; a < COST_MAX_ANIMS ; a++) {
    if(!anims[a].name) continue;
    for(d = 0 ; d < COST_MAX_DIR ; d++) {
      for(l = 0 ; l < COST_MAX_LIMBS ; l++) {
        cost_limb_anim_t* anim = &anims[a].dir[d].limb[l];
        cost_cmd_t* cmd = anim->cmd_list;
        int id;
        anim->len = 0;
        while(cmd) {
          if(anim->len+1 > COST_MAX_LIMB_CMDS) goto too_many_cmd;
          switch(cmd->type) {
          case COST_CMD_DISPLAY:
            if((id = cost_get_pic_limb_id(l,cmd->arg[0].pic)) < 0)
              return -1;
            anim->cmd[anim->len] = id;              anim->len++;
            break;
          case COST_CMD_HIDE:
          case COST_CMD_SHOW:
          case COST_CMD_NOP:
          case COST_CMD_COUNT:
            anim->cmd[anim->len] = cmd->type;       anim->len++;
            break;
          case COST_CMD_SOUND:
            if(anim->len+2 > COST_MAX_LIMB_CMDS) goto too_many_cmd;
            anim->cmd[anim->len] = cmd->type;       anim->len++;
            anim->cmd[anim->len] = cmd->arg[0].i;   anim->len++;
            break;
          }
          cmd = cmd->next;
        }
      }
    }
  }
  return 0;
 too_many_cmd:
  printf("Too many commands in limb %d (max %d)\n",l,COST_MAX_LIMB_CMDS);
  return -1;
}

static int cost_write(scc_fd_t* fd) {
  int size,num_anim,i,j,pad = 0;
  cost_pic_t* p;
  uint8_t fmt = 0x58 | cost_flags;
  unsigned coff,cpos = 0;
  unsigned aoff[COST_MAX_ANIMS*COST_MAX_DIR];
  unsigned loff[COST_MAX_LIMBS];

  if(cost_create_limbs()) return -1;

  if(pal_size == 32) fmt |= 1;

  size = cost_get_size(&num_anim,&coff,aoff,loff);

  // round up to next 2 multiple
  if(size & 1) {
    size++;
    pad = 1;
  }

  scc_fd_w32(fd,MKID('C','O','S','T'));
  scc_fd_w32be(fd,size+8);


  scc_fd_w32le(fd,size);  // size

  scc_fd_w8(fd,'C'); // header
  scc_fd_w8(fd,'O');

  scc_fd_w8(fd,num_anim*COST_MAX_DIR-1); // last anim

  scc_fd_w8(fd,fmt); // format

  scc_fd_write(fd,pal,pal_size); // palette

  scc_fd_w16le(fd,coff); // cmd offset

  for(i = COST_MAX_LIMBS-1 ; i >= 0 ; i--) // limbs offset
    scc_fd_w16le(fd,loff[i]);

  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++) // anim offsets
    scc_fd_w16le(fd,aoff[i]);

  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++) { // anims
    cost_anim_dir_t* anim = &anims[i/COST_MAX_DIR].dir[i%COST_MAX_DIR];
    scc_fd_w16le(fd,anim->limb_mask); // limb mask
    if(!anim->limb_mask) continue;
    for(j = COST_MAX_LIMBS-1 ; j >= 0 ; j--) {
      if(!(anim->limb_mask & (1 << j))) continue;
      if(anim->limb[j].len) {
        scc_fd_w16le(fd,cpos);  // cmd start
        cpos += anim->limb[j].len;
        // last cmd offset
        scc_fd_w8(fd,((anim->limb[j].len-1)&0x7F) |
                    (anim->limb[j].flags&0x80));
      } else
        scc_fd_w16le(fd,0xFFFF); // stoped limb
    }
  }

  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++) { // anim cmds
    cost_anim_dir_t* anim = &anims[i/COST_MAX_DIR].dir[i%COST_MAX_DIR];
    for(j = COST_MAX_LIMBS-1 ; j >= 0 ; j--) {
      if(!anim->limb[j].len ) continue;
      scc_fd_write(fd,anim->limb[j].cmd,anim->limb[j].len);
    }
  }

  for(i = COST_MAX_LIMBS-1 ; i >= 0 ; i--)  // limbs
    for(j = 0 ; j < limbs[i].num_pic ; j++) {
      if(limbs[i].pic[j]) scc_fd_w16le(fd,limbs[i].pic[j]->offset);
      else scc_fd_w16le(fd,0);
    }

  // i would prefer to just go along the list,
  // but that should give results closer to the original.
  for(i = COST_MAX_LIMBS-1 ; i >= 0 ; i--) // pictures
    for(j = 0 ; j < limbs[i].num_pic ; j++) {
      if(!(p = limbs[i].pic[j])) continue;
      if(!p->ref) continue;
      if(!p->width || !p->height) printf("Bad pic?\n");
      //printf("Write pic: %dx%d\n",p->width,p->height);
      scc_fd_w16le(fd,p->width);
      scc_fd_w16le(fd,p->height);
      scc_fd_w16le(fd,p->rel_x);
      scc_fd_w16le(fd,p->rel_y);
      scc_fd_w16le(fd,p->move_x);
      scc_fd_w16le(fd,p->move_y);
      scc_fd_write(fd,p->data,p->data_size);
      p->ref = 0;
    }

  if(pad) scc_fd_w8(fd,0);

  return 1;
}


static int akos_write(scc_fd_t* fd) {
  int akhd_size = 8 + 2 + 1 + 1 + 2 + 2 + 2;
  int akpl_size = 8 + pal_size;
  int aksq_size = 8;
  int akch_size = 8;
  int akof_size = 8;
  int akci_size = 8;
  int akcd_size = 8;
  int akos_size;
  int i,j,d;
  int cpos = 0;
  int aoff[COST_MAX_DIR*COST_MAX_ANIMS];
  cost_pic_t* pic;
  int num_anim = 0, num_pic = 0;
  int data_off = 0, header_off = 0;


  // get the highest anim id
  for(i = COST_MAX_ANIMS-1 ; i >= 0 ; i--)
    if(anims[i].name) break;
  num_anim = i+1;

  // Compute the number of picture and setup the ids
  for(pic = pic_list ; pic ; pic = pic->next) {
    if(!pic->ref) continue;
    pic->idx = num_pic;
    num_pic++;
  }

  // Generate the command sequence
  for(i = 0 ; i < num_anim ; i++)
    for(d = 0 ; d < COST_MAX_DIR ; d++)
      for(j = COST_MAX_LIMBS-1 ; j >= 0 ; j--) {
        cost_limb_anim_t* anim = &anims[i].dir[d].limb[j];
        cost_cmd_t* cmd = anim->cmd_list;
        anim->len = 0;
        while(cmd) {
          switch(cmd->type) {
          case COST_CMD_DISPLAY:
            anim->cmd[anim->len] = cmd->arg[0].pic->idx;
            anim->len++;
            break;
          }
          cmd = cmd->next;
        }
        aksq_size += anim->len;
      }

  // Compute the size needed for the anim definitions
  akch_size += 2*COST_MAX_DIR*num_anim;
  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++) {
    cost_anim_dir_t* anim = &anims[i/COST_MAX_DIR].dir[i%COST_MAX_DIR];
    if(!anim->limb_mask) {
      aoff[i] = 0;
      continue;
    }
    aoff[i] = akch_size-8;
    akch_size += 2;
    for(j = COST_MAX_LIMBS-1 ; j >= 0 ; j--) {
      if(!(anim->limb_mask & (1 << j))) continue;
      akch_size += 1 + 2 + 2;
    }
  }

  akof_size += (4 + 2)*num_pic;

  akci_size += (2+2 + 2+2 + 2+2)*num_pic;

  // Compute the size needed for the picture data
  for(pic = pic_list ; pic ; pic = pic->next) {
    if(!pic->ref) continue;
    akcd_size += pic->data_size;
  }

  akos_size = 8 + akhd_size + akpl_size + aksq_size +
    akch_size + akof_size + akci_size + akcd_size;

  scc_fd_w32(fd,MKID('A','K','O','S'));
  scc_fd_w32be(fd,akos_size);

  // Write the header
  scc_fd_w32(fd,MKID('A','K','H','D'));
  scc_fd_w32be(fd,akhd_size);
  // Version ?
  scc_fd_w16le(fd,0x0001);
  // Flags
  scc_fd_w8(fd,cost_flags>>7);
  // Unknown
  scc_fd_w8(fd,0x80);
  // Num anim
  scc_fd_w16le(fd,num_anim*COST_MAX_DIR);
  // Num frame
  scc_fd_w16le(fd,num_pic);
  // Codec
  scc_fd_w16le(fd,1);

  // Write the palette
  scc_fd_w32(fd,MKID('A','K','P','L'));
  scc_fd_w32be(fd,akpl_size);
  scc_fd_write(fd,pal,pal_size);

  // Write the commands
  scc_fd_w32(fd,MKID('A','K','S','Q'));
  scc_fd_w32be(fd,aksq_size);
  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++) {
    cost_anim_dir_t* anim = &anims[i/COST_MAX_DIR].dir[i%COST_MAX_DIR];
    for(j = COST_MAX_LIMBS-1 ; j >= 0 ; j--) {
      if(anim->limb[j].len > 0)
        scc_fd_write(fd,anim->limb[j].cmd,anim->limb[j].len);
    }
  }

  // Write the anims
  scc_fd_w32(fd,MKID('A','K','C','H'));
  scc_fd_w32be(fd,akch_size);
  // offsets
  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++)
    scc_fd_w16le(fd,aoff[i]);
  // definitions
  for(i = 0 ; i < num_anim*COST_MAX_DIR ; i++) {
    cost_anim_dir_t* anim = &anims[i/COST_MAX_DIR].dir[i%COST_MAX_DIR];
    if(!anim->limb_mask) continue;
    // limb mask
    scc_fd_w16le(fd,anim->limb_mask);
    for(j = COST_MAX_LIMBS-1 ; j >= 0 ; j--) {
      if(!(anim->limb_mask & (1 << j))) continue;
      // mode
      scc_fd_w8(fd,(anim->limb[j].flags&0x80) ? 0x03 : 0x02);
      // cmd start
      scc_fd_w16le(fd,cpos);
      cpos += anim->limb[j].len;
      // len
      scc_fd_w16le(fd,anim->limb[j].len-1);
    }
  }

  // Write the offset table
  scc_fd_w32(fd,MKID('A','K','O','F'));
  scc_fd_w32be(fd,akof_size);
  for(pic = pic_list ; pic ; pic = pic->next) {
    if(!pic->ref) continue;
    // Data offset
    scc_fd_w32le(fd,data_off);
    data_off += pic->data_size;
    // Header offset
    scc_fd_w16le(fd,header_off);
    header_off += 2+2 + 2+2 + 2+2;
  }

  // Write the pic headers
  scc_fd_w32(fd,MKID('A','K','C','I'));
  scc_fd_w32be(fd,akci_size);
  for(pic = pic_list ; pic ; pic = pic->next) {
    if(!pic->ref) continue;
    // width / height
    scc_fd_w16le(fd,pic->width);
    scc_fd_w16le(fd,pic->height);
    scc_fd_w16le(fd,pic->rel_x);
    scc_fd_w16le(fd,pic->rel_y);
    scc_fd_w16le(fd,pic->move_x);
    scc_fd_w16le(fd,pic->move_y);
  }

  // Write the pic data
  scc_fd_w32(fd,MKID('A','K','C','D'));
  scc_fd_w32be(fd,akcd_size);
  for(pic = pic_list ; pic ; pic = pic->next) {
    if(!pic->ref) continue;
    scc_fd_write(fd,pic->data,pic->data_size);
  }

  return 1;
}

static int header_write(scc_fd_t* fd,char *prefix) {
  int i;
  scc_fd_printf(fd,"/* This file was generated do not edit */\n\n");
  for(i = 0 ; i < COST_MAX_ANIMS ; i++) {
    if(!anims[i].name) continue;
    scc_fd_printf(fd,"#define %s%s %d\n",prefix,anims[i].name,i);
  }
  return 1;
}

static scc_lex_t* cost_lex;
extern int cost_main_lexer(YYSTYPE *lvalp, YYLTYPE *llocp,scc_lex_t* lex);

static void set_start_pos(YYLTYPE *llocp,int line,int column) {
  llocp->first_line = line+1;
  llocp->first_column = column;
}

static void set_end_pos(YYLTYPE *llocp,int line,int column) {
  llocp->last_line = line+1;
  llocp->last_column = column;
}

int yylex(void) {
  return scc_lex_lex(&yylval,&yylloc,cost_lex);
}

int yyerror (const char *s)  /* Called by yyparse on error */
{
  scc_log(LOG_ERR,"%s: %s\n",scc_lex_get_file(cost_lex),
          cost_lex->error ? cost_lex->error : s);
  return 0;
}

static cost_pic_t* find_pic(char* name) {
	cost_pic_t* p;
	for(p = pic_list ; p ; p = p->next)
		if(!strcmp(name,p->name)) break;
	return p;
}