#ifndef __defaults__
#define __defaults__
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct
{
	float	v2t[16],t2v[16];	// volume2talairach, talairach2volume. Talairach is in fact MNI.
	float	c2t[16],t2c[16];	// colin2talairach, talairach2colin. Colin is the typical template.
	char	temp_file[256];
	char	temp_mori_file[256],temp_msph_file[256],temp_mtxr_file[256];
	char	loc_file[256],roi_dir[256],corr_dir[256],pval_dir[256];
	char	sum_file[256],coin_dir[256];
	float	R;
	float	VSIZE;
	int		TSAG,TCOR,TAXI;
	float	TORI[3];
	int		LR,PA,IS;
	int		N;
}GlobalDefaults;

static int defaults(char *d, GlobalDefaults *gd);
static int defaults(char *d, GlobalDefaults *gd)
{
	FILE	*f;
	char	s[256],c[256];	

	f=fopen(d,"r");
    
    if(f==0)
        return 0;
	while(!feof(f))
	{
		s[0]=c[0]='\n';
		fgets(s,255,f);
		sscanf(s,"%s",c);
		
		if(strcmp(c,"template_sag_voxels")==0)
			sscanf(s,"template_sag_voxels %i",&gd->TSAG);
		else
		if(strcmp(c,"template_cor_voxels")==0)
			sscanf(s,"template_cor_voxels %i",&gd->TCOR);
		else
		if(strcmp(c,"template_axi_voxels")==0)
			sscanf(s,"template_axi_voxels %i",&gd->TAXI);
		else
		if(strcmp(c,"template_origin")==0)
		{
			fgets(s,255,f);
			sscanf(s,"%f %f %f",&gd->TORI[0],&gd->TORI[1],&gd->TORI[2]);
		}
		else
		if(strcmp(c,"voxel_size")==0)
			sscanf(s,"voxel_size %f",&gd->VSIZE);
		else
		if(strcmp(c,"experiments")==0)
			sscanf(s,"experiments %i",&gd->N);
	}

	gd->LR=ceil(gd->TSAG/gd->VSIZE);
	gd->PA=ceil(gd->TCOR/gd->VSIZE);
	gd->IS=ceil(gd->TAXI/gd->VSIZE);

	gd->v2t[0]=gd->VSIZE;				gd->v2t[1]=0;						gd->v2t[2]=0;						gd->v2t[3]=0;
	gd->v2t[4]=0;						gd->v2t[5]=gd->VSIZE;				gd->v2t[6]=0;						gd->v2t[7]=0;
	gd->v2t[8]=0;						gd->v2t[9]=0;						gd->v2t[10]=gd->VSIZE;				gd->v2t[11]=0;
	gd->v2t[12]=-gd->TORI[0];			gd->v2t[13]=-gd->TORI[1];			gd->v2t[14]=-gd->TORI[2];			gd->v2t[15]=1;

	gd->t2v[0]=1/gd->VSIZE;				gd->t2v[1]=0;						gd->t2v[2]=0;						gd->t2v[3]=0;
	gd->t2v[4]=0;						gd->t2v[5]=1/gd->VSIZE;				gd->t2v[6]=0;						gd->t2v[7]=0;
	gd->t2v[8]=0;						gd->t2v[9]=0;						gd->t2v[10]=1/gd->VSIZE;			gd->t2v[11]=0;
	gd->t2v[12]=gd->TORI[0]/gd->VSIZE;	gd->t2v[13]=gd->TORI[1]/gd->VSIZE;	gd->t2v[14]=gd->TORI[2]/gd->VSIZE;	gd->t2v[15]=1;

	gd->c2t[0]=1;						gd->c2t[1]=0;						gd->c2t[2]=0;						gd->c2t[3]=0;
	gd->c2t[4]=0;						gd->c2t[5]=1;						gd->c2t[6]=0;						gd->c2t[7]=0;
	gd->c2t[8]=0;						gd->c2t[9]=0;						gd->c2t[10]=1;						gd->c2t[11]=0;
	gd->c2t[12]=-gd->TORI[0];			gd->c2t[13]=-gd->TORI[1];			gd->c2t[14]=-gd->TORI[2];			gd->c2t[15]=1;

	gd->t2c[0]=1;						gd->t2c[1]=0;						gd->t2c[2]=0;						gd->t2c[3]=0;
	gd->t2c[4]=0;						gd->t2c[5]=1;						gd->t2c[6]=0;						gd->t2c[7]=0;
	gd->t2c[8]=0;						gd->t2c[9]=0;						gd->t2c[10]=1;						gd->t2c[11]=0;
	gd->t2c[12]=gd->TORI[0];			gd->t2c[13]=gd->TORI[1];			gd->t2c[14]=gd->TORI[2];			gd->t2c[15]=1;
    
    return 1;
}

#endif