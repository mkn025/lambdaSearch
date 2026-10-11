#include "dirutils.h"

unsigned int
    __posixdir_d_type(struct dirent* d)
    {
      // same as ((*d).d_type)
      return(d -> d_type);
    }
