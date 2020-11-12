: $Id: vecstim.mod,v 1.3 2010/12/13 21:29:27 samn Exp $ 
:  Vector stream of events

NEURON {
  THREADSAFE
       ARTIFICIAL_CELL VecStim 
}

ASSIGNED {
	index
	etime (ms)
	space
}

INITIAL {
	index = 0
	element()
	if (index > 0) {
		if (etime - t>=0) {
			net_send(etime - t, 1)
		} else {
			printf("Event in the stimulus vector at time %g is omitted since has value less than t=%g!\n", etime, t)
			net_send(0, 2)
		}
	}
}

NET_RECEIVE (w) {
	if (flag == 1) { net_event(t) }
	if (flag == 1 || flag == 2) {
		element()
		if (index > 0) {	
			if (etime - t>=0) {
				net_send(etime - t, 1)
			} else {
				printf("Event in the stimulus vector at time %g is omitted since has value less than t=%g!\n", etime, t)
				net_send(0, 2)
			}
		}
	}
}

VERBATIM
extern double* vector_vec();
extern int vector_capacity();
extern void* vector_arg();
ENDVERBATIM

PROCEDURE element() {
VERBATIM	
  { void* vv; int i, size; double* px;
	i = (int)index;
	if (i >= 0) {
		vv = *((void**)(&space));
		if (vv) {
			size = vector_capacity(vv);
			px = vector_vec(vv);
			if (i < size) {
				etime = px[i];
				index += 1.;
			}else{
				index = -1.;
			}
		}else{
			index = -1.;
		}
	}
  }
ENDVERBATIM
}

PROCEDURE play() {
VERBATIM
	void** vv;
	vv = (void**)(&space);
	*vv = (void*)0;
	if (ifarg(1)) {
		*vv = vector_arg(1);
	}
ENDVERBATIM
}
        

VERBATIM
static void bbcore_write(double* xarray, int* iarray, int* xoffset, int* ioffset, _threadargsproto_) {
  int i, dsize, *ia;
  double *xa, *dv;
  dsize = 0;
  if (_p_ptr) {
    dsize = vector_capacity(_p_ptr);
  }
  if (xarray) {
    void* vec = _p_ptr;
    ia = iarray + *ioffset;
    xa = xarray + *xoffset;
    ia[0] = dsize;
    if (dsize) {
      dv = vector_vec(vec);
      for (i = 0; i < dsize; ++i) {
         xa[i] = dv[i];
      }
    }
  }
  *ioffset += 1;
  *xoffset += dsize;
}

static void bbcore_read(double* xarray, int* iarray, int* xoffset, int* ioffset, _threadargsproto_) {
  int dsize, i, *ia;
  double *xa, *dv;
  dsize = 0;
  if (xarray) {
      assert(!_p_ptr);
      xa = xarray + *xoffset;
      ia = iarray + *ioffset;
      dsize = ia[0];
      _p_ptr = vector_new1(dsize);
      dv = vector_vec(_p_ptr);
      for (i = 0; i < dsize; ++i) {
          dv[i] = xa[i];
      }
  }
  *xoffset += dsize;
  *ioffset += 1;
}

ENDVERBATIM
