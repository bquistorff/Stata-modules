#include <cstdlib>
#include <cassert>
#include <stdio.h>
//#define SD_FASTMODE
#include "stplugin.h"
#include "pr_loqo.h"


//check: restart; make sure all row/col major the same
//try: fastmode

struct mat{
	ST_int nRows, nCols;
	double * data;
};

struct mat blank_mat(ST_int rows, ST_int cols){
	struct mat ret;
	ret.nRows=rows;
	ret.nCols=cols;
	ret.data=new double[ret.nRows*ret.nCols];
	return(ret);
}

struct mat assign_mat(ST_int rows, ST_int cols, double existing_data[]){
	struct mat ret;
	ret.nRows=rows;
	ret.nCols=cols;
	ret.data=existing_data;
	return(ret);
}

void st_store(struct mat m, char*st_mat_name){
	for(int r=0; r<m.nRows; r++){
		for(int c=0; c<m.nCols; c++){
			//Stata does 1-indexing
			SF_mat_store(st_mat_name, r+1, c+1, m.data[r * m.nCols + c]) ;
		}
	}
}

struct mat load_mat(char *st_mat_name){
	struct mat ret;
	ret.nRows=SF_row(st_mat_name);
	ret.nCols=SF_col(st_mat_name);
	ret.data=new double[ret.nRows*ret.nCols];
	for(int r=0; r<ret.nRows; r++){
		for(int c=0; c<ret.nCols; c++){
			//Stata does 1-indexing
			SF_mat_el(st_mat_name, r+1, c+1, &ret.data[r * ret.nCols + c]);
		}
	}
	return(ret);
}


// Regular C-style stata_call()
//plugin call synthopt , `c' `H'  `A' $bslack `l' `u' $bd $marg $maxit $sig `wsol' //verb restart
STDLL stata_call(int argc, char *argv[]) { 
	SF_display_const("Here\n");
	struct mat c = load_mat(argv[0]);
	struct mat H = load_mat(argv[1]);
	struct mat a = load_mat(argv[2]);
	struct mat b = load_mat(argv[3]);
	struct mat l = load_mat(argv[4]);
	struct mat u = load_mat(argv[5]);
	double bound      = atof(argv[6]);
	double margin     = atof(argv[7]);
	int counter_max   = atoi(argv[8]);
	double sigfig_max = atof(argv[9]);
	char *wsol  = argv[10];
	int verb	=(argc>11,atoi(argv[11]),STATUS);
	int restart	=(argc>12,atoi(argv[12]),0);
	
	int n = c.nRows;
	int m = b.nRows;
	struct mat primal = blank_mat(3*n,1);
	struct mat answer = assign_mat(n,1,primal.data); //subset
	struct mat dual = blank_mat(m + 2*n,1);
	SF_display_const("Here\n");
    int ret_status = pr_loqo(n, m, c.data, H.data, a.data, b.data, l.data, u.data, primal.data, dual.data, 
	    verb, sigfig_max, counter_max, margin, bound, restart);
	SF_display_const("Here\n");
	switch(ret_status) {
		//case STILL_RUNNING: SF_display_const("STILL_RUNNING\n"); break;
		case OPTIMAL_SOLUTION: SF_display_const("OPTIMAL_SOLUTION\n"); break;
		case SUBOPTIMAL_SOLUTION: SF_display_const("SUBOPTIMAL_SOLUTION\n"); break;
		case ITERATION_LIMIT: SF_display_const("ITERATION_LIMIT\n"); break;
		case PRIMAL_INFEASIBLE: SF_display_const("PRIMAL_INFEASIBLE\n"); break;
		case DUAL_INFEASIBLE: SF_display_const("DUAL_INFEASIBLE\n"); break;
		case PRIMAL_AND_DUAL_INFEASIBLE: SF_display_const("PRIMAL_AND_DUAL_INFEASIBLE\n"); break;
		case INCONSISTENT: SF_display_const("INCONSISTENT\n"); break;
		case PRIMAL_UNBOUNDED: SF_display_const("PRIMAL_UNBOUNDED\n"); break;
		case DUAL_UNBOUNDED: SF_display_const("DUAL_UNBOUNDED\n"); break;
		case TIME_LIMIT: SF_display_const("TIME_LIMIT\n"); break;
	}
	const int buff_size = 3;
	char buffer[buff_size];
	snprintf(buffer,buff_size, "%i", ret_status);
	SF_macro_save_const("_PR_LOQO_return", buffer); 
	
	st_store(answer, wsol);
	
	/*free(c.data);
	free(H.data);
	free(a.data);
	free(b.data);
	free(l.data);
	free(u.data);
	free(primal.data);
	free(dual.data);*/
	
    return((ST_retcode) 0) ;
}
