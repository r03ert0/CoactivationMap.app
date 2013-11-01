/*
 *  coactivation.h
 * CoactivationMap
 *
 *  Created by rOBERTO tORO on 15/06/2007.
 *  Copyright 2007 Roberto Toro, Brain & Body Centre. All rights reserved.
 *
 */
#ifndef __coactivation__
#define __coactivation__

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define KMAXPEAKS 50

#define SIGN(x)	(((x)>0)?1:(-1))

#define pi 3.14159265358979323846264338327950288419716939937510

typedef struct
{
	int		a,b,c;
	int		maxk;
	float	maxlr;
}Peak;

float likelihood_ratio(int a, int b, int k, int N);
float phi_correlation(int a, int b, int k, int N);
float mutual_information(int a, int b, int k, int N);
float t_score(int a, int b, int k, int N);
float p_combination(int a, int b, int k, int N);
float gammp(float a,float x);

void discrete_cosine_transform(float *vol, int *dim);

void findpeaks(float threshold, int R, int *co, int *sz, short *sum, short *cvol, int N, Peak *peaks, int *npeaks);
#endif