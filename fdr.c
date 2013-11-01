/*
 *  fdr.c
 *  ac_explorer
 *
 *  Created by rOBERTO tORO on 16/06/2007.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#include "fdr.h"

float fdr_id(float *p, int n, float q)
{
	float	coef=q/(float)n;
	int		i;
	
	for(i=n-1;i>=0;i--)
		if(p[i]<(i+1)*coef)
			break;
	
	return p[i];
}
float fdr_n(float *p, int n, float q)
{
	float	cVN,coef;
	int		i;
	
	cVN=0;
	for(i=1;i<=n;i++)
		cVN+=1/(float)i;
	coef=q/(cVN*n);
	
	for(i=n-1;i>=0;i--)
		if(p[i]<(i+1)*coef)
			break;
	
	if(i>=0)
		return p[i];
	else
		return 0;
}
int compare(const void *a, const void *b)
{

	float x=*(float*)a;
	float y=*(float*)b;
	
	if(x>y)
		return 1;
	if(x<y)
		return -1;
	else
		return 0;
}
float fdr_independent(float *p, int n, float q)
{
	qsort(p,n,sizeof(float),compare);

	return fdr_id(p,n,q);
}
float fdr_nonparametric(float *p, int n, float q)
{
	qsort(p,n,sizeof(float),compare);

	return fdr_n(p,n,q);
}