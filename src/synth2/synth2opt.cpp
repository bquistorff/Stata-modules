#include <cstdlib>
#include <cassert>
#include <stdio.h>
#include <cmath>
#include <cstring>
//#define SD_FASTMODE
#include "stplugin.h"
#include "pr_loqo.h"

//see http://www.stata.com/manuals13/perror.pdf
#define ST_ERR_INVALID_SYNTAX 197
#define ST_ERR_CONFORMABILITY 503

//NOTE: H must be symmetric.
//NOTE: Pass in A (m.n) (not a, which is n.m according to pr_loqo.h).

//Row/col major. 
//C/C++ usually uses row-major. Malabl col-major. pr_loqo "rows first order"!?
//row-major[r * nCols + c]. col-major[c * nRows + r]. 3 spots to replace
//For using PR_LOQO it only matters for A (H is symmetric).
//Currently uses row-major. 
class Matrix
{
    public:
        Matrix(ST_int rows, ST_int cols, double existing_data[])
        : nRows(rows), nCols(cols), data(existing_data), should_free(false) { }
		
        Matrix(ST_int rows, ST_int cols)
        : nRows(rows), nCols(cols), data(new double[nRows*nCols]), should_free(true) { }
		
		Matrix(char *st_mat_name)
		: nRows(SF_row(st_mat_name)), nCols(SF_col(st_mat_name)),data(new double[nRows*nCols]), should_free(true){
			if(!nRows | !nCols) throw ST_ERR_INVALID_SYNTAX;
			st_load(st_mat_name);
		}
		
        ~Matrix() { if(should_free) delete [] data; }
		
		void st_store(char*st_mat_name){
			for(int r=0; r<nRows; r++){
				for(int c=0; c<nCols; c++){
					double val = data[r * nCols + c];
					if(!std::isfinite(val)) val = (double)SV_missval;
					//Stata does 1-indexing
					ST_retcode ret = SF_mat_store(st_mat_name, r+1, c+1, val) ;
					if(ret!=(ST_retcode)0) throw ret;
				}
			}
		}

		//0-indexing
        double &operator()(ST_int r, ST_int c) { 
			if (r < 0 || r >= nRows || c < 0 || c >= nCols){
				SF_error_const("matrix subscript out of bounds\n");
				throw ST_ERR_CONFORMABILITY;
			}
			return data[r * nCols + c]; 
		}
	
		const ST_int nRows, nCols;
        double * const data;
	private:
		void st_load(char*st_mat_name){
			for(ST_int r=0; r<nRows; r++){
				for(ST_int c=0; c<nCols; c++){
					//Stata uses 1-indexing
					ST_retcode ret = SF_mat_el(st_mat_name, r+1, c+1, &data[r * nCols + c]);
					//if(ret!=(ST_retcode)0) throw ret; //not needed as only called from constructor where already checked size.
				}
			}
			
		}
		
		const bool should_free;
};


// Regular C-style stata_call()
STDLL stata_call(int argc, char *argv[]) { 
	try{
	Matrix c = Matrix(argv[0]);
	Matrix H = Matrix(argv[1]);
	Matrix a = Matrix(argv[2]);
	Matrix b = Matrix(argv[3]);
	Matrix l = Matrix(argv[4]);
	Matrix u = Matrix(argv[5]);
	double bound      = atof(argv[6]);
	double margin     = atof(argv[7]);
	int counter_max   = atoi(argv[8]);
	double sigfig_max = atof(argv[9]);
	char *wsol_name  = argv[10];
	int verb	=(argc>11?atoi(argv[11]):FLOOD);
	int restart	=(argc>12?atoi(argv[12]):0);
	char * opt_ret_val_mac_name =(argc>13?argv[13]:NULL);
	
	int n = c.nRows;
	int m = b.nRows;
	Matrix primal = Matrix(3*n,1);
	Matrix answer = Matrix(n,1,primal.data); //subset
	if(restart){
		Matrix wsol = Matrix(wsol_name);
		memcpy(primal.data, wsol.data,n*sizeof(double));
	}
	Matrix dual = Matrix(m + 2*n,1);
	
	const int buff_size = 20;
	char buffer[buff_size];
	ST_retcode st_ret;

#if SYSTEM==STWIN32	
	_set_output_format(_TWO_DIGIT_EXPONENT); //2-digit is default on *nix
#endif

    int opt_ret_val = pr_loqo(n, m, c.data, H.data, a.data, b.data, l.data, u.data, primal.data, dual.data, 
	    verb, sigfig_max, counter_max, margin, bound, restart);
	
	switch(opt_ret_val) {
		//case STILL_RUNNING: SF_display_const("STILL_RUNNING\n"); break;
		case OPTIMAL_SOLUTION: SF_display_const("OPTIMAL_SOLUTION\n"); break;
		case ITERATION_LIMIT: SF_display_const("ITERATION_LIMIT\n"); break;
		case PRIMAL_INFEASIBLE: SF_display_const("PRIMAL_INFEASIBLE\n"); break;
		case DUAL_INFEASIBLE: SF_display_const("DUAL_INFEASIBLE\n"); break;
		case PRIMAL_AND_DUAL_INFEASIBLE: SF_display_const("PRIMAL_AND_DUAL_INFEASIBLE\n"); break;
		case PRIMAL_UNBOUNDED: SF_display_const("PRIMAL_UNBOUNDED\n"); break;
		case DUAL_UNBOUNDED: SF_display_const("DUAL_UNBOUNDED\n"); break;
		case CHOLDC_FAILED: SF_display_const("CHOLDC_FAILED\n"); break;
	}
	snprintf(buffer,buff_size, "%i", opt_ret_val);
	if(opt_ret_val_mac_name) st_ret = SF_macro_save_const(opt_ret_val_mac_name, buffer); 
	
	answer.st_store(wsol_name);
	}
	catch(ST_retcode ret){
		return(ret);
	}
    return((ST_retcode) 0) ;
}
