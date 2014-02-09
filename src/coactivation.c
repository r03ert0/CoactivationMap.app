/*
 *  coactivation.c
 *  ac_explorer
 *
 *  Created by rOBERTO tORO on 15/06/2007.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#include "coactivation.h"

#pragma mark -
float likelihood_ratio(int a, int b, int k, int N)
{
	// H1 = p(b|a)=p(b|-a)=p
	// H2 = p(b|a)=p1 � p2=p(b|-a)
	// lr=-2log(L(H1)/L(H2)), where L(H) is the likelihood of H
	
	if(a==0 || b==0)
		return 0;

	double	p=b/(double)N;
	double	p1=k/(double)a;
	double	p2=(b-k)/(double)(N-a);
	double	lr,e=0.0001;

	lr=(-k*log(e+p ) - (a-k)*log(e+1-p ) - (b-k)*log(e+p ) - (N-a-b+k)*log(e+1-p )
		+k*log(e+p1) + (a-k)*log(e+1-p1) + (b-k)*log(e+p2) + (N-a-b+k)*log(e+1-p2))*2;

	if(lr!=lr)
	{
		printf("NaN for a:%i b:%i k:%i\n",a,b,k);
	}
	return lr;
}
#pragma mark -
float phi_correlation(int a, int b, int k, int N)
{
	float	num,den,r;
	
	if(a==0 || b==0)
		return 0;

	num=pow((N*k)/(a*b)-1,2);
	den=((N-a)*(N-b))/(a*b);
	r=sqrt(num/den)*SIGN(N*k-a*b);
	
	return r;
}
#pragma mark -
float mutual_information(int a, int b, int k, int N)
{
	if(a==0 || b==0)
		return 0;

	double	mi;
	mi=log(k/(double)N)-log(a/(double)N)-log(b/(double)N);
	return mi;
}
#pragma mark -
float t_score(int a, int b, int k, int N)
{
	if(a==0 || b==0)
		return 0;

	double	p1=k/(double)a;
	double	p2=(b-k)/(double)(N-a);
	double	var1=pow(p1,k)*pow(1-p1,a-k);
	double	var2=pow(p2,b-k)*pow(1-p2,N-a-b+k);
	double	t;
	
	t=(p1-p2)/sqrt(var1/(double)a+var2/(double)(N-a));
	
	return t;
}
#pragma mark -
double gammln(double xx)
// Returns the value ln[Œì(xx)] for xx>0.
{
	//Internal arithmetic will be done in double precision, a nicety that you can omit if
	//five-figure accuracy is good enough.
	double x,y,tmp,ser;
	static double cof[6]={  76.18009172947146,-86.50532032941677,
							24.01409824083091,-1.231739572450155,
							0.1208650973866179e-2,-0.5395239384953e-5};
	int j;
	
	y=x=xx;
	tmp=x+5.5;
	tmp -= (x+0.5)*log(tmp);
	ser=1.000000000190015;
	for (j=0;j<=5;j++) ser += cof[j]/++y;
	return -tmp+log(2.5066282746310005*ser/x);
}
double factln(int n)
// Returns ln(n!).
{
	static double a[101]; // A static array is automatically initialized to zero.
	if(n<=1) return 0.0;
	if(n<=100) return a[n]?a[n]:(a[n]=gammln(n+1.0)); // In range of table.
	else return gammln(n+1.0); //Out of rangeof table.
}
double probability(int a, int b, int i, int n)
// Returns the probability of observing i co-ocurrences in two
// sequences of length n containing a and b activations respectively
{
	double vnum=factln(a)+factln(n-a)+factln(b)+factln(n-b);
	double vden=factln(n)+factln(i)+factln(a-i)+factln(b-i)+factln(n-a-b+i);
	return exp(vnum-vden);
}
float p_combination(int a, int b, int k, int n)
// Returns the probability of observing k coactivations or more
{
    int		i,tmp;
	float	s,v;
	
	if(a<b)
	{
		tmp=a; a=b; b=tmp;
	}
	
	s=0;
	for(i=k;i<=b;i++)
	{
		v=probability(a,b,i,n);
		s+=v;
	}
	return pow(1-s,8);
}
#pragma mark -
#define ITMAX 100 
#define EPS 3.0e-7
#define FPMIN 1.0e-30
void gser(float *gamser,float a,float x,float *gln) 
// Returns the incomplete gamma function P(a,x) evaluated by its series representation as gamser. 
// Also returns ln Gamma(a) as gln. 
{ 
	int		n; 
	float	sum,del,ap; 
	
	*gln=gammln(a); 
	if(x<=0.0)
	{ 
		if(x<0.0)
			printf("x less than 0 in routine gser\n"); 
		*gamser=0.0; 
		return; 
	}
	else
	{ 
		ap=a; 
		del=sum=1.0/a; 
		for(n=1;n<=ITMAX;n++)
		{ 
			++ap; 
			del*=x/ap; 
			sum+=del; 
			if(fabs(del)< fabs(sum)*EPS)
			{ 
				*gamser=sum*exp(-x+a*log(x)-(*gln)); 
				return; 
			} 
		} 
		printf("a too large,ITMAX too small in routine gser\n"); 
		return; 
	} 
}

void gcf(float *gammcf,float a,float x,float *gln) 
// Returns the incomplete gamma function Q(a,x) evaluated by its continued fraction represen- 
// tation as gammcf. Also returns ln Gamma(a) as gln. 
{ 
	int		i; 
	float	an,b,c,d,del,h; 
	
	*gln=gammln(a); 
	b=x+1.0-a; // Setup for evaluating continued fraction by modified Lentz’s method(5.2) with b0=0. 
	c=1.0/FPMIN; 
	d=1.0/b; 
	h=d; 
	for(i=1;i<=ITMAX;i++) // Iterate to convergence. 
	{
		an=-i*(i-a); 
		b+=2.0; 
		d=an*d+b; 
		if(fabs(d)<FPMIN)
			d=FPMIN; 
		c=b+an/c; 
		if(fabs(c)<FPMIN)
			c=FPMIN; 
		d=1.0/d; 
		del=d*c; 
		h*=del; 
		if(fabs(del-1.0)< EPS)
			break; 
	} 
	if(i> ITMAX)
		printf("a too large,ITMAX too small in gcf\n"); 
	*gammcf=exp(-x+a*log(x)-(*gln))*h; // Put factors in front. 
}

float gammp(float a,float x) 
// Returns the incomplete gamma function P(a,x). 
{ 
	float	gamser,gammcf,gln; 
	
	if(x< 0.0||a<=0.0)
		printf("Invalid arguments in routine gammp\n"); 
	if(x< (a+1.0)) // Use the series representation.
	{
		gser(&gamser,a,x,&gln); 
		return gamser; 
	}
	else // Use the continued fraction representation 
	{
		gcf(&gammcf,a,x,&gln); 
		return 1.0-gammcf; // and take its complement. 
	} 
} 
#pragma mark -
void compress_dct_1d(float *in, float *out, int N)
{
	int n,k;
    
	for(k=0;k<N;k++)
	{
		float z=0;
		for(n=0;n<N;n++)
			z+=in[n]*cos(pi*(2*n+1)*k/(float)(2*N));
		out[k]=z*((k==0)?1/sqrt(N):sqrt(2/(float)N));
	}
}
void compress_idct_1d(float *in, float *out, int N)
{
	int n,k;
    
	for(n=0;n<N;n++)
	{
		float z=0;
		for(k=0;k<N;k++)
			z+=((k==0)?1/sqrt(N):sqrt(2/(float)N))*in[k]*cos(pi*(2*n+1)*k/(float)(2*N));
		out[n]=z;
	}
}
void compress_dct(float *vol,float *coeff,int *d)
{
	int i,j,k;
	float *in,*out;
    int max;
    
    max=(d[0]>d[1])?d[0]:d[1];
    max=(d[2]>max)?d[2]:max;
    in=(float*)calloc(max,sizeof(float));
    out=(float*)calloc(max,sizeof(float));
	
    for(i=0;i<d[0];i++)
        for(j=0;j<d[1];j++)
        {
            for(k=0;k<d[2];k++)
                in[k]=vol[k*d[1]*d[0]+j*d[0]+i];
            compress_dct_1d(in,out,d[2]);
            for(k=0;k<d[2];k++)
                coeff[k*d[1]*d[0]+j*d[0]+i]=out[k];
        }
    
	for(j=0;j<d[1];j++)
        for(k=0;k<d[2];k++)
        {
            for(i=0;i<d[0];i++)
                in[i]=coeff[k*d[1]*d[0]+j*d[0]+i];
            compress_dct_1d(in,out,d[0]);
            for(i=0;i<d[0];i++)
                coeff[k*d[1]*d[0]+j*d[0]+i]=out[i];
        }
    
	for(k=0;k<d[2];k++)
        for(i=0;i<d[0];i++)
        {
            for(j=0;j<d[1];j++)
                in[j]=coeff[k*d[1]*d[0]+j*d[0]+i];
            compress_dct_1d(in, out,d[1]);
            for(j=0;j<d[1];j++)
                coeff[k*d[1]*d[0]+j*d[0]+i]=out[j];
        }
    
    free(in);
    free(out);
}
void compress_idct(float *vol,float *coeff,int *d)
{
	int i,j,k;
	float *in,*out;
    int max;
    
    max=(d[0]>d[1])?d[0]:d[1];
    max=(d[2]>max)?d[2]:max;
    in=(float*)calloc(max,sizeof(float));
    out=(float*)calloc(max,sizeof(float));
	
	for(i=0;i<d[0];i++)
        for(j=0;j<d[1];j++)
        {
            for(k=0;k<d[2];k++)
                in[k]=vol[k*d[1]*d[0]+j*d[0]+i];
            compress_idct_1d(in, out,d[2]);
            for(k=0;k<d[2];k++)
                coeff[k*d[1]*d[0]+j*d[0]+i]=out[k];
        }
    
	for(j=0;j<d[1];j++)
        for(k=0;k<d[2];k++)
        {
            for(i=0;i<d[0];i++)
                in[i]=coeff[k*d[1]*d[0]+j*d[0]+i];
            compress_idct_1d(in, out,d[0]);
            for(i=0;i<d[0];i++)
                coeff[k*d[1]*d[0]+j*d[0]+i]=out[i];
        }
    
	for(k=0;k<d[2];k++)
        for(i=0;i<d[0];i++)
        {
            for(j=0;j<d[1];j++)
                in[j]=coeff[k*d[1]*d[0]+j*d[0]+i];
            compress_idct_1d(in, out,d[1]);
            for(j=0;j<d[1];j++)
                coeff[k*d[1]*d[0]+j*d[0]+i]=out[j];
        }
    
    free(in);
    free(out);
}
void discrete_cosine_transform(float *vol, int *d)
{
	// based on article at http://reference.wolfram.com/legacy/applications/digitalimage/FunctionIndex/InverseDiscreteCosineTransform.html
	float	*tmp,*coeff;
	int		i,j,k;//,n=0;
	
    /*
     float   x[]={1,2,1,0,1,2,3,1},y[8];
     coeff=(float*)calloc(8,sizeof(float));
     compress_dct_1d(x,coeff,8);
     compress_idct_1d(coeff,y,8);
     */
    
    // change dimensions to multiple of 8
	tmp=(float*)calloc(d[0]*d[1]*d[2],sizeof(float));
	coeff=(float*)calloc(d[0]*d[1]*d[2],sizeof(float));
	for(i=0;i<d[0];i++)
    for(j=0;j<d[1];j++)
    for(k=0;k<d[2];k++)
        tmp[k*d[1]*d[0]+j*d[0]+i]=vol[k*d[1]*d[0]+j*d[0]+i];
	
	// dct
	compress_dct(tmp,coeff,d);
	
	// compress at rate
    /*
    for(i=0;i<d[0];i++)
    for(j=0;j<d[1];j++)
    for(k=0;k<d[2];k++)
    {
        if(i*i+j*j+k*k>20*20)
            coeff[k*d[1]*d[0]+j*d[0]+i]=0;
        else
            n++;
    }
    printf("%i non-zero coefficients\n",n);
    */
    
	// idct
	//compress_idct(coeff,tmp,d);
	
	// change volume to compressed version
	for(i=0;i<d[0];i++)
    for(j=0;j<d[1];j++)
    for(k=0;k<d[2];k++)
        vol[k*d[1]*d[0]+j*d[0]+i]=coeff[k*d[1]*d[0]+j*d[0]+i];
	
	free(tmp);
    free(coeff);
}

