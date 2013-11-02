/*
 *  fdr.h
 *  ac_explorer
 *
 *  Created by rOBERTO tORO on 16/06/2007.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

// FDR, based on FDR.m 1.3 by Tom Nichols 02/01/18
// http://www.sph.umich.edu/~nichols/FDR/

#include <stdio.h>
#include <stdlib.h>

float fdr_independent(float *p, int n, float q);
float fdr_nonparametric(float *p, int n, float q);