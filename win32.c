#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <win32/win32guts.h>
#include <cairo.h>
#include <cairo-win32.h>
#include "prima_cairo.h"
#include <Drawable.h>

#ifdef __cplusplus
extern "C" {
#endif

#define var (( PComponent) widget)
#define img (( PDrawable) widget)
#define sys (( PDrawableData) var-> sysData)

void*
apc_cairo_surface_create( Handle widget, int request)
{
	if ( request == REQ_TARGET_PRINTER ) 
        	return cairo_win32_printing_surface_create(sys-> ps);
        return cairo_win32_surface_create(sys-> ps);
}


#ifdef __cplusplus
}
#endif