#pragma mark -
void findpeaks(float threshold, int R, int *co, int *sz, short *sum, short *cvol, int N, Peak *peaks, int *npeaks)
{
	int		i,j,k,l,m,n,nn,i1,i2;
	Peak	coord;
	float	val,max;
	int		x,y,z;
	int		pa,is,lr;
	
	x=co[0];
	y=co[1];
	z=co[2];
	
	lr=sz[0];
	pa=sz[1];
	is=sz[2];
	
	i1=z*pa*lr+y*lr+x;
	
	peaks[0].a=x;
	peaks[0].b=y;
	peaks[0].c=z;
	peaks[0].maxlr=-1;
	peaks[0].maxk=sum[i1];
	(*npeaks)=1;

	for(i=0;i<lr;i++)
	for(j=0;j<pa;j++)
	for(k=0;k<is;k++)
	{
		i2=k*pa*lr+j*lr+i;
		val=likelihood_ratio(sum[i1], sum[i2], cvol[i2], N);

		if(val>threshold)
		{
			nn=0;
			
			max=0;
			for(l=-R;l<=R;l++)
			for(m=-R;m<=R;m++)
			for(n=-R;n<=R;n++)
			if(l*l+m*m+n*n<=R*R)
				if(i+l>=0 && i+l<lr &&
				   j+m>=0 && j+m<pa &&
				   k+n>=0 && k+n<is)
				{
					i2=(k+n)*pa*lr+(j+m)*lr+(i+l);
					val=likelihood_ratio(sum[i1], sum[i2], cvol[i2], N);
					
					if(	val>threshold &&	// count immediate superthreshold neighbours
						fabs(l)<2 && fabs(m)<2 && fabs(n)<2)
						nn++;
					
					if(val>=max)
					{
						max=val;
						coord=(Peak){i+l,j+m,k+n,0,0};
					}
				}
			
			if(pow(x-i,2)+pow(y-j,2)+pow(z-k,2)<=R*R)	// i1==i2 is singular
				coord=(Peak){x,y,z,0,0};
			
			i2=k*pa*lr+j*lr+i;
			val=likelihood_ratio(sum[i1], sum[i2], cvol[i2], N);
			if( nn>1 && // filter single voxel clusters
				val==max &&
				coord.a==i && coord.b==j && coord.c==k)
			{
				peaks[*npeaks].a=i;
				peaks[*npeaks].b=j;
				peaks[*npeaks].c=k;
				peaks[*npeaks].maxlr=max;
				peaks[*npeaks].maxk=cvol[i2];
				(*npeaks)++;
			}
		}
	}
}
